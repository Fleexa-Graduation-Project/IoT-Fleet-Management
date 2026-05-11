## 1. S3 — Cold-Tier Data Lake

Pre-aggregated JSON charts read by the api-service Lambda for `7d` and `1m` chart periods. Hot tier (last 24h) is DynamoDB and cold tier is this S3 bucket.
Reader: `backend/internal/iot/s3ProcessedData.go`.
Writer: `backend/scripts/daily_aggregator.py`.

### Bucket settings

| Setting             | Value                                 |
| ------------------- | ------------------------------------- |
| Name                | `fleexa-data-lake`                    |
| Region              | `us-east-1`                           |
| Block public access | ON (all four toggles)                 |
| Versioning          | Off                                   |
| Default encryption  | SSE-S3 (AES-256)                      |
| Object ownership    | Bucket owner enforced (ACLs disabled) |

### Key layout

```
processed-charts/{device_id}/{YYYY-MM}.json
processed-alerts/system/{YYYY-MM}.json
```

### Env vars

api-service Lambda:

```
BUCKET_NAME=fleexa-data-lake
```

daily-aggregator Lambda:

```
STATE_TABLE=Fleexa_Devices
TELEMETRY_TABLE=Fleexa_Telemetry
ALERTS_TABLE=Fleexa_Alerts
BUCKET_NAME=fleexa-data-lake
```

---

## 2. Cognito — User Authentication

The backend stores zero passwords. All `/auth/*` routes call Cognito. Source: `backend/internal/auth/cognito.go`, `backend/internal/auth/middleware.go`.

### User Pool

| Setting              | Value                                            |
| -------------------- | ------------------------------------------------ |
| Pool name            | `fleexa-users`                                   |
| Sign-in option       | Email only                                       |
| Required attributes  | `email`, `name`                                  |
| Password policy      | Min 8, requires upper + lower + number + special |
| MFA                  | Disabled                                         |
| Self-service sign-up | Enabled                                          |
| Email verification   | Cognito default sender (free, 50/day)            |
| Account recovery     | Email only                                       |
| Deletion protection  | Off                                              |

### App Client

| Setting                       | Value                                                  |
| ----------------------------- | ------------------------------------------------------ |
| Name                          | `fleexa-mobile`                                        |
| Client secret                 | **NO** — do not generate                               |
| Auth flows                    | `ALLOW_USER_PASSWORD_AUTH`, `ALLOW_REFRESH_TOKEN_AUTH` |
| Access token expiry           | 1 hour                                                 |
| ID token expiry               | 1 hour                                                 |
| Refresh token expiry          | 30 days                                                |
| Prevent user existence errors | Enabled                                                |
| Read attributes               | `email`, `name`, `email_verified`                      |
| Write attributes              | `email`, `name`                                        |

### Env vars (api-service Lambda)

```
COGNITO_USER_POOL_ID=us-east-1_xxxxxxxxx
COGNITO_CLIENT_ID=xxxxxxxxxxxxxxxxxxxxxxxxxx
```

JWKS endpoint is public — no IAM needed.
Sign-up makes three Cognito calls: `SignUp` → `AdminConfirmSignUp` → `AdminUpdateUserAttributes` (sets `email_verified=true`, required for `ForgotPassword` to deliver OTP codes).

---

## 3. door-watch Lambda

Scans door devices every minute. Fires escalating Firebase push notifications when a door stays open: **WARNING at 7 min**, **CRITICAL at 15 / 30 / 60 / 120 min**.
Source: `backend/cmd/door-watch/main.go` .
Logic in: `backend/internal/rules/door_rules.go`.

### Function settings

| Setting       | Value                                                      |
| ------------- | ---------------------------------------------------------- |
| Function name | `fleexa-door-watch`                                        |
| Runtime       | `provided.al2023`                                          |
| Architecture  | `arm64`                                                    |
| Handler       | `bootstrap`                                                |
| Timeout       | 30 seconds                                                 |
| Memory        | 256 MB                                                     |
| VPC           | None (must reach Firebase + DynamoDB over public internet) |

