import boto3
import json
import os
from datetime import datetime, timedelta
from decimal import Decimal

# Initialize AWS Clients
s3 = boto3.client('s3')

# Environment Variables configured
STATE_TABLE     = os.environ.get('STATE_TABLE',     'Fleexa_Devices')
TELEMETRY_TABLE = os.environ.get('TELEMETRY_TABLE', 'Fleexa_Telemetry')
ALERTS_TABLE    = os.environ.get('ALERTS_TABLE',    'Fleexa_Alerts')
BUCKET_NAME     = os.environ.get('BUCKET_NAME',     'fleexa-data-lake')

def decimal_default(obj):
    if isinstance(obj, Decimal):
        return float(obj)
    raise TypeError

def safe_float(val, default=0.0):
    try:
        return float(val)
    except (TypeError, ValueError):
        return default

def update_s3_chart(s3_key, day_label, new_entry):
    chart_data = []
    try:
        s3_resp = s3.get_object(Bucket=BUCKET_NAME, Key=s3_key)
        chart_data = json.loads(s3_resp['Body'].read().decode('utf-8'))
    except s3.exceptions.NoSuchKey:
        pass

    existing = next((x for x in chart_data if x["label"] == day_label), None)
    if existing:
        existing.update(new_entry)
    else:
        chart_data.append(new_entry)

    s3.put_object(
        Bucket=BUCKET_NAME,
        Key=s3_key,
        Body=json.dumps(chart_data, default=decimal_default),
        ContentType='application/json'
    )

def fetch_latest_s3_export(table_name):
    """
    Fetches the absolutely latest JSON export for a specific table from S3.
    It lists all prefixes and finds the most recent one.
    """
    try:
        # We need to find the latest export date directory first
        resp = s3.list_objects_v2(Bucket=BUCKET_NAME, Prefix="exports/")
        if 'Contents' not in resp:
            return []
            
        # Filter for the specific table
        table_objects = [obj for obj in resp['Contents'] if f"/{table_name}/" in obj['Key']]
        if not table_objects:
            return []
            
        # Sort by LastModified to get the most recent export
        latest_obj = sorted(table_objects, key=lambda x: x['LastModified'], reverse=True)[0]
        
        print(f"  -> Reading {latest_obj['Key']}")
        data_resp = s3.get_object(Bucket=BUCKET_NAME, Key=latest_obj['Key'])
        return json.loads(data_resp['Body'].read().decode('utf-8'))
    except Exception as e:
        print(f"  -> Failed to read latest export for {table_name}: {e}")
        return []

def lambda_handler(event, _context):
    print("Starting Nightly Data Lake ETL Job (S3 Source)...")

    # Check if this is a manual backfill trigger
    backfill_days = 1
    if isinstance(event, dict) and "backfill_days" in event:
        backfill_days = int(event["backfill_days"])
        print(f"Backfill mode: Processing last {backfill_days} days")

    now = datetime.now()

    # 1. Load the most recent Data Lake Exports into Memory ONCE
    print("Fetching latest Data Lake exports into memory...")
    active_devices  = fetch_latest_s3_export(STATE_TABLE)
    telemetry_items = fetch_latest_s3_export(TELEMETRY_TABLE)
    alerts_items    = fetch_latest_s3_export(ALERTS_TABLE)

    if not active_devices:
        print("No State export found in Data Lake. Exiting.")
        return {"status": "failed", "reason": "No State Export"}

    # Extract all unique user IDs
    user_ids = set()
    for device in active_devices:
        if device.get('user_id'):
            user_ids.add(device['user_id'])

    # Process each day from backfill_days down to 1 (yesterday)
    for i in range(backfill_days, 0, -1):
        target_date = now - timedelta(days=i)
        month_key = target_date.strftime("%Y-%m")          # e.g., "2026-04"
        day_label = target_date.strftime("%b %d")          # e.g., "Apr 28"

        print(f"Processing data for {day_label}...")

        start_time = int(target_date.replace(hour=0,  minute=0,  second=0).timestamp())
        end_time   = int(target_date.replace(hour=23, minute=59, second=59).timestamp())
        
        # 2. Process Telemetry per Device
        for device in active_devices:
            user_id     = device.get('user_id')
            device_id   = device.get('device_id')
            device_type = device.get('type')
            
            if not user_id or not device_id:
                continue

            # In-memory filter for this specific device and time range
            udk = f"{user_id}#{device_id}"
            device_telemetry = [
                item for item in telemetry_items 
                if item.get('user_device_id') == udk and start_time <= int(item.get('timestamp', 0)) <= end_time
            ]

            if not device_telemetry:
                continue

            # Calculate today's aggregate value
            daily_value = None
            if device_type in ["temperature_sensor", "gas_sensor", "light_sensor"]:
                metric_key  = "temp" if device_type == "temperature_sensor" else ("gas_level" if device_type == "gas_sensor" else "light_level")
                total       = sum(safe_float(item.get('payload', {}).get(metric_key, 0)) for item in device_telemetry if metric_key in item.get('payload', {}))
                daily_value = round(total / len(device_telemetry), 1) if device_telemetry else 0.0

            elif device_type == "ac_curtain":
                # Each record represents 1 minute at the current publish interval
                on_count    = sum(1 for item in device_telemetry if item.get('payload', {}).get('power_state') == "ON")
                daily_value = round(on_count / 60.0, 1) # convert minutes to hours

            if daily_value is not None:
                update_s3_chart(
                    f"processed-charts/{user_id}/{device_id}/{month_key}.json",
                    day_label,
                    {"label": day_label, "value": daily_value}
                )

        # 3. Process Alerts per User
        for user_id in user_ids:
            # In-memory filter for this specific user and time range
            user_alerts = [
                item for item in alerts_items 
                if item.get('user_id') == user_id and start_time <= int(item.get('timestamp', 0)) <= end_time
            ]
            
            daily_warnings  = sum(1 for a in user_alerts if str(a.get('severity', '')).upper() == 'WARNING')
            daily_criticals = sum(1 for a in user_alerts if str(a.get('severity', '')).upper() == 'CRITICAL')

            update_s3_chart(
                f"processed-alerts/{user_id}/{month_key}.json",
                day_label,
                {"label": day_label, "warnings": daily_warnings, "criticals": daily_criticals}
            )

    return {"status": "success", "processed_days": backfill_days}
