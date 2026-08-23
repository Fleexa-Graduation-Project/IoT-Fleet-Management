# API Endpoints

This page is a high-level index of the Fleexa REST API. For full request/response bodies, query
parameters, and worked examples for every route, see the detailed spec at
[`../../backend/docs/api/api_spec.md`](../../backend/docs/api/api_spec.md). The examples under
[`examples/`](./examples/) walk through a few of the most commonly used calls end to end.

The API is served by the `api-service` AWS Lambda function (a Gin router behind API Gateway) — see
[`backend/README.md`](../../backend/README.md) for the overall backend architecture.

## Base URL & Versioning

All routes are versioned under a single prefix:

```
/api/v1
```

Locally this is `http://localhost:8080/api/v1`; in a deployed environment it is whatever URL
Terraform outputs for the API Gateway stage (see [`infra-iot-fleet/`](../../infra-iot-fleet)).

## Authentication

Authentication is delegated entirely to **Amazon Cognito** — the backend never stores passwords.
Routes fall into two groups:

- **Public** — the `auth` sign-up/sign-in/password-reset routes, which exist to obtain tokens in
  the first place.
- **Private** — everything else. These require a Cognito access token sent as a Bearer header:

  ```
  Authorization: Bearer <cognito-access-token>
  ```

  A Gin middleware validates the JWT locally against cached Cognito signing keys (no external call
  per request) and extracts the caller's `user_id` (the Cognito `sub`). Every private handler scopes
  its DynamoDB reads/writes to that `user_id`, so one account can never see or control another
  account's devices — there is no cross-tenant query in the system.

Every JSON error response, public or private, uses the same shape:

```json
{ "error": "human readable message" }
```

## Auth

| Method | Path | Auth | Purpose |
| :--- | :--- | :---: | :--- |
| `POST` | `/auth/signup` | Public | Create a Cognito account and seed a default `Fleexa_Users` profile row. |
| `POST` | `/auth/signin` | Public | Exchange email/password for Cognito tokens. |
| `POST` | `/auth/refresh` | Public | Exchange a refresh token for a new access/ID token pair. |
| `POST` | `/auth/forgot-password` | Public | Trigger a Cognito verification code email. |
| `POST` | `/auth/reset-password` | Public | Complete a password reset using the emailed code. |
| `POST` | `/auth/change-password` | Private | Change the signed-in user's password. |
| `GET` | `/auth/profile` | Private | Return the Cognito identity (`user_id`, `username`, `email`) for the current token. |
| `DELETE` | `/auth/account` | Private | Delete the Cognito account and the associated `Fleexa_Users` row. |

## Devices

| Method | Path | Auth | Purpose |
| :--- | :--- | :---: | :--- |
| `GET` | `/devices` | Private | List the live state of every device owned by the caller. |
| `GET` | `/devices/:id` | Private | Full state for one device, enriched with device-type-specific insights (e.g. door unlock stats, AC running time, temperature min/max/average). |
| `GET` | `/devices/:id/telemetry` | Private | Historical readings for one device. Accepts `period` (`24h`, `7d`, `1m`) and `metric` (e.g. `temp`, `light_level`) query parameters — see [Data Tiering](../../backend/README.md#data-tiering). |
| `GET` | `/devices/:id/alerts` | Private | Alert history for one specific device. |
| `POST` | `/devices/:id/commands` | Private | Dispatch a control command to an actuator over MQTT (see [`examples/send_command.md`](./examples/send_command.md)). |
| `PUT` | `/devices/:id/preferences` | Private | Update per-device preferences — currently the door sensor's `normal_unlock_duration` baseline used for "above normal" unlock alerts. |

## Alerts

| Method | Path | Auth | Purpose |
| :--- | :--- | :---: | :--- |
| `GET` | `/alerts` | Private | Sorted alert feed across all of the caller's devices for the Notifications screen. Supports `limit` and `before` (cursor) query parameters. |
| `PUT` | `/alerts/read` | Private | Mark a single alert (`alert_id`) as read. |

## Users

| Method | Path | Auth | Purpose |
| :--- | :--- | :---: | :--- |
| `GET` | `/users/preferences` | Private | Return the caller's notification preferences and registered FCM device tokens. |
| `PUT` | `/users/preferences` | Private | Update notification preferences (`receive_notifications`, `receive_critical`, `receive_warnings`) and register/unregister a mobile device's FCM push token (`hardware_id` + `fcm_token`; an empty token unregisters that device). |

## System

| Method | Path | Auth | Purpose |
| :--- | :--- | :---: | :--- |
| `GET` | `/system/overview` | Private | Aggregated dashboard data: overall connection status, devices online count, an alerts-by-severity chart, and an AC energy consumption chart. Accepts the same `period` parameter as telemetry. |

## Machine-Readable Spec

A concise OpenAPI 3.0 description of these same routes lives at
[`openapi.yaml`](./openapi.yaml) in this directory, useful for generating clients or importing into
tools like Postman/Insomnia.
