# Deployment Architecture

Fleexa is provisioned entirely through Terraform and deployed through a single GitHub Actions workflow. There are no manually-clicked AWS Console resources in the intended workflow, and no container orchestration platform — every compute unit is an AWS Lambda function built from this repository and uploaded as a zip by Terraform itself.

---

## Terraform layout

```text
infra-iot-fleet/terraform/
├── main.tf              # wires the modules together (iot_core, dynamodb, s3, cognito,
│                         #  api_gateway, cron_aggregator, door-watch/ac-timer-watch lambdas)
├── iotrules.tf           # IoT Topic Rules that route MQTT -> iot-ingestion Lambda
├── lambda_build.tf       # `go build` + zip steps for iot-ingestion, door-watch, ac-timer-watch,
│                         #  and the daily_aggregator Python zip
├── backend.tf            # Terraform state backend configuration
├── provider.tf           # AWS provider configuration
├── variables.tf          # root input variables (project_name, environment, aws_region, ...)
├── outputs.tf            # api_endpoint / api_url outputs for the Flutter app
├── terraform.tfvars      # default variable values
├── environments/         # per-environment variable files: dev.tfvars, staging.tfvars, prod.tfvars
└── modules/
    ├── iot_core/          # IoT Thing Type, sample Thing, and the device IoT Policy (mTLS scoping)
    ├── dynamodb/           # Fleexa_Telemetry, Fleexa_Devices (device-state), Fleexa_Alerts,
    │                       #  Fleexa_Commands, Fleexa_Users tables + GSIs
    ├── s3/                 # the data lake bucket (private, SSE-AES256, versioning suspended)
    ├── cognito/             # User Pool + App Client used for mobile/API auth
    ├── api_gateway/         # builds api-service, HTTP API (API Gateway v2), Lambda proxy integration
    ├── lambda/              # generic reusable Lambda + IAM role module (used by door-watch,
    │                         #  ac-timer-watch, and iot-ingestion)
    ├── cron_aggregator/     # daily_aggregator Python Lambda + EventBridge daily rule (DynamoDB -> S3)
    └── cron_export/         # db-export Go Lambda + EventBridge daily rule (DynamoDB table dump -> S3)
```

Each Lambda-owning module (`lambda`, `api_gateway`, `cron_aggregator`, `cron_export`) creates its own dedicated IAM execution role, scoped to only the DynamoDB tables, S3 bucket, and IoT/Cognito actions that function actually needs — see [`security_model.md`](./security_model.md) for the least-privilege breakdown.

### How the Go/Python binaries actually get built

Terraform does not consume pre-built artifacts from CI. `lambda_build.tf` and `modules/api_gateway/main.tf` shell out to `go build` (via `null_resource` + `local-exec`) directly from the Terraform run:

- `cmd/iot-ingestion/main.go` → `dist/ingestion/bootstrap` → zipped and deployed as the `processing_main_lambda` function (module `lambda`, targeted by both IoT Topic Rules in `iotrules.tf`).
- `cmd/door-watch/main.go` → `dist/door-watch/bootstrap` → `door-watch-service` function.
- `cmd/ac-timer-watch/main.go` → `dist/ac-timer-watch/bootstrap` → `ac-timer-watch-service` function.
- `cmd/api-service/main.go` → `dist/api/bootstrap` → `<project>-<environment>-api-service` function (module `api_gateway`).
- `backend/scripts/daily_aggregator.py` is zipped as-is (no build step, Python) and deployed by `cron_aggregator` as `<project>-<environment>-daily-aggregator`, `runtime = "python3.10"`.
- `db-export` (`cmd/db-export`) is deployed by `cron_export`; its zip is passed in as an existing artifact (`var.lambda_zip_path`) rather than built inline in that module.

