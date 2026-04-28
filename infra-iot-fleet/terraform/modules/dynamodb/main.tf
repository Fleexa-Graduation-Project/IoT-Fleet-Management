
resource "aws_dynamodb_table" "telemetry" {
  name         = "${var.project_name}-${var.environment}-telemetry"
  billing_mode = "PAY_PER_REQUEST"
  hash_key     = "device_id"
  range_key    = "timestamp"

  attribute {
    name = "device_id"
    type = "S"
  }

  attribute {
    name = "timestamp"
    type = "N"
  }

  ttl {
    attribute_name = "ttl"
    enabled        = true
  }
}

# ... Repeat similar naming pattern for other tables (state, alerts, commands)
resource "aws_dynamodb_table" "device_state" {
  name         = "${var.project_name}-${var.environment}-device-state"
  billing_mode = "PAY_PER_REQUEST"
  hash_key     = "device_id"
  attribute {
    name = "device_id"
    type = "S"
  }
}

resource "aws_dynamodb_table" "alerts" {
  name         = "${var.project_name}-${var.environment}-alerts"
  billing_mode = "PAY_PER_REQUEST"
  hash_key     = "alert_id"
  range_key    = "timestamp"
  attribute {
    name = "alert_id"
    type = "S"
  }
  attribute {
    name = "timestamp"
    type = "N"
  }
  ttl {
    attribute_name = "ttl"
    enabled        = true
  }
}

resource "aws_dynamodb_table" "commands" {
  name         = "${var.project_name}-${var.environment}-commands"
  billing_mode = "PAY_PER_REQUEST"
  hash_key     = "command_id"
  range_key    = "timestamp"
  attribute {
    name = "command_id"
    type = "S"
  }
  attribute {
    name = "timestamp"
    type = "N"
  }
}
