import boto3
import sys
from botocore.exceptions import ClientError

# Configuration
REGION = 'us-east-1'
TABLES_TO_CHECK = ['device_telemetry', 'device_state', 'alert_log', 'command_log']
IOT_THING_NAME = 'temp-sensor-01'

def check_dynamodb():
    print("☁️  Checking DynamoDB Tables...")
    dynamodb = boto3.client('dynamodb', region_name=REGION)
    all_exist = True
    
    for table_name in TABLES_TO_CHECK:
        try:
            response = dynamodb.describe_table(TableName=table_name)
            status = response['Table']['TableStatus']
            print(f"   ✅ Table '{table_name}' exists (Status: {status})")
        except ClientError as e:
            print(f"   ❌ Table '{table_name}' NOT FOUND. Error: {e}")
            all_exist = False
            
    return all_exist

def check_iot_core():
    print("\n📡 Checking AWS IoT Core...")
    iot = boto3.client('iot', region_name=REGION)
    
    try:
        # Check Endpoint
        endpoint = iot.describe_endpoint(endpointType='iot:Data-ATS')
        print(f"   ✅ IoT Endpoint found: {endpoint['endpointAddress']}")
        
        # Check Thing
        thing = iot.describe_thing(ThingName=IOT_THING_NAME)
        print(f"   ✅ IoT Thing '{IOT_THING_NAME}' exists (ID: {thing['thingId']})")
        return True
    except ClientError as e:
        print(f"   ❌ IoT Check Failed. Error: {e}")
        return False

def main():
    print("=== Fleexa Infrastructure Smoke Test ===\n")
    
    db_ok = check_dynamodb()
    iot_ok = check_iot_core()
    
    print("\n" + "="*40)
    if db_ok and iot_ok:
        print("✅ SMOKE TEST PASSED: Infrastructure is ready.")
        sys.exit(0)
    else:
        print("❌ SMOKE TEST FAILED: Issues detected.")
        sys.exit(1)

if __name__ == "__main__":
    main()