### Env vars

```
STATE_TABLE=Fleexa_Devices
ALERTS_TABLE=Fleexa_Alerts
FIREBASE_CREDENTIALS=./firebase-adminsdk.json
AWS_REGION=us-east-1
```

**Note:** the existing `iot-ingestion` Lambda also calls `notifications.NewService` (`backend/cmd/iot-ingestion/main.go:59-67`) — bundle the same `firebase-adminsdk.json` and set `FIREBASE_CREDENTIALS` on it too, or gas-alert pushes break.

---

## 4. EventBridge Schedules

### 4.1 door-watch — every 1 minute

```hcl
resource "aws_cloudwatch_event_rule" "door_watch_cron" {
  name                = "fleexa-door-watch"
  schedule_expression = "rate(1 minute)"
}

resource "aws_cloudwatch_event_target" "door_watch_target" {
  rule = aws_cloudwatch_event_rule.door_watch_cron.name
  arn  = aws_lambda_function.door_watch.arn
}

resource "aws_lambda_permission" "allow_eventbridge_door_watch" {
  statement_id  = "AllowExecutionFromEventBridge"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.door_watch.function_name
  principal     = "events.amazonaws.com"
  source_arn    = aws_cloudwatch_event_rule.door_watch_cron.arn
}
```

### 4.2 daily-aggregator — once daily at 00:30 UTC

Triggers the Python Lambda that fills the S3 cold tier. Without it, `period=7d` and `period=1m` chart endpoints return empty data.
Source: `backend/scripts/daily_aggregator.py`.

#### Function settings

| Setting       | Value                             |
| ------------- | --------------------------------- |
| Function name | `fleexa-daily-aggregator`         |
| Runtime       | `python3.12`                      |
| Handler       | `daily_aggregator.lambda_handler` |


`boto3` is provided by the Python runtime — no extra dependencies needed.

```hcl
resource "aws_cloudwatch_event_rule" "daily_aggregator_cron" {
  name                = "fleexa-daily-aggregator"
  schedule_expression = "cron(30 0 * * ? *)"
}

resource "aws_cloudwatch_event_target" "daily_aggregator_target" {
  rule = aws_cloudwatch_event_rule.daily_aggregator_cron.name
  arn  = aws_lambda_function.daily_aggregator.arn
}

resource "aws_lambda_permission" "allow_eventbridge_daily_aggregator" {
  statement_id  = "AllowExecutionFromEventBridge"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.daily_aggregator.function_name
  principal     = "events.amazonaws.com"
  source_arn    = aws_cloudwatch_event_rule.daily_aggregator_cron.arn
}
```

---

## 5. IAM — Roles & Policies

Lambda trust policy (same for all three roles):

```json
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Principal": { "Service": "lambda.amazonaws.com" },
      "Action": "sts:AssumeRole"
    }
  ]
}
```

### 5.1 api-service Lambda

