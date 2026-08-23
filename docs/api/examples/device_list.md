# Example: Listing & Reading Devices

Two related calls: `GET /devices` for a fleet-wide summary, and `GET /devices/:id` for one
device's full state. Both return `models.DeviceState` records — see
[`backend/models/deviceState.go`](../../../backend/models/deviceState.go). `payload` is a free-form
map whose fields depend on the device `type` (see the [Device Catalog](../../../README.md#device-catalog)
in the root README).

## `GET /devices`

Returns the latest known state of every device the caller owns — this is what backs the fleet
dashboard's device list.

```
GET /api/v1/devices
Authorization: Bearer <cognito-access-token>
```

```json
{
  "data": [
    {
      "user_id": "5f2a1c3e-...-92b1",
      "device_id": "temp-sensor-01",
      "type": "temp-sensor",
      "status": "ONLINE",
      "operational_state": "NORMAL",
      "health": "HEALTHY",
      "payload": {
        "temp": 24.5,
        "humidity": 41.0,
        "battery": 92
      },
      "last_seen_at": 1708434000
    },
    {
      "user_id": "5f2a1c3e-...-92b1",
      "device_id": "door-actuator-01",
      "type": "door-actuator",
      "status": "ONLINE",
      "operational_state": "LOCKED",
      "health": "HEALTHY",
      "payload": {
        "lock_state": "LOCKED",
        "open": false
      },
      "last_seen_at": 1713386750
    },
    {
      "user_id": "5f2a1c3e-...-92b1",
      "device_id": "gas-sensor-01",
      "type": "gas-sensor",
      "status": "ONLINE",
      "operational_state": "NORMAL",
      "health": "HEALTHY",
      "payload": {
        "gas_level": 120.0,
        "status": "SAFE",
        "alarm_on": false
      },
      "last_seen_at": 1713386750
    },
    {
      "user_id": "5f2a1c3e-...-92b1",
      "device_id": "light-sensor-01",
      "type": "light-sensor",
      "status": "ONLINE",
      "operational_state": "NORMAL",
      "health": "HEALTHY",
      "payload": {
        "light_level": 450.0,
        "light_status": "Normal"
      },
      "last_seen_at": 1713386750
    },
    {
      "user_id": "5f2a1c3e-...-92b1",
      "device_id": "ac-actuator-01",
      "type": "ac-actuator",
      "status": "ONLINE",
      "operational_state": "ON",
      "health": "HEALTHY",
      "payload": {
        "power_state": "ON",
        "target_temp": 24.0,
        "mode": "COOLING",
        "last_turned_on": 1708434000,
        "timer_end_timestamp": 0
      },
      "last_seen_at": 1708434000
    }
  ]
}
```

Notes on this response:

- `status` (`ONLINE`/`OFFLINE`) is derived at request time from `last_seen_at`, not stored.
- For `light-sensor` devices, the handler adds a human-readable `light_status` (`Bright` /
  `Normal` / `Dark`) derived from `operational_state`.
- `payload` shape differs per `type` — a `temp-sensor` payload is not the same shape as a
  `door-actuator` payload.

## `GET /devices/:id`

Returns everything from the list view for a single device, plus device-type-specific insights
computed from recent telemetry history. These extra fields only appear on this endpoint, not on
`GET /devices`.

### Door actuator — includes unlock stats and security status

```
GET /api/v1/devices/door-actuator-01
Authorization: Bearer <cognito-access-token>
```

```json
{
  "device_id": "door-actuator-01",
  "type": "door-actuator",
  "status": "ONLINE",
  "operational_state": "LOCKED",
  "health": "HEALTHY",
  "payload": {
    "lock_state": "LOCKED",
    "open": false,
    "security_alert": "SAFE",
    "last_activity_time": "12 mins ago",
    "average_unlock": 7.0,
    "unlock_duration_status": "Normal",
    "recent_events": [
      { "event": "Door locked", "time": "8:45 PM", "timestamp": 1713386700 },
      { "event": "Door unlocked", "time": "8:42 PM", "timestamp": 1713386520 }
    ]
  },
  "last_seen_at": 1713386750
}
```

`security_alert` escalates from `SAFE` to `WARNING` (unlocked > 7 min) to `CRITICAL_ALERT`
(unlocked > 15 min) — this is what the scheduled `door-watch` Lambda also keys off of when firing
escalating push notifications. `unlock_duration_status` compares `average_unlock` against the
device's `normal_unlock_duration` preference (settable via `PUT /devices/:id/preferences`,
default 15 seconds).

### AC actuator — includes runtime and timer insights

```json
{
  "device_id": "ac-actuator-01",
  "type": "ac-actuator",
  "status": "ONLINE",
  "operational_state": "ON",
  "health": "HEALTHY",
  "payload": {
    "power_state": "ON",
    "target_temp": 24.0,
    "mode": "COOLING",
    "last_turned_on": 1708434000,
    "timer_end_timestamp": 1708437600,
    "inside_temp": 25.5,
    "outside_temp": 36.0,
    "time_remaining": "1h 0m",
    "running_time": "2h 30m",
    "recent_events": [
      { "event": "A/C turned ON", "time": "3:04 PM", "timestamp": 1708434000 }
    ]
  },
  "last_seen_at": 1708434000
}
```

`inside_temp` is read from the `temp-sensor-01` device's own state, not from the AC unit itself.
If `timer_end_timestamp` is in the future, the `ac-timer-watch` Lambda (EventBridge, every minute)
will publish an MQTT `OFF` command and clear the timer once it expires.

### Temperature sensor — includes 24h min/max/average

```json
{
  "device_id": "temp-sensor-01",
  "type": "temp-sensor",
  "status": "ONLINE",
  "operational_state": "NORMAL",
  "health": "HEALTHY",
  "payload": {
    "temp": 24.5,
    "Min": 22.0,
    "Max": 29.0,
    "Average": 25.4
  },
  "last_seen_at": 1708434000
}
```

### Not found

```
GET /api/v1/devices/does-not-exist
```

```json
{ "error": "Device not found" }
```
