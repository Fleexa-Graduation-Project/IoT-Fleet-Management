import boto3
from botocore.exceptions import ClientError

# Table names must match what Terraform created
DYNAMODB_TABLES = [
    'iot-fleet-dev-telemetry',
    'iot-fleet-dev-device-state',
    'iot-fleet-dev-alerts',
    'iot-fleet-dev-commands'
]

IOT_THING_NAME = 'iot-fleet-device'  # Or whatever your thing is named

def check_dynamodb():
    """Check if all DynamoDB tables exist"""
    dynamodb = boto3.client('dynamodb', region_name='us-east-1')
    all_ok = True
    
    for table_name in DYNAMODB_TABLES:
        try:
            response = dynamodb.describe_table(TableName=table_name)
            print(f"   ✅ Table '{table_name}' is ACTIVE")
        except ClientError as e:
            print(f"   ❌ Table '{table_name}' NOT FOUND. Error: {e}")
            all_ok = False
    
    return all_ok

def check_iot_core():
    """Check if IoT Core endpoint and thing exist"""
    iot = boto3.client('iot', region_name='us-east-1')
    
    try:
        endpoint = iot.describe_endpoint(endpointType='iot:Data-ATS')
        print(f"   ✅ IoT Endpoint found: {endpoint['endpointAddress']}")
        
        # Fixed: lowercase 'thingName'
        thing = iot.describe_thing(thingName=IOT_THING_NAME)
        print(f"   ✅ IoT Thing '{IOT_THING_NAME}' exists")
        return True
    except ClientError as e:
        print(f"   ❌ IoT Core check failed: {e}")
        return False

def main():
    print("=== Fleexa Infrastructure Smoke Test ===\n")
    
    print("☁️  Checking DynamoDB Tables...")
    db_ok = check_dynamodb()
    
    print("\n📡 Checking AWS IoT Core...")
    iot_ok = check_iot_core()
    
    if db_ok and iot_ok:
        print("\n✅ All checks passed!")
    else:
        print("\n❌ Some checks failed. Review errors above.")

if __name__ == "__main__":
    main()
