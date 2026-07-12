variable "project_name" {
  description = "Project name"
  type        = string
}

variable "environment" {
  description = "Environment name"
  type        = string
}

variable "aws_region" {
  description = "AWS region"
  type        = string
}

variable "cognito_user_pool_id" {
  description = "Cognito User Pool ID"
  type        = string
}

variable "cognito_client_id" {
  description = "Cognito Client ID"
  type        = string
}

variable "bucket_name" {
  description = "S3 Bucket Name"
  type        = string
}

variable "iot_endpoint" {
  description = "AWS IoT Core ATS endpoint (e.g. xxxxxx-ats.iot.us-east-1.amazonaws.com)"
  type        = string
}

variable "users_table_name" {
  description = "DynamoDB Users table name"
  type        = string
  default     = "iot-fleet_Users"
}

variable "fleet_lat" {
  description = "Fleet location latitude for weather API"
  type        = string
  default     = ""
}

variable "fleet_lon" {
  description = "Fleet location longitude for weather API"
  type        = string
  default     = ""
}
