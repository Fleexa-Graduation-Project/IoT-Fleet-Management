# Deployment Guide

Fleexa has two things that get "deployed": the **AWS infrastructure** (managed by Terraform in [`infra-iot-fleet/terraform`](../../infra-iot-fleet/terraform)) and the **application code** that runs inside it (Go Lambda binaries, built and packaged as part of that same Terraform apply). Both are driven by the GitHub Actions pipeline in [`.github/workflows/ci-cd.yml`](../../.github/workflows/ci-cd.yml), but you'll also do manual deploys locally while iterating on infrastructure.

## Manual Infrastructure Deployment

This is the same flow described in the root [README "Infrastructure Deployment"](../../README.md#1-infrastructure-deployment-aws) section, with more detail.

1. Make sure you have AWS CLI v2 configured with credentials that can manage IoT Core, Lambda, API Gateway, DynamoDB, Cognito, and S3 (see [`setup/aws_setup.md`](../setup/aws_setup.md)).

2. Navigate to the Terraform root:
   ```bash
   cd infra-iot-fleet/terraform
   ```

3. Initialize the backend and providers. State is stored remotely in the `fleexa-s3-tfstate` S3 bucket with locking via the `fleexa-dynamoDB-tflock` DynamoDB table (see [`backend.tf`](../../infra-iot-fleet/terraform/backend.tf)), so `init` must succeed before anything else will:
   ```bash
   terraform init
   ```

4. Format and validate before touching real infrastructure:
   ```bash
   terraform fmt -check -recursive
   terraform validate
   ```

5. Review the plan, then apply:
   ```bash
   terraform plan -var="aws_region=us-east-1" -out=tfplan
   terraform show tfplan
   terraform apply tfplan
   ```
   `terraform apply` provisions/updates the IoT Core Thing type and policy, the DynamoDB tables, the Cognito user pool, the API Gateway, the S3 data lake bucket, and the Lambda functions (built from `backend/cmd/*` — see [`lambda_build.tf`](../../infra-iot-fleet/terraform/lambda_build.tf)) in one pass.

6. Capture the outputs you'll need for backend and mobile configuration:
   ```bash
   terraform output
   ```
   Only `api_endpoint` / `api_url` are exposed as root-level outputs today. For the IoT Core data endpoint (needed by device simulators and the backend's `IOT_ENDPOINT` variable), query it directly:
   ```bash
   aws iot describe-endpoint --endpoint-type iot:Data-ATS --region us-east-1 --query endpointAddress --output text
   ```
   For the Cognito `user_pool_id` / `client_id`, either check the Cognito console for the pool Terraform created, or inspect the module's state directly:
   ```bash
   terraform state show 'module.cognito.aws_cognito_user_pool.pool'
   terraform state show 'module.cognito.aws_cognito_user_pool_client.client'
   ```
   See [`backend/README.md#environment-variables`](../../backend/README.md#environment-variables) for where each value goes.

## Automated Deployment (CI/CD)

The full pipeline lives in [`.github/workflows/ci-cd.yml`](../../.github/workflows/ci-cd.yml) and runs on every push to `main` or `dev-branch`, and on pull requests targeting `main`. Its jobs, in dependency order:

| Job | Runs when | What it does |
| :--- | :--- | :--- |
| **`test`** ("Unit Tests & Schema Validation") | always | Installs `requirements.txt`, runs the simulator unit tests (`test_schemas.py`, `test_sensors.py`, `test_actuators.py`) and a project-root import smoke check. Pure offline, no AWS needed. |
| **`test-go`** ("Go Backend Unit Tests & Build") | always | `go test ./... -v` and `go build ./...` inside `backend/`. |
| **`build`** ("Build Docker Image") | after `test` | Builds the `devices/Dockerfile` image and runs an import smoke test inside the built container. |
| **`terraform-plan`** ("Terraform Plan (Dry Run)") | on pushes to non-`main` branches, or `workflow_dispatch` (needs `test` + `test-go`) | `terraform init`, `fmt -check`, `validate`, then `terraform plan` — no changes are ever applied here. |
| **`terraform-deploy`** ("Deploy Infrastructure to AWS (us-east-1)") | **only** on push to `main` or `Lambda-CI/CD-Implementation`, or `workflow_dispatch` (needs `test`, `test-go`, `build`, `terraform-plan`) | `terraform apply -auto-approve`, saves `terraform output -json` to `infrastructure-outputs.json`, and prints the live IoT Core endpoint. |
| **`verify-deploy`** ("Verify AWS Deployment") | after `terraform-deploy`, same branch condition | Confirms the expected IoT topic rules, DynamoDB tables, S3 buckets, and Lambda functions actually exist post-apply, and that the IoT CA certificate is `ACTIVE`. |

In short: **pushing to `dev-branch` only runs tests, the Docker build, and a Terraform plan** — nothing is applied. **Pushing to `main` (or the legacy `Lambda-CI/CD-Implementation` branch) runs the full pipeline through a real `terraform apply` and a post-deploy verification pass.** AWS credentials for the `terraform-plan`, `terraform-deploy`, and `verify-deploy` jobs come from the repository's `AWS` GitHub Environment secrets (`AWS_ACCESS_KEY_ID` / `AWS_SECRET_ACCESS_KEY`).

### Practical implications for contributors

- **Never push directly to `main`.** Land changes on `dev-branch` (or a feature branch merged into `dev-branch`) first, where CI only plans — it never mutates real AWS resources.
- A pull request into `main` triggers `terraform-plan` so reviewers can see the infrastructure diff before merge.
- If you need to force a full deploy outside the normal branch flow (e.g. to re-run `verify-deploy` after a manual console change), use the workflow's `workflow_dispatch` trigger from the Actions tab.
- Because `terraform-deploy` uses `-auto-approve`, any Terraform change merged to `main` goes live without a manual gate — review `terraform plan` output carefully in the PR before merging.

## Deploying Backend Code Changes

There is no separate "deploy the backend" step distinct from infrastructure — the Lambda functions are built and packaged as part of the same `terraform apply` (via [`lambda_build.tf`](../../infra-iot-fleet/terraform/lambda_build.tf), which compiles `backend/cmd/*` into deployable artifacts). To ship a backend code change:

1. Merge it to `main` through the normal PR flow.
2. The `terraform-deploy` job's `terraform apply` rebuilds and updates the affected Lambda function(s) automatically.
3. `verify-deploy` confirms `processing_main_lambda` and `iot-fleet-dev-api-service` (among others) still exist and are healthy.

## Deploying the Device Simulators

The simulators are not part of the Terraform apply — they're a Docker Compose stack you run wherever you want simulated devices to live (your laptop, a shared VM, etc.). See [`setup/docker_guide.md`](../setup/docker_guide.md) for the full workflow; in short:

```bash
cd devices
cp .env.example .env   # fill in AWS credentials
docker compose up --build -d
```

## Deploying the Mobile App

The Flutter app is not currently auto-deployed by CI. Build and distribute it manually per platform (`flutter build apk`, `flutter build ios`, etc.) — see [`mobile/README.md`](../../mobile/README.md) for local run instructions.