All Go Lambdas run on `provided.al2023` (or the generic `lambda` module's configurable runtime) with `arm64` architecture and the `bootstrap` handler name, consistent with the `aws-lambda-go` runtime API.

### Scheduling

Two `aws_cloudwatch_event_rule` resources drive the scheduled Lambdas:
- `every-minute` (rate(1 minute)) triggers both `door-watch-service` and `ac-timer-watch-service`.
- `daily-aggregation` / `daily-db-export` (cron, once a day) trigger the aggregator and export Lambdas respectively.

### Environments

`infra-iot-fleet/terraform/environments/{dev,staging,prod}.tfvars` hold the per-environment values for the root variables declared in `variables.tf` — `project_name`, `environment`, `aws_region`, `iot_endpoint`, Cognito IDs, the S3 bucket name, and the Firebase service-account JSON (`firebase_credentials_json`, marked `sensitive`). Table, function, and bucket names are derived from `project_name`/`environment` throughout the modules (e.g. `${project_name}-${environment}-telemetry`), so pointing Terraform at a different `.tfvars` file stands up an isolated copy of the whole stack.

---

## CI/CD pipeline

The pipeline is defined in `.github/workflows/ci-cd.yml` and runs on push to `main`/`dev-branch` and on pull requests targeting `main` (plus manual `workflow_dispatch`):

| Job | Runs on | What it does |
| :--- | :--- | :--- |
| **`test`** (Unit Tests & Schema Validation) | every push/PR | Installs `devices/requirements.txt`, runs the simulator/schema `pytest` suites (`test_schemas.py`, `test_sensors.py`, `test_actuators.py`), and sanity-imports every simulator class. |
| **`test-go`** (Go Backend Unit Tests & Build) | every push/PR | `go test ./... -v` and `go build ./...` inside `backend/`. |
| **`build`** (Build Docker Image) | after `test` | Builds the `devices/Dockerfile` simulator image and runs an import smoke test inside the built container. |
| **`terraform-plan`** (Terraform Plan — Dry Run) | after `test` + `test-go`, on pushes not targeting `main` or on `workflow_dispatch` | `terraform init` / `fmt -check` / `validate` / `plan` against `infra-iot-fleet/terraform`, prints the plan summary. Runs with AWS credentials from the `AWS` GitHub environment. |
| **`terraform-deploy`** (Deploy Infrastructure to AWS) | after `test`, `test-go`, `build`, `terraform-plan`, only on push to `main` or `Lambda-CI/CD-Implementation` (or `workflow_dispatch`) | `terraform apply -auto-approve`, saves `terraform output -json` to `infrastructure-outputs.json`, and prints the IoT Core ATS endpoint. |
| **`verify-deploy`** (Verify AWS Deployment) | after `terraform-deploy`, same branch condition | Confirms the two IoT Topic Rules, all five DynamoDB tables, the S3 data lake bucket, and the `processing_main_lambda`/`api-service` Lambda functions exist via AWS CLI queries; also lists registered IoT Things and CA certificate status. |

This matches the root [`README.md`](../../README.md)'s "CI/CD Pipeline Workflow" summary: unit tests and schema validation, a Docker build check, a Terraform plan on every PR, a Terraform apply on pushes to the deployment branches, and a post-deploy verification pass — with the caveat that `terraform apply` runs directly from the GitHub Actions runner against the `AWS` environment's credentials rather than through a separate CD tool.

### Region and provisioning notes

- All jobs target `us-east-1` (`env.AWS_REGION` in the workflow; also the default in `variables.tf`).
- `terraform-deploy` and `verify-deploy` both gate on the `AWS` GitHub Environment, which supplies `AWS_ACCESS_KEY_ID`/`AWS_SECRET_ACCESS_KEY` as repository/environment secrets.
- Because the Lambda build step runs `go build`/zips artifacts as part of `terraform apply`, a successful `terraform-deploy` run always redeploys the current commit's backend code — there's no separate artifact promotion step between environments.

---

## Runtime topology at a glance

```text
GitHub Actions (ci-cd.yml)
   test / test-go ──▶ build ──▶ terraform-plan ──▶ terraform-deploy ──▶ verify-deploy
                                                          │
                                                          ▼
                                   terraform apply (infra-iot-fleet/terraform)
                                                          │
        ┌───────────────┬───────────────┬───────────────┼───────────────┬───────────────┐
        ▼               ▼               ▼               ▼               ▼               ▼
   modules/iot_core  modules/dynamodb modules/s3    modules/cognito modules/api_gateway  modules/lambda
   (Thing, Policy)   (5 tables)     (data lake)     (User Pool)   (api-service +HTTP API) (door-watch,
                                                                                            ac-timer-watch,
                                                                                            iot-ingestion)
                                                          │
                                              modules/cron_aggregator, modules/cron_export
                                              (daily_aggregator, db-export + EventBridge)
```
