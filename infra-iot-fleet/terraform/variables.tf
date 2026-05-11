variable "project_name" {
  type        = string
  description = "Project name"
  default     = "iot-fleet"
}
variable "aws_region" {
  type        = string
  description = "AWS region"
  default     = "us-east-1"
}

variable "cognito_user_pool_id" {
  type        = string
  description = "Cognito User Pool ID"
  default     = ""
}

variable "cognito_client_id" {
  type        = string
  description = "Cognito Client ID"
  default     = ""
}

variable "bucket_name" {
  type        = string
  description = "S3 Bucket Name"
  default     = ""
}
variable "environment" {
  type        = string
  description = "Environment (dev/prod)"
  default     = "dev"
}

variable "enable_iot_lambda_rules" {
  type        = bool
  description = "Enable IoT topic rules and Lambda invoke permissions for telemetry and alerts"
  default     = false
}

variable "telemetry_processor_lambda_name" {
  type        = string
  description = "Name of existing Lambda function that processes telemetry messages"
  default     = "processing_main_lambda"
}

variable "alert_processor_lambda_name" {
  type        = string
  description = "Name of existing Lambda function that processes alert messages"
  default     = "processing_main_lambda"
}
