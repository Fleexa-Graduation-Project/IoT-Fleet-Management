# Fleexa monitoring stack — CloudWatch metric alarms.
#
# Standalone root module: watches the 5 backend Lambda functions and 5 DynamoDB
# tables described in backend/README.md. Intentionally NOT wired into
# infra-iot-fleet/terraform/main.tf — apply this directory on its own.

terraform {
  required_version = ">= 1.0"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 6.0"
    }
  }
}

provider "aws" {
  region = var.aws_region
}

# ─── Variables ────────────────────────────────────────────────────────────

variable "project_name" {
  type        = string
  description = "Project name, used as a prefix for alarm names"
  default     = "fleexa"
}

variable "environment" {
  type        = string
  description = "Deployment environment (dev, staging, prod)"
  default     = "dev"
}

variable "aws_region" {
  type        = string
  description = "AWS region the monitored resources live in"
  default     = "us-east-1"
}

variable "lambda_function_names" {
  type        = list(string)
  description = "Names of the Fleexa backend Lambda functions to monitor (see backend/README.md)"
  default = [
    "api-service",
    "iot-ingestion",
    "door-watch",
    "ac-timer-watch",
    "db-export",
  ]
}

variable "dynamodb_table_names" {
  type        = list(string)
  description = "Names of the Fleexa DynamoDB tables to monitor (see backend/README.md)"
  default = [
    "Fleexa_Devices",
    "Fleexa_Telemetry",
    "Fleexa_Alerts",
    "Fleexa_Commands",
    "Fleexa_Users",
  ]
}

variable "lambda_error_threshold" {
  type        = number
  description = "Number of Lambda errors within a 5 minute window that triggers the alarm"
  default     = 5
}

variable "lambda_duration_threshold_ms" {
  type        = number
  description = "Lambda p99 duration (ms) that triggers the latency alarm"
  default     = 3000
}

variable "dynamodb_throttle_threshold" {
  type        = number
  description = "Number of throttled DynamoDB requests within a 5 minute window that triggers the alarm"
  default     = 1
}

variable "alarm_actions" {
  type        = list(string)
  description = "ARNs (typically an SNS topic) to notify when an alarm transitions to ALARM"
  default     = []
}

variable "ok_actions" {
  type        = list(string)
  description = "ARNs to notify when an alarm transitions back to OK"
  default     = []
}

locals {
  tags = {
    Project     = "Fleexa"
    Environment = var.environment
    ManagedBy   = "monitoring/cloudwatch"
  }
}

# ─── Lambda: error rate ────────────────────────────────────────────────────

resource "aws_cloudwatch_metric_alarm" "lambda_errors" {
  for_each = toset(var.lambda_function_names)

  alarm_name        = "${var.project_name}-${var.environment}-${each.value}-errors"
  alarm_description = "Triggers when the ${each.value} Lambda raises more than ${var.lambda_error_threshold} errors in a 5 minute window"

  namespace   = "AWS/Lambda"
  metric_name = "Errors"
  dimensions = {
    FunctionName = each.value
  }

  statistic           = "Sum"
  period              = 300
  evaluation_periods  = 1
  comparison_operator = "GreaterThanThreshold"
  threshold           = var.lambda_error_threshold
  treat_missing_data  = "notBreaching"

  alarm_actions = var.alarm_actions
  ok_actions    = var.ok_actions

  tags = local.tags
}

# ─── Lambda: duration / latency ────────────────────────────────────────────

resource "aws_cloudwatch_metric_alarm" "lambda_duration" {
  for_each = toset(var.lambda_function_names)

  alarm_name        = "${var.project_name}-${var.environment}-${each.value}-high-latency"
  alarm_description = "Triggers when the ${each.value} Lambda's p99 duration exceeds ${var.lambda_duration_threshold_ms}ms for 3 consecutive periods"

  namespace   = "AWS/Lambda"
  metric_name = "Duration"
  dimensions = {
    FunctionName = each.value
  }

  extended_statistic  = "p99"
  period              = 300
  evaluation_periods  = 3
  comparison_operator = "GreaterThanThreshold"
  threshold           = var.lambda_duration_threshold_ms
  treat_missing_data  = "notBreaching"

  alarm_actions = var.alarm_actions
  ok_actions    = var.ok_actions

  tags = local.tags
}

# ─── DynamoDB: read throttling ──────────────────────────────────────────────

resource "aws_cloudwatch_metric_alarm" "dynamodb_read_throttle" {
  for_each = toset(var.dynamodb_table_names)

  alarm_name        = "${var.project_name}-${var.environment}-${each.value}-read-throttle"
  alarm_description = "Triggers when ${each.value} rejects read requests due to throttling"

  namespace   = "AWS/DynamoDB"
  metric_name = "ReadThrottleEvents"
  dimensions = {
    TableName = each.value
  }

  statistic           = "Sum"
  period              = 300
  evaluation_periods  = 1
  comparison_operator = "GreaterThanOrEqualToThreshold"
  threshold           = var.dynamodb_throttle_threshold
  treat_missing_data  = "notBreaching"

  alarm_actions = var.alarm_actions
  ok_actions    = var.ok_actions

  tags = local.tags
}

# ─── DynamoDB: write throttling ─────────────────────────────────────────────

resource "aws_cloudwatch_metric_alarm" "dynamodb_write_throttle" {
  for_each = toset(var.dynamodb_table_names)

  alarm_name        = "${var.project_name}-${var.environment}-${each.value}-write-throttle"
  alarm_description = "Triggers when ${each.value} rejects write requests due to throttling"

  namespace   = "AWS/DynamoDB"
  metric_name = "WriteThrottleEvents"
  dimensions = {
    TableName = each.value
  }

  statistic           = "Sum"
  period              = 300
  evaluation_periods  = 1
  comparison_operator = "GreaterThanOrEqualToThreshold"
  threshold           = var.dynamodb_throttle_threshold
  treat_missing_data  = "notBreaching"

  alarm_actions = var.alarm_actions
  ok_actions    = var.ok_actions

  tags = local.tags
}
