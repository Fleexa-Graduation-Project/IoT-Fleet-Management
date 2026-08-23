# System Architecture

Fleexa is a serverless-first IoT fleet management platform built entirely on AWS managed services. There is no Kubernetes, no self-managed message broker, and no long-lived server process anywhere in the stack — every backend workload runs as an AWS Lambda function, triggered either by AWS IoT Core, by API Gateway, or by EventBridge on a schedule.

This document describes the system at a high level. For a step-by-step trace of a single telemetry reading and a single command, see [`data_flow.md`](./data_flow.md). For how these pieces are provisioned, see [`deployment_architecture.md`](./deployment_architecture.md). For authentication and isolation guarantees, see [`security_model.md`](./security_model.md).

---

## Overview

```text
 ┌─────────────────┐        mTLS/MQTT        ┌────────────────┐
 │  Edge Devices    │ ───────────────────────▶ │  AWS IoT Core  │
 │ (Python sim.)    │ ◀─────────────────────── │  + IoT Policies│
 └─────────────────┘        commands           └───────┬────────┘
                                                         │ IoT Rules (SQL)
                                                         ▼
                              ┌───────────────────────────────────────────┐
                              │              AWS Lambda (Go)              │
                              │  iot-ingestion · door-watch ·             │
                              │  ac-timer-watch · api-service · db-export │
                              └───────┬───────────────────────┬───────────┘
                                      │                       │
                              ┌───────▼───────┐       ┌───────▼────────┐
                              │  DynamoDB     │       │  S3 Data Lake  │
                              │  (hot tier)   │       │  (cold tier)   │
                              └───────┬───────┘       └────────────────┘
                                      │
                     ┌────────────────┴─────────────────┐
                     ▼                                   ▼
           ┌───────────────────┐               ┌───────────────────┐
           │  API Gateway      │               │  Firebase Cloud   │
           │  + Cognito auth   │               │  Messaging (push) │
           └─────────┬─────────┘               └─────────┬─────────┘
                     ▼                                   ▼
                          ┌────────────────────────┐
                          │   Flutter Mobile App    │
                          └────────────────────────┘
```

## Layers

### 1. Edge simulation & connectivity

Dockerized Python simulators (`devices/simulators/`) stand in for physical hardware — temperature, gas, light and door sensors, plus door-lock and AC/curtain actuators (see the Device Catalog in the root [`README.md`](../../README.md)). Each simulated device authenticates directly to **AWS IoT Core** using per-device X.509 certificates and mutual TLS (mTLS); there is no intermediary gateway. What a device may publish, subscribe to, and receive is constrained by an **AWS IoT Policy** scoped to its Thing name (see [`security_model.md`](./security_model.md)).

### 2. AWS IoT Core + IoT Rules

IoT Core is the sole MQTT broker. Two **IoT Topic Rules**, defined in `infra-iot-fleet/terraform/iotrules.tf`, use IoT SQL to match inbound topics and route each message to a Lambda function:

- `<project>_telemetry_processor` — matches `devices/+/+/telemetry`, invokes the `iot-ingestion` Lambda.
- `<project>_alert_processor` — matches `devices/+/+/alerts`, invokes the same `iot-ingestion` Lambda.

There is no separate broker-side fan-out beyond these two rules; all routing logic past that point lives in Go.

### 3. Lambda processors (Go backend)

The backend (`backend/`) is organized as five independent, single-purpose Lambda functions that share the same internal packages but ship as separate binaries (see `backend/cmd/*`):

| Function | Trigger | Responsibility |
| :--- | :--- | :--- |
| **`iot-ingestion`** | AWS IoT Core (MQTT, via the two rules above) | Validates every incoming message (`internal/validation`), updates device state, runs the rules engine (`internal/rules`), saves alerts, sends push notifications. |
| **`api-service`** | API Gateway (HTTP, `ANY /{proxy+}`) | Serves the REST API behind a Gin router. Validates Cognito JWTs, reads device state/telemetry/alerts, dispatches commands back to devices. |
| **`door-watch`** | EventBridge, every 1 minute | Scans open/unlocked doors (via the `OpenDoorsIndex` GSI) and fires escalating alerts. |
| **`ac-timer-watch`** | EventBridge, every 1 minute | Finds AC units whose sleep timer has expired, publishes an MQTT OFF command back to the device, and clears the timer state. |
| **`db-export`** | EventBridge, daily | Exports selected DynamoDB tables to the S3 data lake for backup/offline analysis. |

