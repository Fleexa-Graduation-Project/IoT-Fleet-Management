variable "project_name" {
  description = "Project name prefix"
  type        = string
}

variable "environment" {
  description = "Deployment environment (e.g. dev, prod)"
  type        = string
  default     = "dev"
}

variable "tags" {
  description = "Tags to apply to resources"
  type        = map(string)
  default = {
    Project = "Fleexa"
  }
}

# Optional: If you want to allow overriding table names, keep these.
# Otherwise, you can remove them since main.tf is now using 
# "${var.project_name}-${var.environment}-..." for naming.
# If you keep them, you are currently IGNORING them in your main.tf implementation.