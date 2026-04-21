# Fleexa API Specification (v1)

**Base URL:** `http://localhost:8080/api/v1`  
**Content-Type:** `application/json`

---

## 1. System Overview & Device State

### 1.1 Get System Overview

Retrieves high-level aggregated data for the Global Dashboard (system health, alerts, energy).

- **Endpoint:** `GET /system/overview`
- **Query Parameters (Optional):**

  - `period` (string): `24h`, `7d`, `1m`

- **Response (200 OK):**

```json
{
  "system_status": "Connected",
  "devices_online": "5 / 5",
  "alerts_chart": {
    "critical": [
      { "label": "Mon", "value": 0 },
      { "label": "Tue", "value": 2 }
    ],
    "warning": [
      { "label": "Mon", "value": 3 },
      { "label": "Tue", "value": 1 }
    ]
  },
  "alerts_chart_max": 5.0,
  "energy_consumption": [
    { "label": "Mon", "value": 12.4 },
    { "label": "Tue", "value": 15.1 }
  ],
  "energy_chart_max": 15.1
}
```

---

### 1.2 Get All Devices List

Retrieves live status of all devices.

- **Endpoint:** `GET /devices`

- **Response (200 OK):**

```json
{
  "data": [
    {
      "device_id": "temp-sensor-01",
      "type": "temp-sensor",
      "status": "ONLINE",
      "operational_state": "NORMAL",
      "health": "HEALTHY",
      "payload": {
        "temp": 24.5
      },
      "last_seen_at": 1708434000
    },
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
        "timer_end_timestamp": 0
      },
      "last_seen_at": 1708434000
    }
  ]
}
```

---

### 1.3 Get Specific Device Details

Retrieves full device state + insights.

- **Endpoint:** `GET /devices/:id`

- **Endpoint:** `GET /devices/ac-actuator-01`
- **Response (200 OK):**

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
      {
        "event": "A/C turned ON",
        "time": "3:04 PM",
        "timestamp": 1708434000
      }
    ]
  },
  "last_seen_at": 1708434000
}
```

- **Endpoint:** `GET /devices/door-actuator-01`

- **Response (200 OK):**

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
      {
        "event": "Door locked",
        "time": "8:45 PM",
        "timestamp": 1713386700
      },
      {
        "event": "Door unlocked",
        "time": "8:42 PM",
        "timestamp": 1713386520
      }
    ]
  },
  "last_seen_at": 1713386750
}
```

- **Endpoint:** `GET /devices/gas-sensor-01`

- **Response (200 OK):**

```json
{
  "device_id": "gas-sensor-01",
  "type": "gas-sensor",
  "status": "ONLINE",
  "operational_state": "WARNING",
  "health": "HEALTHY",
  "payload": {
    "gas_level": 520.0,
    "status": "WARNING",
    "alarm_on": false,
    "recent_events": [
      {
        "description": "Gas level Exceed safe limit",
        "gas_level": "500 PPM",
        "time": "1 min ago",
        "timestamp": 1713386700
      },
      {
        "description": "Gas spike detected",
        "gas_level": "350 PPM",
        "time": "1 hour ago",
        "timestamp": 1713383100
      }
    ]
  },
  "last_seen_at": 1713386750
}
```

- **Endpoint:** `GET /devices/light-sensor-01`

- **Response (200 OK):**
```json
{
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
}
```

- **Endpoint:** `GET /devices/temp-sensor-01`
- **Response (200 OK):**
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





---

## 2. Telemetry, Analytics, and Alerts (The Insights)

### 2.1 Get Device Telemetry & Insights

Retrieves historical data + analytics.

- **Endpoint:** `GET /devices/:id/telemetry`
- **Query Parameters:**

  - `period`: `24h`, `7d`, `1m`
  - `metric`: e.g. `temp`, `light_level`

- **Response (200 OK):**

```json
{
  "device_id": "temp-sensor-01",
  "period": "24h",
  "source": "DynamoDB",
  "data": [
    { "label": "14:00", "value": 29.0 },
    { "label": "16:00", "value": 28.5 }
  ],
  "chart_max": 29.0
}
```
- **Endpoint:** `GET /devices/light-sensor-01/telemetry?period=24h&metric=light_level`
- **Response (200 OK):**
```json
{
  "device_id": "light-sensor-01",
  "period": "24h",
  "source": "DynamoDB",
  "data": [
    { "label": "18:00", "value": 180.0 },
    { "label": "20:00", "value": 45.0 },
    { "label": "22:00", "value": 0.0 },
    { "label": "00:00", "value": 0.0 },
    { "label": "02:00", "value": 0.0 },
    { "label": "04:00", "value": 15.0 },
    { "label": "06:00", "value": 120.0 },
    { "label": "08:00", "value": 350.0 },
    { "label": "10:00", "value": 680.0 },
    { "label": "12:00", "value": 850.0 },
    { "label": "14:00", "value": 810.0 },
    { "label": "16:00", "value": 410.0 }
  ],
  "chart_max": 850.0
}
```

---

### 2.2 Get Device Alerts

Retrieves warnings & critical events for specific device.

- **Endpoint:** `GET /devices/:id/alerts`

- **Response (200 OK):**

```json
{
  "data": [
    {
      "device_id": "gas-sensor-01",
      "timestamp": 1708430000,
      "type": "gas-sensor",
      "severity": "CRITICAL",
      "payload": {
        "gas_level": 950,
        "status": "DANGER",
        "alarm_on": true
      }
    }
  ]
}
```

### 2.3 Get All Sorted Alerts for all devices (Notifications Screen)

Retrieves all recent sorted alerts across all devices for the last 7 days.

- **Endpoint:** `GET /alerts`

- **Response (200 OK):**

```json
{
  "data": [
    {
      "device_id": "gas-sensor-01",
      "timestamp": 1708434000,
      "type": "gas-sensor",
      "severity": "CRITICAL",
      "payload": {
        "gas_level": 950,
        "status": "DANGER",
        "alarm_on": true
      }
    },
    {
      "device_id": "door-actuator-01",
      "timestamp": 1708430000,
      "type": "door-actuator",
      "severity": "WARNING",
      "payload": {
        "lock_state": "UNLOCKED"
      }
    }
  ]
}
```

---

## 3. Device Control (Actuators)

### 3.1 Send Command to Device

Sends command to actuator via MQTT.

- **Endpoint:** `POST /devices/:id/commands`

- **Request Body:**
```json
{
  "action": "SET_STATE",
  "parameters": {
    "power_state": "ON",
    "target_temp": 24.0,
    "mode": "COOLING"
  }
}
```

- **Response (202 Accepted):**

```json
{
  "message": "Command dispatched successfully",
  "request_id": "cmd-1708434000123"
}
```

---

## 4. Authentication & Security (Upcoming)

Authentication will be handled via AWS Cognito or a dedicated service.

### 4.1 Planned Auth Flows

- **Sign In:** `POST /auth/login` → Returns JWT
- **Sign Up:** `POST /auth/register`
- **Verify:** `POST /auth/verify`
