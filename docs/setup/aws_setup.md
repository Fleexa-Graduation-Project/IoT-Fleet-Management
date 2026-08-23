# AWS Account Setup

This walks through bringing Fleexa up in a fresh AWS account, from credentials to the values you'll need to hand to the backend and mobile app afterward.

## 1. Create IAM Credentials

1. Sign in to the AWS Console (or create a new account if you're standing up an isolated sandbox).
2. Create an IAM user (or role, if you're using SSO) with **administrator-level permissions** for the initial setup. Terraform provisions resources across IoT Core, Lambda, API Gateway, DynamoDB, Cognito, and S3, and least-privilege scoping the bootstrap user is out of scope for a first-time setup.
3. Generate an access key for that user and configure the AWS CLI:
   ```bash
   aws configure
   # AWS Access Key ID: ...
   # AWS Secret Access Key: ...
   # Default region name: us-east-1
   # Default output format: json
   ```
4. Verify the credentials work:
   ```bash
   aws sts get-caller-identity
   ```

## 2. Choose a Region

The project defaults to **`us-east-1`** everywhere: the root README's Terraform apply example, the CI/CD pipeline's `AWS_REGION` env var, and the Terraform `aws_region` variable's default all point at it. You can deploy to a different region by passing `-var="aws_region=..."`, but keep in mind:
- The Terraform S3 state backend (`fleexa-s3-tfstate` bucket, `fleexa-dynamoDB-tflock` lock table — see [`backend.tf`](../../infra-iot-fleet/terraform/backend.tf)) is itself pinned to `us-east-1` and is not parameterized by the region variable.
- AWS IoT Core, Cognito, and DynamoDB are all regional services — every device certificate, MQTT broker endpoint, and Cognito pool you create will be tied to whichever region you pick.

Unless you have a specific reason not to, stick with `us-east-1` to match the rest of the team's setup and the CI pipeline.

## 3. Provision the Bootstrap Backend (one-time, if not already created)

Terraform expects the S3 state bucket and DynamoDB lock table referenced in `backend.tf` to already exist. If you're standing up a brand-new AWS account rather than reusing the shared one, create them once, out of band, before running `terraform init`:
```bash
aws s3api create-bucket --bucket fleexa-s3-tfstate --region us-east-1
aws dynamodb create-table \
  --table-name fleexa-dynamoDB-tflock \
  --attribute-definitions AttributeName=LockID,AttributeType=S \
  --key-schema AttributeName=LockID,KeyType=HASH \
  --billing-mode PAY_PER_REQUEST
```
If you're joining an existing team/account, skip this — the bucket and table already exist and your IAM user just needs read/write access to them.

## 4. Run Terraform

Full detail is in [`guides/deployment.md`](../guides/deployment.md); the short version:
```bash
cd infra-iot-fleet/terraform
terraform init
terraform validate
terraform apply -var="aws_region=us-east-1"
```
This provisions, in one pass: the IoT Core Thing type and device policy, the `Fleexa_*` DynamoDB tables, a Cognito user pool + app client, the API Gateway HTTP API, an S3 data lake bucket, and the backend's Lambda functions.

## 5. Collect the Values You'll Need

`terraform output` only surfaces `api_endpoint` / `api_url` at the root level. Gather the rest like this:

| Value | How to get it | Used for |
| :--- | :--- | :--- |
| **API Gateway URL** | `terraform output api_url` | Mobile app's API base URL |
| **AWS IoT Core endpoint** | `aws iot describe-endpoint --endpoint-type iot:Data-ATS --region us-east-1 --query endpointAddress --output text` | Backend `IOT_ENDPOINT`, simulator `MQTT_BROKER` |
| **Cognito User Pool ID** | `terraform state show 'module.cognito.aws_cognito_user_pool.pool'` (or AWS Console → Cognito) | Backend `COGNITO_USER_POOL_ID`, mobile app auth config |
| **Cognito App Client ID** | `terraform state show 'module.cognito.aws_cognito_user_pool_client.client'` | Backend `COGNITO_CLIENT_ID`, mobile app auth config |
| **DynamoDB table names** | `terraform state show 'module.dynamodb.aws_dynamodb_table.<telemetry\|device_state\|alerts\|commands>'`, or `aws dynamodb list-tables` | Backend `*_TABLE` env vars |
| **S3 data lake bucket name** | `terraform state show 'module.s3.aws_s3_bucket.data_lake'` | Backend `BUCKET_NAME` |

Feed these into the backend's environment variables exactly as documented in [`backend/README.md#environment-variables`](../../backend/README.md#environment-variables):
```bash
export STATE_TABLE=Fleexa_Devices
export TELEMETRY_TABLE=Fleexa_Telemetry
export ALERTS_TABLE=Fleexa_Alerts
export COMMANDS_TABLE=Fleexa_Commands
export USERS_TABLE=Fleexa_Users
export BUCKET_NAME=fleexa-data-lake
export FIREBASE_CREDENTIALS=./firebase-adminsdk.json
export COGNITO_USER_POOL_ID=us-east-1_xxxxxxxxx
export COGNITO_CLIENT_ID=xxxxxxxxxxxxxxxxxxxxxxxxxx
export IOT_ENDPOINT=your-iot-endpoint.iot.us-east-1.amazonaws.com
export AWS_REGION=us-east-1
```

## 6. Firebase Credentials

Push notifications require a Firebase service account JSON (`FIREBASE_CREDENTIALS`, either a file path or the raw JSON content depending on how it's supplied to the Lambda). If you're setting this up fresh:
1. Create a Firebase project and generate a service account key from **Project Settings → Service Accounts → Generate new private key**.
2. If passing the JSON through Terraform as the `firebase_credentials_json` variable (rather than mounting a file), be aware that Terraform can unescape `\n` sequences inside the `private_key` field into literal newlines, which breaks JSON parsing — see [`guides/troubleshooting.md`](../guides/troubleshooting.md#firebase--push-notifications) for the exact failure mode and how the backend works around it.

## 7. GitHub Actions Secrets

If you're setting up CI/CD for a new AWS account, add `AWS_ACCESS_KEY_ID` and `AWS_SECRET_ACCESS_KEY` to the repository's `AWS` GitHub Environment (Settings → Environments) — the `terraform-plan`, `terraform-deploy`, and `verify-deploy` jobs in [`.github/workflows/ci-cd.yml`](../../.github/workflows/ci-cd.yml) read them from there.

## 8. Sanity Check

After the apply finishes, confirm the core resources exist (the same checks CI's `verify-deploy` job runs):
```bash
aws iot list-topic-rules --region us-east-1 --query 'rules[*].ruleName'
aws dynamodb list-tables --region us-east-1
aws s3api list-buckets --query 'Buckets[*].Name'
aws lambda list-functions --region us-east-1 --query 'Functions[*].FunctionName'
```
