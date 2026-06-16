#!/usr/bin/env python3
"""
simulate_devices.py
-------------------
Publishes randomised telemetry (and alerts where appropriate) directly
to the processing_main_lambda via boto3 Lambda invoke.

Sensor types  → telemetry messages with randomised edge-state values
Gas sensor    → also fires an 'alerts' message when alarm_on=True
Door sensor   → also fires an 'alerts' message when intrusion_detected=True
Actuators     → state driven by random command; never self-generate alerts

Usage:
    python simulate_devices.py                  # runs indefinitely
    python simulate_devices.py --once           # single round then exit
    python simulate_devices.py --count 5        # 5 rounds then exit
"""

import boto3
import json
import time
import random
import argparse
from datetime import datetime

# ─── Configuration ────────────────────────────────────────────────────────────

LAMBDA_FUNCTION   = "processing_main_lambda"
REGION            = "us-east-1"
INTERVAL_SECONDS  = 10          # seconds between full publish rounds

USER_ID = "34c81498-30c1-709b-3fe2-61f8bcce903a"

DEVICES = [
    {"device_id": "temp-sensor-01",   "type": "temp-sensor"},
    {"device_id": "light-sensor-01",  "type": "light-sensor"},
    {"device_id": "gas-sensor-01",    "type": "gas-sensor"},
    {"device_id": "door-sensor-01",   "type": "door-sensor"},
    {"device_id": "ac-actuator-01",   "type": "ac-actuator"},
    {"device_id": "door-actuator-01", "type": "door-actuator"},
]

# ─── AWS client ───────────────────────────────────────────────────────────────

lambda_client = boto3.client("lambda", region_name=REGION)

# ─── Payload generators ───────────────────────────────────────────────────────

def gen_temp_sensor():
    """~25% chance of HOT (>30), ~25% chance of COLD (<18), rest NORMAL."""
    roll = random.random()
    if roll < 0.25:
        temp = round(random.uniform(31.0, 45.0), 1)   # HOT
    elif roll < 0.50:
        temp = round(random.uniform(5.0, 17.9), 1)    # COLD
    else:
        temp = round(random.uniform(18.0, 30.0), 1)   # NORMAL
    humidity = round(random.uniform(30.0, 90.0), 1)
    return {"temp": temp, "humidity": humidity}


def gen_light_sensor():
    """~25% BRIGHT (>600 lux), ~25% DARK (<200 lux), rest NORMAL."""
    roll = random.random()
    if roll < 0.25:
        level = random.uniform(601.0, 1000.0)   # BRIGHT
    elif roll < 0.50:
        level = random.uniform(0.0, 199.9)      # DARK
    else:
        level = random.uniform(200.0, 600.0)    # NORMAL
    return {"light_level": round(level, 1)}


def gen_gas_sensor():
    """~30% chance of DANGER (alarm_on=True)."""
    alarm_on  = random.random() < 0.30
    gas_level = round(random.uniform(200.0, 900.0) if alarm_on else random.uniform(0.0, 199.9), 1)
    return {
        "gas_level":  gas_level,
        "alarm_on":   alarm_on,
        "ppm":        round(gas_level * 1.2, 1),
    }


def gen_door_sensor():
    """~30% chance of OPEN; intrusion_detected when open AND roll < 0.4."""
    open_val            = random.random() < 0.30
    duration_open_secs  = random.randint(5, 300) if open_val else 0
    intrusion_detected  = open_val and random.random() < 0.40
    return {
        "open":                    open_val,
        "duration_open_seconds":   duration_open_secs,
        "intrusion_detected":      intrusion_detected,
    }


def gen_ac_actuator():
    """Random ON/OFF driven by simulated command."""
    power_state  = random.choice(["ON", "OFF"])
    target_temp  = round(random.uniform(18.0, 28.0), 1)
    fan_speed    = random.choice(["LOW", "MEDIUM", "HIGH"])
    return {
        "power_state": power_state,
        "target_temp": target_temp,
        "fan_speed":   fan_speed,
    }


def gen_door_actuator():
    """Random LOCKED/UNLOCKED driven by simulated command."""
    lock_state = random.choice(["LOCKED", "UNLOCKED"])
    return {
        "lock_state":     lock_state,
        "last_command":   "remote",
        "battery_level":  random.randint(20, 100),
    }


