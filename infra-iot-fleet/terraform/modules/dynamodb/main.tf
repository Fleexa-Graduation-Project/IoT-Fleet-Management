
resource "aws_dynamodb_table" "telemetry" {
  name         = "${var.project_name}-${var.environment}-telemetry"
  billing_mode = "PAY_PER_REQUEST"
  hash_key     = "user_device_id"
  range_key    = "timestamp"

  attribute {
    name = "user_device_id"
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

resource "aws_dynamodb_table" "device_state" {
  name         = "${var.project_name}-${var.environment}-device-state"
  billing_mode = "PAY_PER_REQUEST"
  hash_key     = "user_id"
  range_key    = "device_id"

  attribute {
    name = "user_id"
    type = "S"
  }

  attribute {
    name = "device_id"
    type = "S"
  }

  attribute {
    name = "operational_state"
    type = "S"
  }

  global_secondary_index {
    name            = "OpenDoorsIndex"
    hash_key        = "operational_state"
    range_key       = "device_id"
    projection_type = "ALL"
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
  attribute {
    name = "user_id"
    type = "S"
  }
  attribute {
    name = "user_device_id"
    type = "S"
  }

  global_secondary_index {
    name            = "UserAlertsIndex"
    hash_key        = "user_id"
    range_key       = "timestamp"
    projection_type = "ALL"
  }

  global_secondary_index {
    name            = "DeviceAlertsIndex"
    hash_key        = "user_device_id"
    range_key       = "timestamp"
    projection_type = "ALL"
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

  ttl {
    attribute_name = "expires_at"
    enabled        = true
  }
}

resource "aws_dynamodb_table" "users" {
  name         = "${var.project_name}_Users"
  billing_mode = "PAY_PER_REQUEST"
  hash_key     = "user_id"
  attribute {
    name = "user_id"
    type = "S"
  }
}
