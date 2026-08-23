<div align="center">
  <img src="../docs/assets/fleexa_letter_logo.svg" alt="Logo" width="100" height="100">
  <br></br>
  <h1 align="center">Fleexa Infrastructure</h1>

  <p align="center">
    <strong>Terraform IaC for the Fleexa AWS backend — Lambda, DynamoDB, API Gateway, Cognito, IoT Core.</strong>
    <br />
    <br />
    <a href="#repository-structure">Structure</a>
    ·
    <a href="#modules">Modules</a>
    ·
    <a href="#environments">Environments</a>
    ·
    <a href="#scripts">Scripts</a>
    ·
    <a href="#getting-started">Getting Started</a>
  </p>
</div>

<div align="center">

[![Terraform](https://img.shields.io/badge/Terraform-1.14.8-623CE4.svg?style=flat-square&logo=terraform)](https://www.terraform.io/)
[![AWS](https://img.shields.io/badge/AWS-Lambda_%7C_DynamoDB_%7C_IoT_Core-232F3E.svg?style=flat-square&logo=amazon-aws)](https://aws.amazon.com/)

</div>

---

## About

`infra-iot-fleet/` is the Terraform root for the Fleexa backend described in
[`backend/README.md`](../backend/README.md): it provisions the 5 Lambda functions
(`api-service`, `iot-ingestion` a.k.a. `processing_main_lambda`, `door-watch-service`,
`ac-timer-watch-service`, `db-export`), the 5 DynamoDB tables, the API Gateway HTTP API,
Cognito user pool, IoT Core rules/topics, and the S3 data lake bucket behind them.

State is stored remotely — see [`terraform/backend.tf`](./terraform/backend.tf) — in the
`fleexa-s3-tfstate` S3 bucket (key `iot-fleet/terraform.tfstate`) with locking via the
`fleexa-dynamoDB-tflock` DynamoDB table.

> Note: [`monitoring/`](../monitoring) at the repository root holds CloudWatch alarms,
> dashboards, and log retention config for these same resources. It is a deliberately
> separate, standalone stack and is **not** applied by this Terraform root — see
> [`monitoring/README.md`](../monitoring/README.md).

---

## Repository Structure

```text
infra-iot-fleet/
├── terraform/
│   ├── main.tf                # Wires the modules together (dynamodb, lambda, s3, cognito, ...)
│   ├── variables.tf           # Root input variables (project_name, aws_region, iot_endpoint, ...)
│   ├── outputs.tf              # api_endpoint / api_url outputs
│   ├── provider.tf            # AWS provider + required_providers
│   ├── backend.tf             # S3 remote state + DynamoDB state lock
│   ├── iotrules.tf            # AWS IoT Core topic rules → Lambda routing
│   ├── lambda_build.tf        # null_resource `go build` + archive_file steps per Lambda
│   ├── environments/
│   │   ├── dev.tfvars
│   │   ├── staging.tfvars
│   │   └── prod.tfvars
│   └── modules/
│       ├── api_gateway/       # HTTP API Gateway in front of api-service
│       ├── cognito/           # User pool + app client
│       ├── cron_aggregator/   # Scheduled daily_aggregator.py Lambda (S3 rollups)
│       ├── cron_export/       # db-export Lambda + daily EventBridge schedule
│       ├── dynamodb/          # The 5 Fleexa tables (telemetry, device_state, alerts, commands, users)
│       ├── iot_core/          # IoT Core endpoint / policy resources
│       ├── lambda/            # Generic Lambda function + exec role module (used by door-watch, ac-timer-watch)
│       └── s3/                # Data lake bucket
└── scripts/
    ├── deploy.sh               # terraform apply wrapper, by environment
    ├── plan.sh                 # terraform plan wrapper, by environment
    ├── validate.sh             # terraform validate + fmt -check
    └── register_devices.sh     # Provisions IoT Things/certs for the demo device fleet
```

---

## Modules

| Module | Provisions |
| :--- | :--- |
| `modules/dynamodb` | `Fleexa_Telemetry`, `Fleexa_Devices` (device state, GSI `OpenDoorsIndex`), `Fleexa_Alerts` (GSIs `UserAlertsIndex`, `DeviceAlertsIndex`), `Fleexa_Commands`, `Fleexa_Users` |
| `modules/lambda` | Reusable Lambda function + IAM exec role (used directly by `door-watch-service` and `ac-timer-watch-service`) |
| `modules/api_gateway` | HTTP API Gateway + the `api-service` Lambda behind it |
| `modules/cron_export` | The `db-export` Lambda and its daily `cron(0 0 * * ? *)` EventBridge trigger |
| `modules/cron_aggregator` | Scheduled Lambda that runs `backend/scripts/daily_aggregator.py` for the S3 cold-tier rollups |
| `modules/cognito` | User pool + app client backing Cognito-based auth |
| `modules/iot_core` | IoT Core endpoint / policy resources for MQTT device connectivity |
| `modules/s3` | `fleexa-data-lake-<environment>` bucket for the cold storage tier |

The `iot-ingestion` Lambda (`processing_main_lambda`) and the IoT Core topic rules that route
`devices/+/+/telemetry` and `devices/+/+/alerts` MQTT messages to it are declared directly in
[`terraform/lambda_build.tf`](./terraform/lambda_build.tf) and [`terraform/iotrules.tf`](./terraform/iotrules.tf).

---

## Environments

Each file under `terraform/environments/` is a `.tfvars` file for one deployment target
(`dev`, `staging`, `prod`) — `project_name`, `aws_region`, `iot_endpoint`,
`firebase_credentials_json`, and fleet location (`fleet_lat`/`fleet_lon`) all vary by environment.
Select one with `-var-file=environments/<env>.tfvars`, or via the wrapper scripts below.

---

## Scripts

| Script | Purpose |
| :--- | :--- |
| `scripts/plan.sh <env>` | Runs `terraform plan -var-file=environments/<env>.tfvars` |
| `scripts/deploy.sh <env>` | Runs `terraform apply -var-file=environments/<env>.tfvars` |
| `scripts/validate.sh` | Runs `terraform validate` and `terraform fmt -check -recursive` |
| `scripts/register_devices.sh` | Creates IoT Things, X.509 certs, and policy attachments for the 6 demo devices, then prints the MQTT endpoint for the simulators |

---

## Getting Started

### Prerequisites
* [Terraform](https://www.terraform.io/downloads) >= 1.0
* An AWS account with credentials configured (`aws configure` or equivalent)
* Go >= 1.24.2 to build the Lambda binaries (`terraform/lambda_build.tf` invokes `go build` via `local-exec`)

### Plan and deploy

```bash
cd infra-iot-fleet

./scripts/validate.sh
./scripts/plan.sh dev
./scripts/deploy.sh dev
```

### Provision demo devices

Once the IoT Core stack is up:

```bash
./scripts/register_devices.sh
```

This creates the 6 demo Things (`temp-sensor-01`, `light-sensor-01`, `gas-sensor-01`,
`door-sensor-01`, `ac-actuator-01`, `door-actuator-01`), saves their certificates under
`../devices/certs/`, and prints the `MQTT_ENDPOINT` to export before running the Python
simulators in [`devices/`](../devices).

<p align="right"><a href="#fleexa-infrastructure">Back to top</a></p>