PAYLOAD_GENERATORS = {
    "temp-sensor":    gen_temp_sensor,
    "light-sensor":   gen_light_sensor,
    "gas-sensor":     gen_gas_sensor,
    "door-sensor":    gen_door_sensor,
    "ac-actuator":    gen_ac_actuator,
    "door-actuator":  gen_door_actuator,
}

# ─── Alert builders ───────────────────────────────────────────────────────────

def build_gas_alert(user_id, device_id, payload, ts):
    gas_level = payload.get("gas_level", 0)
    severity  = "CRITICAL" if gas_level > 600 else "WARNING"
    return {
        "topic":   f"devices/{user_id}/{device_id}/alerts",
        "payload": {
            "user_id":   user_id,
            "device_id": device_id,
            "timestamp": ts,
            "type":      "gas-sensor",
            "payload": {
                **payload,
                "severity":    severity,
                "description": f"Gas alarm triggered — level {gas_level} ppm",
            },
        },
    }


def build_door_alert(user_id, device_id, payload, ts):
    duration = payload.get("duration_open_seconds", 0)
    severity = "CRITICAL" if duration > 120 else "WARNING"
    return {
        "topic":   f"devices/{user_id}/{device_id}/alerts",
        "payload": {
            "user_id":   user_id,
            "device_id": device_id,
            "timestamp": ts,
            "type":      "door-sensor",
            "payload": {
                **payload,
                "severity":    severity,
                "description": f"Intrusion detected — door open for {duration}s",
            },
        },
    }

# ─── Core publish ─────────────────────────────────────────────────────────────

def invoke(event: dict, label: str) -> bool:
    """Invoke the Lambda and return True on success."""
    try:
        resp = lambda_client.invoke(
            FunctionName=LAMBDA_FUNCTION,
            InvocationType="RequestResponse",
            Payload=json.dumps(event).encode(),
        )
        status   = resp["StatusCode"]
        fn_error = resp.get("FunctionError")
        body     = json.loads(resp["Payload"].read())

        if fn_error:
            print(f"  ✗  {label:<35} status={status} error={body.get('errorMessage', fn_error)}")
            return False

        print(f"  ✓  {label:<35} status={status}")
        return True

    except Exception as exc:
        print(f"  ✗  {label:<35} invoke failed: {exc}")
        return False


def run_round():
    ts = int(time.time())   # always use real current time → passes envelope validation
    print(f"\n[{datetime.utcnow().strftime('%H:%M:%S')} UTC]  Publishing round ...")

    for device in DEVICES:
        device_id   = device["device_id"]
        device_type = device["type"]
        payload     = PAYLOAD_GENERATORS[device_type]()

        # ── telemetry message ──────────────────────────────────────────────
        telemetry_event = {
            "topic":   f"devices/{USER_ID}/{device_id}/telemetry",
            "payload": {
                "user_id":   USER_ID,
                "device_id": device_id,
                "timestamp": ts,
                "type":      device_type,
                "payload":   payload,
            },
        }
        invoke(telemetry_event, f"{device_id} / telemetry")

        # ── auto-fire alerts for sensors that warrant them ─────────────────
        if device_type == "gas-sensor" and payload.get("alarm_on"):
            alert_event = build_gas_alert(USER_ID, device_id, payload, ts)
            invoke(alert_event, f"{device_id} / alert (gas)")

        elif device_type == "door-sensor" and payload.get("intrusion_detected"):
            alert_event = build_door_alert(USER_ID, device_id, payload, ts)
            invoke(alert_event, f"{device_id} / alert (intrusion)")

# ─── Entry point ──────────────────────────────────────────────────────────────

def main():
    parser = argparse.ArgumentParser(description="Fleexa device simulator")
    group  = parser.add_mutually_exclusive_group()
    group.add_argument("--once",  action="store_true", help="Run a single round and exit")
    group.add_argument("--count", type=int,            help="Run N rounds then exit")
    args = parser.parse_args()

    if args.once:
        run_round()
    elif args.count:
        for i in range(args.count):
            print(f"Round {i+1}/{args.count}")
            run_round()
            if i < args.count - 1:
                time.sleep(INTERVAL_SECONDS)
    else:
        print(f"Running indefinitely — interval {INTERVAL_SECONDS}s  (Ctrl-C to stop)")
        while True:
            run_round()
            time.sleep(INTERVAL_SECONDS)


if __name__ == "__main__":
    main()