Role name (existing): `iot-fleet-api-lambda`
Defined in: [infra-iot-fleet/terraform/modules/api_gateway/main.tf:19-33](../infra-iot-fleet/terraform/modules/api_gateway/main.tf#L19-L33)

**Add** the following statements alongside the existing DynamoDB + IoT statements at [main.tf:97-125](../infra-iot-fleet/terraform/modules/api_gateway/main.tf#L97-L125):

```json
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Sid": "FleexaS3ChartReader",
      "Effect": "Allow",
      "Action": ["s3:GetObject"],
      "Resource": [
        "arn:aws:s3:::fleexa-data-lake/processed-charts/*",
        "arn:aws:s3:::fleexa-data-lake/processed-alerts/*"
      ]
    },
    {
      "Sid": "FleexaCognitoOps",
      "Effect": "Allow",
      "Action": [
        "cognito-idp:SignUp",
        "cognito-idp:AdminConfirmSignUp",
        "cognito-idp:AdminUpdateUserAttributes",
        "cognito-idp:InitiateAuth",
        "cognito-idp:ChangePassword",
        "cognito-idp:ForgotPassword",
        "cognito-idp:ConfirmForgotPassword",
        "cognito-idp:GetUser",
        "cognito-idp:DeleteUser"
      ],
      "Resource": "arn:aws:cognito-idp:us-east-1:<ACCOUNT_ID>:userpool/<USER_POOL_ID>"
    },
    {
      "Sid": "FleexaUsersTable",
      "Effect": "Allow",
      "Action": ["dynamodb:GetItem", "dynamodb:PutItem", "dynamodb:DeleteItem"],
      "Resource": "arn:aws:dynamodb:us-east-1:<ACCOUNT_ID>:table/Fleexa_Users"
    }
  ]
}
```

### 5.2 door-watch Lambda

Role name (new): `fleexa-door-watch-role`

```json
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Sid": "Logs",
      "Effect": "Allow",
      "Action": [
        "logs:CreateLogGroup",
        "logs:CreateLogStream",
        "logs:PutLogEvents"
      ],
      "Resource": "arn:aws:logs:us-east-1:<ACCOUNT_ID>:*"
    },
    {
      "Sid": "ReadDeviceState",
      "Effect": "Allow",
      "Action": ["dynamodb:Scan", "dynamodb:GetItem"],
      "Resource": "arn:aws:dynamodb:us-east-1:<ACCOUNT_ID>:table/Fleexa_Devices"
    },
    {
      "Sid": "WriteAlerts",
      "Effect": "Allow",
      "Action": ["dynamodb:PutItem"],
      "Resource": "arn:aws:dynamodb:us-east-1:<ACCOUNT_ID>:table/Fleexa_Alerts"
    }
  ]
}
```

### 5.3 daily-aggregator Lambda

Role name (new): `fleexa-daily-aggregator-role`

```json
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Sid": "Logs",
      "Effect": "Allow",
      "Action": [
        "logs:CreateLogGroup",
        "logs:CreateLogStream",
        "logs:PutLogEvents"
      ],
      "Resource": "arn:aws:logs:us-east-1:<ACCOUNT_ID>:*"
    },
    {
      "Sid": "ReadAggregatorSources",
      "Effect": "Allow",
      "Action": ["dynamodb:Scan", "dynamodb:Query"],
      "Resource": [
        "arn:aws:dynamodb:us-east-1:<ACCOUNT_ID>:table/Fleexa_Devices",
        "arn:aws:dynamodb:us-east-1:<ACCOUNT_ID>:table/Fleexa_Telemetry",
        "arn:aws:dynamodb:us-east-1:<ACCOUNT_ID>:table/Fleexa_Alerts"
      ]
    },
    {
      "Sid": "WriteChartObjects",
      "Effect": "Allow",
      "Action": ["s3:GetObject", "s3:PutObject"],
      "Resource": [
        "arn:aws:s3:::fleexa-data-lake/processed-charts/*",
        "arn:aws:s3:::fleexa-data-lake/processed-alerts/*"
      ]
    }
  ]
}
```

---

## 6. DynamoDB — Fleexa_Users Table

Stores user notification preferences (FCM device token, per-severity toggles).
Source: `backend/internal/users/user_store.go`.
Model in `backend/models/user.go`.

### Table settings

| Setting       | Value                         |
| ------------- | ----------------------------- |
| Name          | `Fleexa_Users`                |
| Billing mode  | `PAY_PER_REQUEST` (on-demand) |
| Partition key | `user_id` (String)            |
| Sort key      | — (none)                      |
| TTL           | Disabled (profiles persist)   |
| Region        | `us-east-1`                   |

Partition key value is the Cognito `sub`.

### Env var (api-service Lambda)

```
USERS_TABLE=Fleexa_Users
```
