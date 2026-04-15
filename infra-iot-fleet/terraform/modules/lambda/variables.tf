variable "project_name" {
  type        = string
  description = "Project name"
}

variable "environment" {
  type        = string
  description = "Environment name"
}

variable "function_name" {
  type        = string
  description = "Name of the Lambda function"
}

variable "handler" {
  type        = string
  description = "Lambda handler"
  default     = "bootstrap"
}

variable "runtime" {
  type        = string
  description = "Lambda runtime"
  default     = "provided.al2023"
}

variable "architecture" {
  type        = string
  description = "Lambda architecture (e.g. arm64 or x86_64)"
  default     = "arm64"
}

variable "lambda_zip_path" {
  type        = string
  description = "Path to the zip file containing the Lambda deployment package"
}

variable "custom_policy_json" {
  type        = string
  description = "JSON for custom IAM policy attached to the role"
  default     = "{}"
}

variable "environment_variables" {
  type        = map(string)
  description = "Environment variables for the Lambda function"
  default     = {}
}
