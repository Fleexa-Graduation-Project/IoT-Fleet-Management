resource "aws_dynamodb_table" "telemetry" {
  name           = var.telemetry_table_name  # Uses variable
  billing_mode   = "PAY_PER_REQUEST"
  hash_key       = "device_id"
  range_key      = "timestamp"

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

  tags = merge(var.tags, { Name = var.telemetry_table_name })
}

resource "aws_dynamodb_table" "device_state" {
  name           = var.state_table_name  # Uses variable
  billing_mode   = "PAY_PER_REQUEST"
  hash_key       = "device_id"

  attribute {
    name = "device_id"
    type = "S"
  }

  tags = merge(var.tags, { Name = var.state_table_name })
}

resource "aws_dynamodb_table" "alerts" {
  name           = var.alerts_table_name  # Uses variable
  billing_mode   = "PAY_PER_REQUEST"
  hash_key       = "alert_id"
  range_key      = "timestamp"

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

  tags = merge(var.tags, { Name = var.alerts_table_name })
}

resource "aws_dynamodb_table" "commands" {
  name           = var.commands_table_name  # Uses variable
  billing_mode   = "PAY_PER_REQUEST"
  hash_key       = "command_id"
  range_key      = "timestamp"

  attribute {
    name = "command_id"
    type = "S"
  }

  attribute {
    name = "timestamp"
    type = "N"
  }

  tags = merge(var.tags, { Name = var.commands_table_name })
}