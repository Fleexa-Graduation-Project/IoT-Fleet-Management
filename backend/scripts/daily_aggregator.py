import boto3
import json
import os
from datetime import datetime, timedelta
from decimal import Decimal

# Initialize AWS Clients
s3 = boto3.client('s3')
dynamodb = boto3.resource('dynamodb')

# Environment Variables configured by Marwan
STATE_TABLE = os.environ.get('STATE_TABLE', 'Fleexa_DeviceStates')
TELEMETRY_TABLE = os.environ.get('TELEMETRY_TABLE', 'Fleexa_Telemetry')
BUCKET_NAME = os.environ.get('BUCKET_NAME', 'fleexa-data-lake')

def decimal_default(obj):
    if isinstance(obj, Decimal):
        return float(obj)
    raise TypeError

def lambda_handler(event, context):
    print("Starting Nightly ETL Job...")
    
    # 1. Setup Time boundaries (Midnight to 11:59 PM today)
    now = datetime.now()
    yesterday = now - timedelta(days=1)
    month_key = yesterday.strftime("%Y-%m") # e.g., "2026-04"
    day_label = yesterday.strftime("%b %d") # e.g., "Apr 28"
    
    start_time = int(yesterday.replace(hour=0, minute=0, second=0).timestamp())
    end_time = int(yesterday.replace(hour=23, minute=59, second=59).timestamp())

    # 2. Get all active devices from the State Store
    state_table = dynamodb.Table(STATE_TABLE)
    devices_response = state_table.scan(ProjectionExpression="device_id, #type", ExpressionAttributeNames={"#type": "type"})
    
    for device in devices_response.get('Items', []):
        device_id = device['device_id']
        device_type = device['type']
        
        # 3. Query today's raw telemetry (All 288 points)
        telemetry_table = dynamodb.Table(TELEMETRY_TABLE)
        response = telemetry_table.query(
            KeyConditionExpression="device_id = :did AND #ts BETWEEN :start AND :end",
            ExpressionAttributeNames={"#ts": "timestamp"},
            ExpressionAttributeValues={
                ":did": device_id,
                ":start": start_time,
                ":end": end_time
            }
        )
        
        items = response.get('Items', [])
        if not items:
            continue # No data today, skip
            
        # 4. Transform: Calculate Today's Average
        daily_value = None
        if device_type in ["temp-sensor", "gas-sensor", "light-sensor"]:
            metric_key = "temp" if device_type == "temp-sensor" else ("gas_level" if device_type == "gas-sensor" else "light_level")
            total = sum(float(item['payload'].get(metric_key, 0)) for item in items if metric_key in item['payload'])
            daily_value = round(total / len(items), 1) if items else 0.0
            
        elif device_type == "ac-actuator":
            # Count how many records had "power_state: ON". Assuming 5-min intervals.
            on_count = sum(1 for item in items if item['payload'].get('power_state') == "ON")
            daily_value = round((on_count * 1) / 60.0, 1) # convert to hours
        
        if daily_value is not None:
            # 5. Load: Save today's average to S3
            s3_key = f"processed-charts/{device_id}/{month_key}.json"
            chart_data = []
            
            try:
                s3_resp = s3.get_object(Bucket=BUCKET_NAME, Key=s3_key)
                chart_data = json.loads(s3_resp['Body'].read().decode('utf-8'))
            except s3.exceptions.NoSuchKey:
                pass # First day of the month!
                
            # Overwrite today if it ran twice, otherwise append
            existing = next((x for x in chart_data if x["label"] == day_label), None)
            if existing:
                existing["value"] = daily_value
            else:
                chart_data.append({"label": day_label, "value": daily_value})
                
            s3.put_object(
                Bucket=BUCKET_NAME,
                Key=s3_key,
                Body=json.dumps(chart_data, default=decimal_default),
                ContentType='application/json'
            )

    return {"status": "success"}