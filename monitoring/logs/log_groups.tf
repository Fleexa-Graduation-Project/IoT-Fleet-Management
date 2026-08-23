# Fleexa monitoring stack — explicit CloudWatch log groups for the backend Lambdas.
#
# Standalone root module: not wired into infra-iot-fleet/terraform/main.tf.
# Lambda auto-creates a `/aws/lambda/<function-name>` log group on first invocation
# with NO retention set (logs kept forever). Declaring the group here lets us pin
# retention (see retention_policy.tf) and tag it, without touching the Lambda
# resources themselves. If the group already exists from a prior invocation,
# import it first with:
#   terraform import 'aws_cloudwatch_log_group.lambda["api-service"]' /aws/lambda/api-service

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

variable "aws_region" {
  type        = string
  description = "AWS region the monitored Lambda functions live in"
  default     = "us-east-1"
}

variable "lambda_function_names" {
  type        = list(string)
  description = "Names of the Fleexa backend Lambda functions to manage log groups for (see backend/README.md)"
  default = [
    "api-service",
    "iot-ingestion",
    "door-watch",
    "ac-timer-watch",
    "db-export",
  ]
}

resource "aws_cloudwatch_log_group" "lambda" {
  for_each = toset(var.lambda_function_names)

  name              = "/aws/lambda/${each.value}"
  retention_in_days = local.log_retention_days

  tags = {
    Project     = "Fleexa"
    Environment = var.environment
    Function    = each.value
    ManagedBy   = "monitoring/logs"
  }
}
