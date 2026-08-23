# Fleexa monitoring stack — per-environment CloudWatch log retention.
#
# `environment` and `log_retention_days` are declared here and consumed by
# log_groups.tf in this same root module.

variable "environment" {
  type        = string
  description = "Deployment environment (dev, staging, prod)"
  default     = "dev"

  validation {
    condition     = contains(["dev", "staging", "prod"], var.environment)
    error_message = "environment must be one of: dev, staging, prod."
  }
}

variable "log_retention_days_by_environment" {
  type        = map(number)
  description = "CloudWatch log retention (days) keyed by environment"
  default = {
    dev     = 14
    staging = 14
    prod    = 30
  }
}

# Optional escape hatch: override the computed retention outright instead of
# going through log_retention_days_by_environment.
variable "log_retention_days_override" {
  type        = number
  description = "If set, overrides the per-environment retention lookup for every managed log group"
  default     = null
}

locals {
  log_retention_days = coalesce(
    var.log_retention_days_override,
    lookup(var.log_retention_days_by_environment, var.environment, 14)
  )
}
