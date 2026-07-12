class MockData {
  // 1. System Overview Data
  static const Map<String, String> systemOverview = {
    '24h': '''{
      "system_status": "Connected",
      "devices_online": "5 / 5",
      "alerts_chart": {
        "warning": [ { "label": "18:00", "value": 0 }, { "label": "20:00", "value": 2 }, { "label": "22:00", "value": 2 }, { "label": "00:00", "value": 2 }, { "label": "02:00", "value": 2 }, { "label": "04:00", "value": 3 }, { "label": "06:00", "value": 3 }, { "label": "08:00", "value": 3 }, { "label": "10:00", "value": 4 }, { "label": "12:00", "value": 4 }, { "label": "14:00", "value": 4 }, { "label": "16:00", "value": 4 } ],
        "critical": [ { "label": "18:00", "value": 0 }, { "label": "20:00", "value": 0 }, { "label": "22:00", "value": 0 }, { "label": "00:00", "value": 0 }, { "label": "02:00", "value": 0 }, { "label": "04:00", "value": 0 }, { "label": "06:00", "value": 1 }, { "label": "08:00", "value": 1 }, { "label": "10:00", "value": 2 }, { "label": "12:00", "value": 2 }, { "label": "14:00", "value": 2 }, { "label": "16:00", "value": 2 } ]
      },
      "alerts_chart_max": 4.0,
      "energy_consumption": [ { "label": "18:00", "value": 0.1 }, { "label": "20:00", "value": 0.1 }, { "label": "22:00", "value": 0.1 }, { "label": "00:00", "value": 0.1 }, { "label": "02:00", "value": 0.5 }, { "label": "04:00", "value": 1.2 }, { "label": "06:00", "value": 2.5 }, { "label": "08:00", "value": 3.1 }, { "label": "10:00", "value": 3.2 }, { "label": "12:00", "value": 2.8 }, { "label": "14:00", "value": 1.5 }, { "label": "16:00", "value": 0.8 } ],
      "energy_chart_max": 3.2
    }''',
    '7d': '''{
      "system_status": "Connected",
      "devices_online": "5 / 5",
      "alerts_chart": {
        "warning": [ { "label": "Wed", "value": 2 }, { "label": "Thu", "value": 5 }, { "label": "Fri", "value": 0 }, { "label": "Sat", "value": 2 }, { "label": "Sun", "value": 0 }, { "label": "Mon", "value": 3 }, { "label": "Tue", "value": 1 } ],
        "critical": [ { "label": "Wed", "value": 2 }, { "label": "Thu", "value": 2 }, { "label": "Fri", "value": 1 }, { "label": "Sat", "value": 1 }, { "label": "Sun", "value": 3 }, { "label": "Mon", "value": 0 }, { "label": "Tue", "value": 0 } ]
      },
      "alerts_chart_max": 5.0,
      "energy_consumption": [ { "label": "Wed", "value": 14.5 }, { "label": "Thu", "value": 16.2 }, { "label": "Fri", "value": 10.1 }, { "label": "Sat", "value": 12.4 }, { "label": "Sun", "value": 8.5 }, { "label": "Mon", "value": 15.0 }, { "label": "Tue", "value": 13.8 } ],
      "energy_chart_max": 16.2
    }''',
    '1m': '''{
      "system_status": "Connected",
      "devices_online": "5 / 5",
      "alerts_chart": {
        "warning": [ { "label": "W1", "value": 10 }, { "label": "W2", "value": 15 }, { "label": "W3", "value": 8 }, { "label": "W4", "value": 12 } ],
        "critical": [ { "label": "W1", "value": 5 }, { "label": "W2", "value": 8 }, { "label": "W3", "value": 2 }, { "label": "W4", "value": 6 } ]
      },
      "alerts_chart_max": 12,
      "energy_consumption": [ { "label": "W1", "value": 85.4 }, { "label": "W2", "value": 92.1 }, { "label": "W3", "value": 78.5 }, { "label": "W4", "value": 105.2 } ],
      "energy_chart_max": 105.2
    }'''
  };

  // 2. All Devices List
  static const String allDevices = '''{
    "data": [
      { "device_id": "temp-sensor-01", "type": "temp-sensor", "status": "ONLINE", "operational_state": "HOT", "health": "DEGRADED", "payload": { "temp": 32.5 }, "last_seen_at": 1708434000 },
      { "device_id": "light-sensor-01", "type": "light-sensor", "status": "ONLINE", "operational_state": "BRIGHT", "health": "HEALTHY", "payload": { "light_level": 750.0, "light_status": "Bright" }, "last_seen_at": 1708434000 },
      { "device_id": "gas-sensor-01", "type": "gas-sensor", "status": "ONLINE", "operational_state": "SAFE", "health": "HEALTHY", "payload": { "gas_level": 120, "status": "SAFE", "alarm_on": false }, "last_seen_at": 1708434000 },
      { "device_id": "door-actuator-01", "type": "door-actuator", "status": "ONLINE", "operational_state": "LOCKED", "health": "HEALTHY", "payload": { "lock_state": "LOCKED", "open": false }, "last_seen_at": 1708434000 },
      { "device_id": "ac-actuator-01", "type": "ac-actuator", "status": "ONLINE", "operational_state": "ON", "health": "HEALTHY", "payload": { "power_state": "ON", "mode": "COOLING", "target_temp": 22.0, "last_turned_on": 1708434000, "timer_end_timestamp": 0 }, "last_seen_at": 1708434000 }
    ]
  }''';

  // 3. Specific Device Details
  static const Map<String, String> deviceDetails = {
    'ac-actuator-01':
        '''{ "device_id": "ac-actuator-01", "type": "ac-actuator", "status": "ONLINE", "operational_state": "ON", "health": "HEALTHY", "payload": { "power_state": "ON", "target_temp": 24.0, "mode": "COOLING", "last_turned_on": 1708434000, "timer_end_timestamp": 1708437600, "inside_temp": 25.5, "outside_temp": 36.0, "time_remaining": "1h 0m", "running_time": "2h 30m", "recent_events": [ { "event": "A/C turned ON", "time": "3:04 PM", "timestamp": 1708434000 } ] }, "last_seen_at": 1708434000 }''',
    'light-sensor-01':
        '''{ "device_id": "light-sensor-01", "type": "light-sensor", "status": "ONLINE", "operational_state": "NORMAL", "health": "HEALTHY", "payload": { "light_level": 450.0, "light_status": "Normal" }, "last_seen_at": 1708434000 }''',
    'temp-sensor-01':
        '''{ "device_id": "temp-sensor-01", "type": "temp-sensor", "status": "ONLINE", "operational_state": "NORMAL", "health": "HEALTHY", "payload": { "temp": 24.5, "Min": 22.0, "Max": 29.0, "Average": 25.4 }, "last_seen_at": 1708434000 }''',
    'gas-sensor-01':
        '''{ "device_id": "gas-sensor-01", "type": "gas-sensor", "status": "ONLINE", "operational_state": "WARNING", "health": "DEGRADED", "payload": { "gas_level": 720, "status": "WARNING", "alarm_on": false, "recent_events": [ { "description": "Gas level Exceed safe limit", "gas_level": "500 PPM", "time": "1 min ago", "timestamp": 1713386700 } ] }, "last_seen_at": 1708434000 }''',
    'door-actuator-01':
        '''{ "device_id": "door-actuator-01", "type": "door-actuator", "status": "ONLINE", "operational_state": "LOCKED", "health": "HEALTHY", "payload": { "lock_state": "LOCKED", "open": false, "security_alert": "SAFE", "last_activity_time": "12 mins ago", "average_unlock": 7.0, "unlock_duration_status": "Normal", "recent_events": [ { "event": "Door locked", "time": "8:45 PM", "timestamp": 1713386700 }, { "event": "Door unlocked", "time": "8:42 PM", "timestamp": 1713386520 } ] }, "last_seen_at": 1713386750 }'''
  };

  // 4. Telemetry Data (Mapped by "deviceId_period")
  static const Map<String, String> telemetry = {
    'light-sensor-01_7d':
        '''{ "device_id": "light-sensor-01", "period": "7d", "source": "DynamoDB", "data": [ { "label": "Mon", "value": 300.0 }, { "label": "Tue", "value": 450.0 }, { "label": "Wed", "value": 500.0 }, { "label": "Thu", "value": 420.0 }, { "label": "Fri", "value": 480.0 }, { "label": "Sat", "value": 350.0 }, { "label": "Sun", "value": 280.0 } ], "chart_max": 500.0 }''',
    'light-sensor-01_24h':
        '''{ "device_id": "light-sensor-01", "period": "24h", "source": "DynamoDB", "data": [ { "label": "12 AM", "value": 0.0 }, { "label": "2 AM", "value": 0.0 }, { "label": "4 AM", "value": 15.0 }, { "label": "6 AM", "value": 120.0 }, { "label": "8 AM", "value": 350.0 }, { "label": "10 AM", "value": 680.0 }, { "label": "12 PM", "value": 850.0 }, { "label": "2 PM", "value": 810.0 }, { "label": "4 PM", "value": 410.0 }, { "label": "6 PM", "value": 180.0 }, { "label": "8 PM", "value": 45.0 }, { "label": "10 PM", "value": 0.0 } ], "chart_max": 850.0 }''',
    'light-sensor-01_1m':
        '''{ "device_id": "light-sensor-01", "period": "1m", "source": "DynamoDB", "data": [ { "label": "Week 1", "value": 390.0 }, { "label": "Week 2", "value": 410.0 }, { "label": "Week 3", "value": 360.0 }, { "label": "Week 4", "value": 480.0 } ], "chart_max": 480.0 }''',
    'temp-sensor-01_7d':
        '''{ "device_id": "temp-sensor-01", "period": "7d", "source": "DynamoDB", "data": [ { "label": "Sat", "value": 12.0 }, { "label": "Sun", "value": 32.0 }, { "label": "Mon", "value": 28.0 }, { "label": "Tue", "value": 30.0 }, { "label": "Wed", "value": 25.0 }, { "label": "Thu", "value": 18.0 }, { "label": "Fri", "value": 5.0 } ], "chart_max": 32.0 }''',
    'temp-sensor-01_24h':
        '''{ "device_id": "temp-sensor-01", "period": "24h", "source": "DynamoDB", "data": [ { "label": "18:00", "value": 26.0 }, { "label": "20:00", "value": 23.5 }, { "label": "22:00", "value": 21.0 }, { "label": "00:00", "value": 19.0 }, { "label": "02:00", "value": 18.5 }, { "label": "04:00", "value": 17.0 }, { "label": "06:00", "value": 17.5 }, { "label": "08:00", "value": 21.0 }, { "label": "10:00", "value": 24.0 }, { "label": "12:00", "value": 27.5 }, { "label": "14:00", "value": 29.5 }, { "label": "16:00", "value": 28.0 } ], "chart_max": 27.0 }''',
    'temp-sensor-01_1m':
        '''{ "device_id": "temp-sensor-01", "period": "1m", "source": "DynamoDB", "data": [ { "label": "Week 1", "value": 22.5 }, { "label": "Week 2", "value": 24.0 }, { "label": "Week 3", "value": 21.0 }, { "label": "Week 4", "value": 23.5 } ], "chart_max": 24.0 }''',
    'gas-sensor-01_7d':
        '''{ "device_id": "gas-sensor-01", "period": "7d", "source": "DynamoDB", "data": [ { "label": "Mon", "value": 20.0 }, { "label": "Tue", "value": 24.0 }, { "label": "Wed", "value": 22.0 }, { "label": "Thu", "value": 26.0 }, { "label": "Fri", "value": 28.0 }, { "label": "Sat", "value": 25.0 }, { "label": "Sun", "value": 23.0 } ], "chart_max": 28.0 }''',
    'gas-sensor-01_24h':
        '''{ "device_id": "gas-sensor-01", "period": "24h", "source": "DynamoDB", "data": [ { "label": "12 AM", "value": 20.0 }, { "label": "2 AM", "value": 22.0 }, { "label": "4 AM", "value": 19.0 }, { "label": "6 AM", "value": 25.0 }, { "label": "8 AM", "value": 30.0 }, { "label": "10 AM", "value": 28.0 }, { "label": "12 PM", "value": 35.0 }, { "label": "2 PM", "value": 820.0 }, { "label": "4 PM", "value": 50.0 }, { "label": "6 PM", "value": 25.0 }, { "label": "8 PM", "value": 22.0 }, { "label": "10 PM", "value": 20.0 } ], "chart_max": 820.0 }''',
    'gas-sensor-01_1m':
        '''{ "device_id": "gas-sensor-01", "period": "1m", "source": "DynamoDB", "data": [ { "label": "Week 1", "value": 25.0 }, { "label": "Week 2", "value": 28.0 }, { "label": "Week 3", "value": 22.0 }, { "label": "Week 4", "value": 26.0 } ], "chart_max": 28.0 }''',
    'ac-actuator-01_7d':
        '''{ "device_id": "ac-actuator-01", "period": "7d", "source": "DynamoDB", "data": [ { "label": "Sat", "value": 12.5 }, { "label": "Sun", "value": 20.0 }, { "label": "Mon", "value": 10.0 }, { "label": "Tue", "value": 2.0 }, { "label": "Wed", "value": 4.0 }, { "label": "Thu", "value": 13.0 }, { "label": "Fri", "value": 16.0 } ], "chart_max": 20.0 }''',
    'ac-actuator-01_24h':
        '''{ "device_id": "ac-actuator-01", "period": "24h", "source": "DynamoDB", "data": [ { "label": "12 AM", "value": 2.0 }, { "label": "2 AM", "value": 3.0 }, { "label": "4 AM", "value": 0.0 }, { "label": "6 AM", "value": 0.0 }, { "label": "8 AM", "value": 1.5 }, { "label": "10 AM", "value": 1.5 }, { "label": "12 PM", "value": 1.0 }, { "label": "2 PM", "value": 3.0 }, { "label": "4 PM", "value": 0.0 }, { "label": "6 PM", "value": 4.0 }, { "label": "8 PM", "value": 2.5 }, { "label": "10 PM", "value": 5.0 } ], "chart_max": 4.0 }''',
    'ac-actuator-01_1m':
        '''{ "device_id": "ac-actuator-01", "period": "1m", "source": "DynamoDB", "data": [ { "label": "Week 1", "value": 35.0 }, { "label": "Week 2", "value": 28.5 }, { "label": "Week 3", "value": 40.0 }, { "label": "Week 4", "value": 15.0 } ], "chart_max": 40.0 }'''
  };

  // 5. Specific Device Alerts
  static const Map<String, String> deviceAlerts = {
    'gas-sensor-01':
        '''{ "data": [ { "device_id": "gas-sensor-01", "timestamp": 1708442580, "type": "gas-sensor", "severity": "CRITICAL", "payload": { "gas_level": 820, "status": "DANGER", "alarm_on": true } }, { "device_id": "gas-sensor-01", "timestamp": 1708438980, "type": "gas-sensor", "severity": "WARNING", "payload": { "gas_level": 400, "status": "WARNING", "alarm_on": false } } ] }''',
    'door-actuator-01':
        '''{ "data": [ { "device_id": "door-actuator-01", "timestamp": 1708410000, "type": "door-actuator", "severity": "WARNING", "payload": { "lock_state": "UNLOCKED", "method": "Manual Keypad" } } ] }'''
  };

  // 6. Command Success
  static const String commandSuccess = '''{
    "message": "Command dispatched successfully",
    "request_id": "cmd-123456789"
  }''';

  // 7. All Sorted Alerts
  static const String allAlerts = '''{
    "data": [
      { "device_id": "gas-sensor-01", "timestamp": 1776440000, "type": "gas-sensor", "severity": "CRITICAL", "payload": { "gas_level": 950, "status": "DANGER", "alarm_on": true } },
      { "device_id": "door-actuator-01", "timestamp": 1776435000, "type": "door-actuator", "severity": "WARNING", "payload": { "lock_state": "UNLOCKED" } },
      { "device_id": "gas-sensor-01", "timestamp": 1776350000, "type": "gas-sensor", "severity": "WARNING", "payload": { "gas_level": 420, "status": "WARNING", "alarm_on": false } },
      { "device_id": "door-actuator-01", "timestamp": 1776340000, "type": "door-actuator", "severity": "WARNING", "payload": { "lock_state": "UNLOCKED" } },
      { "device_id": "door-actuator-01", "timestamp": 1776150000, "type": "door-actuator", "severity": "WARNING", "payload": { "lock_state": "UNLOCKED" } }
    ]
  }''';

  // 8. Authentication & Stateful Mock Data
  // ==========================================

  static List<Map<String, dynamic>> registeredUsers = [
    {"username": "Jana", "email": "jana@gmail.com", "password": "Password123"},
    {
      "username": "Nourhan",
      "email": "nourhan@gmail.com",
      "password": "Password123"
    }
  ];

  static Map<String, dynamic>? currentUser;

  static const String authSignInSuccess = '''{
    "access_token": "mock_access_token_123",
    "id_token": "mock_id_token_123",
    "refresh_token": "mock_refresh_token_123"
  }''';
}
