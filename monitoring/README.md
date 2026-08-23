<div align="center">
  <img src="../docs/assets/fleexa_letter_logo.svg" alt="Logo" width="100" height="100">
  <br></br>
  <h1 align="center">Fleexa Monitoring</h1>

  <p align="center">
    <strong>CloudWatch alarms, dashboards, and log configuration for the Fleexa backend.</strong>
    <br />
    <br />
    <a href="#what-this-covers">What This Covers</a>
    ·
    <a href="#repository-structure">Structure</a>
    ·
    <a href="#alarms">Alarms</a>
    ·
    <a href="#dashboards">Dashboards</a>
    ·
    <a href="#usage">Usage</a>
  </p>
</div>

---

## What This Covers

This directory is a **standalone observability stack** for the Fleexa backend. It is not wired into
[`infra-iot-fleet/terraform/main.tf`](../infra-iot-fleet/terraform/main.tf) — the core infrastructure
can be deployed, destroyed, or rebuilt without ever touching these resources, and this stack can be
applied independently against an environment where the backend already exists. See the root
[`README.md`](../README.md#repository-structure) Repository Structure section, which lists
`monitoring/` as its own top-level concern: "CloudWatch dashboards and logging configurations".

It watches the five Lambda functions and five DynamoDB tables described in
[`backend/README.md`](../backend/README.md):

**Lambda functions**
* `api-service` — REST API behind API Gateway
* `iot-ingestion` — MQTT telemetry processor
* `door-watch` — scheduled door alert escalation (every 1 min)
* `ac-timer-watch` — scheduled AC auto shutoff (every 1 min)
* `db-export` — DynamoDB → S3 export

**DynamoDB tables**
* `Fleexa_Devices` (GSI: `OpenDoorsIndex`)
* `Fleexa_Telemetry`
* `Fleexa_Alerts` (GSIs: `DeviceAlertsIndex`, `UserAlertsIndex`)
* `Fleexa_Commands` (GSI: `DeviceHistoryIndex`)
* `Fleexa_Users`

---

## Repository Structure

```text
monitoring/
├── cloudwatch/
│   ├── metrics.tf                       # Metric alarms: Lambda errors/latency, DynamoDB throttles
│   ├── alarms/
│   │   ├── high_error_rate.json         # put-metric-alarm body: aggregate Lambda error rate
│   │   ├── high_latency.json            # put-metric-alarm body: Lambda p99 Duration
│   │   └── low_device_connectivity.json # put-metric-alarm body: connected device count drop
│   └── dashboards/
│       ├── lambda_dashboard.json        # Invocations / Errors / Duration per function
│       ├── dynamodb_dashboard.json      # Capacity / throttles per table
│       └── system_dashboard.json        # Top-level fleet health overview
├── logs/
│   ├── log_groups.tf                    # Explicit aws_cloudwatch_log_group per Lambda function
│   └── retention_policy.tf              # Per-environment retention days (dev/staging/prod)
└── README.md
```

---

## Alarms

| Alarm | Metric | Trigger |
| :--- | :--- | :--- |
| **Error rate** (`metrics.tf` + `alarms/high_error_rate.json`) | `AWS/Lambda Errors` | Sum of errors exceeds threshold within a 5 minute window, per function (Terraform) and in aggregate across all five functions (JSON alarm body). |
| **Latency** (`metrics.tf` + `alarms/high_latency.json`) | `AWS/Lambda Duration` (p99) | p99 duration exceeds the configured threshold for 3 consecutive periods, per function and as a fleet-wide max. |
| **DynamoDB throttling** (`metrics.tf`) | `AWS/DynamoDB ReadThrottleEvents` / `WriteThrottleEvents` | Any throttled request against one of the 5 tables. |
| **Low device connectivity** (`alarms/low_device_connectivity.json`) | `Fleexa/DeviceConnectivity ConnectedDeviceCount` (custom) | Average connected device count drops below the expected demo fleet size (see below). |

The `low_device_connectivity` alarm watches a **custom metric**, not something the backend already
publishes today. It assumes a small periodic job (e.g. a scheduled Lambda, or logic added to
`door-watch`/`ac-timer-watch`) scans `Fleexa_Devices` and counts devices whose heartbeat
(`last_seen` / `updated_at`) falls inside the expected heartbeat window, then publishes that count
to CloudWatch under namespace `Fleexa/DeviceConnectivity`, metric `ConnectedDeviceCount`. The default
threshold (3) is sized against the 6 demo devices provisioned by
[`infra-iot-fleet/scripts/register_devices.sh`](../infra-iot-fleet/scripts/register_devices.sh)
(`temp-sensor-01`, `light-sensor-01`, `gas-sensor-01`, `door-sensor-01`, `ac-actuator-01`,
`door-actuator-01`) — adjust it once the fleet is provisioned at real scale.

---

## Dashboards

* **`lambda_dashboard.json`** — Invocations, Errors, and average Duration for each of the 5 functions.
* **`dynamodb_dashboard.json`** — Consumed read/write capacity and read/write throttle events for each of the 5 tables.
* **`system_dashboard.json`** — A single-glance overview: total invocations and errors across the fleet, aggregate DynamoDB throttling, and the custom connected-device-count metric.

---

## Logs

`logs/log_groups.tf` explicitly manages the `/aws/lambda/<function-name>` log group for each of the
5 functions (Lambda creates these automatically on first invocation with no retention set — i.e.
logs are kept forever — so this module takes ownership of retention instead of leaving it unbounded).
`logs/retention_policy.tf` maps environment → retention days:

| Environment | Retention |
| :--- | :--- |
| `dev` | 14 days |
| `staging` | 14 days |
| `prod` | 30 days |

---

## Usage

Both `cloudwatch/` and `logs/` are self-contained Terraform root modules (each declares its own
`terraform`/`provider` block), so they can be applied independently of
`infra-iot-fleet/terraform`:

```bash
cd monitoring/cloudwatch
terraform init
terraform apply -var="environment=prod" -var="alarm_actions=[\"arn:aws:sns:us-east-1:<account-id>:fleexa-alerts\"]"

cd ../logs
terraform init
terraform apply -var="environment=prod"
```

The alarm and dashboard JSON files under `cloudwatch/alarms/` and `cloudwatch/dashboards/` are
plain AWS CLI request bodies, useful for a quick `aws cloudwatch put-metric-alarm` /
`put-dashboard` without going through Terraform, e.g.:

```bash
aws cloudwatch put-metric-alarm --cli-input-json file://cloudwatch/alarms/high_error_rate.json
aws cloudwatch put-dashboard --dashboard-name Fleexa-Lambda --dashboard-body file://cloudwatch/dashboards/lambda_dashboard.json
```

<p align="right"><a href="#fleexa-monitoring">Back to top</a></p>
