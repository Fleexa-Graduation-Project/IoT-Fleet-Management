terraform {
  backend "s3" {
    bucket         = "fleexa-s3-tfstate"
    key            = "iot-fleet/terraform.tfstate"
    region         = "us-east-1"
    encrypt        = true
    dynamodb_table = "fleexa-dynamoDB-tflock"
  }
}