This split follows the "Service-Based Architecture" decision documented in `backend/docs/architecture/decision-log.md`: the IoT data plane (`iot-ingestion`) is kept isolated from the API control plane (`api-service`) so that a bug or deploy in one can never take down the other, while `api-service` stays a single warm Lambda to avoid cold-start latency for the mobile app. A related, always-running scheduled function, the Python `daily_aggregator` Lambda (`backend/scripts/daily_aggregator.py`, provisioned by the `cron_aggregator` Terraform module), pre-aggregates DynamoDB data into the S3 cold tier once a day; it is not one of the five Go services but is part of the same data pipeline.

### 4. Data persistence — hot and cold tiers

| Tier | Store | Window | Used for |
| :--- | :--- | :--- | :--- |
| **Hot** | DynamoDB (`Fleexa_Devices`, `Fleexa_Telemetry`, `Fleexa_Alerts`, `Fleexa_Commands`, `Fleexa_Users`) | Last 24 hours (telemetry/commands carry a 7‑day TTL) | Live dashboards, device state, real-time queries |
| **Cold** | S3 data lake, pre-aggregated JSON | 7 days, 1 month | Historical charts, long-term trends |

`api-service`'s `/devices/:id/telemetry` endpoint accepts a `period` query parameter (`24h`, `7d`, `1m`) and transparently routes reads to the correct tier (`internal/telemetry` for DynamoDB, `internal/iot/s3ProcessedData.go` for S3), so the mobile client never has to know where the data physically lives.

### 5. Client API & security

`api-service` is fronted by **Amazon API Gateway** (HTTP API), which proxies every route to the single Lambda. Mobile/web clients authenticate against **Amazon Cognito**; the Lambda validates the resulting JWT locally against cached Cognito JWKS (`internal/auth/middleware.go`) on every request — no per-request call out to Cognito.

### 6. Mobile app & push notifications

The **Flutter mobile app** (`mobile/`) consumes the REST API for dashboards, device control, and history, and receives real-time alerts out-of-band through **Firebase Cloud Messaging (FCM)**. When the rules engine or a scheduled watcher decides a user needs to be notified, `internal/notifications` sends a multicast FCM push (with Android/APNs-specific payloads) to every device token registered for that user in `Fleexa_Users`.

---

## Component summary

| Component | AWS service | Backend package(s) |
| :--- | :--- | :--- |
| Device identity & transport | IoT Core (Things, Certificates, Policies) | `devices/certs/`, Terraform `modules/iot_core` |
| Message routing | IoT Core Topic Rules | Terraform `iotrules.tf` |
| Telemetry/alert ingestion | Lambda (`iot-ingestion`) | `internal/ingestion`, `internal/validation`, `internal/rules` |
| Scheduled door escalation | Lambda (`door-watch`) + EventBridge | `internal/rules` (`CheckDoorTimeouts`) |
| Scheduled AC auto-off | Lambda (`ac-timer-watch`) + EventBridge | `internal/devices`, `internal/iot` (publisher) |
| Daily cold-tier aggregation | Lambda (`daily_aggregator`, Python) + EventBridge | `backend/scripts/daily_aggregator.py` |
| Backup/export | Lambda (`db-export`) + EventBridge | `backend/cmd/db-export` |
| Hot data store | DynamoDB | `internal/devices`, `internal/telemetry`, `internal/alerts`, `internal/commands`, `internal/users` |
| Cold data store | S3 | `internal/iot/s3ProcessedData.go` |
| REST API | API Gateway (HTTP API) + Lambda (`api-service`) | `internal/api/handlers` |
| Auth | Cognito (User Pool + JWKS) | `internal/auth` |
| Push notifications | Firebase Cloud Messaging | `internal/notifications` |
| Mobile client | Flutter | `mobile/lib` |

---

## Design principle: device-agnostic pipeline

The ingestion pipeline, rules engine, and alert system are intentionally decoupled from any specific device category (see `backend/README.md`). Adding a new device type is a matter of registering it in `internal/devices` (its `DeviceRules`) and, if it needs bespoke alerting, adding a case to `internal/rules` — nothing else in the ingestion, storage, or API layers needs to change. The sensors and actuators shipped today (temperature, gas, light, door sensor, door lock, AC/curtain) are the demonstration layer for that generic pipeline, not a hard architectural boundary.
