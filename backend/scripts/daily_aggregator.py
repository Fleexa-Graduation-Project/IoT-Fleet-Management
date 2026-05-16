import boto3
import json
import os
from datetime import datetime, timedelta
from decimal import Decimal

# Initialize AWS Clients
s3 = boto3.client('s3')
dynamodb = boto3.resource('dynamodb')

# Environment Variables configured
STATE_TABLE     = os.environ.get('STATE_TABLE',     'Fleexa_Devices')
TELEMETRY_TABLE = os.environ.get('TELEMETRY_TABLE', 'Fleexa_Telemetry')
ALERTS_TABLE    = os.environ.get('ALERTS_TABLE',    'Fleexa_Alerts')
BUCKET_NAME     = os.environ.get('BUCKET_NAME',     'fleexa-data-lake')

def decimal_default(obj):
    if isinstance(obj, Decimal):
        return float(obj)
    raise TypeError

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

def lambda_handler(_event, _context):
    print("Starting Nightly ETL Job...")

    now       = datetime.now()
    yesterday = now - timedelta(days=1)
    month_key = yesterday.strftime("%Y-%m") # e.g., "2026-04"
    day_label = yesterday.strftime("%b %d") # e.g., "Apr 28"

    start_time = int(yesterday.replace(hour=0,  minute=0,  second=0).timestamp())
    end_time   = int(yesterday.replace(hour=23, minute=59, second=59).timestamp())

    # Get all active devices from the State Store
    state_table      = dynamodb.Table(STATE_TABLE)
    telemetry_table = dynamodb.Table(TELEMETRY_TABLE)
    alerts_table    = dynamodb.Table(ALERTS_TABLE)

    #scan devices to build composite keys
    devices_response = state_table.scan(
        ProjectionExpression="user_id, device_id, #type",
        ExpressionAttributeNames={"#type": "type"}
    )

    user_ids = set()

    for device in devices_response.get('Items', []):
        user_id     = device['user_id']
        device_id   = device['device_id']
        device_type = device['type']
        user_ids.add(user_id)

        # Query today's raw telemetry
        udk      = f"{user_id}#{device_id}"
        response = telemetry_table.query(
            KeyConditionExpression="user_device_id = :udk AND #ts BETWEEN :start AND :end",
            ExpressionAttributeNames={"#ts": "timestamp"},
            ExpressionAttributeValues={":udk": udk, ":start": start_time, ":end": end_time}
        )

        items = response.get('Items', [])
        if not items:
            continue

        # Calculate today's aggregate value
        daily_value = None
        if device_type in ["temp-sensor", "gas-sensor", "light-sensor"]:
            metric_key  = "temp" if device_type == "temp-sensor" else ("gas_level" if device_type == "gas-sensor" else "light_level")
            total       = sum(float(item['payload'].get(metric_key, 0)) for item in items if metric_key in item['payload'])
            daily_value = round(total / len(items), 1) if items else 0.0

        elif device_type == "ac-actuator":
            # Each record represents 1 minute at the current publish interval
            on_count    = sum(1 for item in items if item['payload'].get('power_state') == "ON")
            daily_value = round(on_count / 60.0, 1) # convert minutes to hours

        if daily_value is not None:
            update_s3_chart(
                f"processed-charts/{user_id}/{device_id}/{month_key}.json",
                day_label,
                {"label": day_label, "value": daily_value}
            )

    #alert aggregation for the Alerts & Warnings chart
    for user_id in user_ids:
        alerts_response = alerts_table.query(
            IndexName="UserAlertsIndex",
            KeyConditionExpression="user_id = :uid AND #ts BETWEEN :start AND :end",
            ExpressionAttributeNames={"#ts": "timestamp"},
            ExpressionAttributeValues={":uid": user_id, ":start": start_time, ":end": end_time}
        )

        alert_items     = alerts_response.get('Items', [])
        daily_warnings  = sum(1 for a in alert_items if str(a.get('severity', '')).upper() == 'WARNING')
        daily_criticals = sum(1 for a in alert_items if str(a.get('severity', '')).upper() == 'CRITICAL')

        update_s3_chart(
            f"processed-alerts/{user_id}/{month_key}.json",
            day_label,
            {"label": day_label, "warnings": daily_warnings, "criticals": daily_criticals}
        )

    return {"status": "success"}
