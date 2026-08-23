# Example: Querying Device Telemetry

`GET /devices/:id/telemetry` returns chart-ready historical data for one device, automatically
routed to the correct storage tier based on the requested time window. See
[`backend/README.md`](../../../backend/README.md#data-tiering) and
[`GetDeviceTelemetry`](../../../backend/internal/api/handlers/device_handler.go) for the
implementation.

## Query parameters

| Parameter | Values | Default | Notes |
| :--- | :--- | :--- | :--- |
| `period` | `24h`, `7d`, `1m` | `24h` | Selects the time window **and** the storage tier. |
| `metric` | e.g. `temp`, `light_level`, `gas_level` | `temp` | Which payload field to chart. Must match a field that device type actually reports. |

## Data tiering

| `period` | Tier | Backing store | `source` value |
| :--- | :--- | :--- | :--- |
| `24h` | Hot | DynamoDB (`Fleexa_Telemetry`, raw readings, 7-day TTL) | `"DynamoDB"` |
| `7d` | Cold | S3, pre-aggregated JSON (`processed-charts/<user_id>/<device_id>/<YYYY-MM>.json`) | `"S3 processed data"` |
| `1m` | Cold | Same S3 objects, chunked into weekly buckets | `"S3 processed data"` |

The client never needs to know which store actually served the request — the `source` field in the
response is purely informational.

## `period=24h` (hot tier)

```
GET /api/v1/devices/temp-sensor-01/telemetry?period=24h&metric=temp
Authorization: Bearer <cognito-access-token>
```

```json
{
  "device_id": "temp-sensor-01",
  "period": "24h",
  "source": "DynamoDB",
  "data": [
    { "label": "14:00", "value": 29.0 },
    { "label": "16:00", "value": 28.5 },
    { "label": "18:00", "value": 27.1 }
  ],
  "chart_max": 29.0
}
```

For `ac-actuator` devices specifically, a `period=24h` query also includes a computed
`running_time` field (total time powered on within the window):

```json
{
  "device_id": "ac-actuator-01",
  "period": "24h",
  "source": "DynamoDB",
  "data": [
    { "label": "14:00", "value": 1.0 },
    { "label": "16:00", "value": 0.0 }
  ],
  "chart_max": 1.0,
  "running_time": "2h 30m"
}
```

## `period=7d` (cold tier, with a "today" overlay)

```
GET /api/v1/devices/temp-sensor-01/telemetry?period=7d
```

```json
{
  "device_id": "temp-sensor-01",
  "period": "7d",
  "source": "S3 processed data",
  "data": [
    { "label": "Apr 21", "value": 24.8 },
    { "label": "Apr 22", "value": 25.1 },
    { "label": "Apr 23", "value": 25.3 },
    { "label": "Apr 24", "value": 26.0 },
    { "label": "Apr 25", "value": 25.7 },
    { "label": "Apr 26", "value": 25.9 },
    { "label": "Apr 27", "value": 26.2 }
  ]
}
```

Each label is one calendar day (`Jan 02` format), oldest to newest, matching the day keys used in
the S3 pre-aggregated JSON.

`7d` and `1m` data comes from nightly pre-aggregated S3 JSON, so the day-in-progress would
otherwise be missing or stale. To avoid that, the handler overlays live DynamoDB data for the
current day onto the last slot of the 7-day chart (`overlayToday` in the handler) — so "today"'s
value is always current even though the rest of the week comes from the S3 rollup.

## `period=1m` (cold tier, weekly buckets)

```
GET /api/v1/devices/temp-sensor-01/telemetry?period=1m
```

```json
{
  "device_id": "temp-sensor-01",
  "period": "1m",
  "source": "S3 processed data",
  "data": [
    { "label": "Week 1", "value": 24.8 },
    { "label": "Week 2", "value": 25.3 },
    { "label": "Week 3", "value": 26.0 },
    { "label": "Week 4", "value": 25.7 }
  ]
}
```

If no S3 data exists yet for the requested range (e.g. a brand-new account), `data` comes back as
an empty array rather than an error.

## A non-temperature metric

```
GET /api/v1/devices/light-sensor-01/telemetry?period=24h&metric=light_level
```

```json
{
  "device_id": "light-sensor-01",
  "period": "24h",
  "source": "DynamoDB",
  "data": [
    { "label": "18:00", "value": 180.0 },
    { "label": "20:00", "value": 45.0 },
    { "label": "22:00", "value": 0.0 },
    { "label": "06:00", "value": 120.0 },
    { "label": "12:00", "value": 850.0 }
  ],
  "chart_max": 850.0
}
```

## Error responses

Unknown device:

```
404 Not Found
```
```json
{ "error": "Device not found" }
```

Backend read failure:

```
500 Internal Server Error
```
```json
{ "error": "failed to fetch telemetry history: device_id=temp-sensor-01, period=24h, error=..." }
```
