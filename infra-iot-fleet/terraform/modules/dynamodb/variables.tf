variable "telemetry_table_name" {
  description = "Name of the table storing device telemetry"
  type        = string
  default     = "device_telemetry"
}

variable "state_table_name" {
  description = "Name of the table storing device state/shadow data"
  type        = string
  default     = "device_state"
}

variable "alerts_table_name" {
  description = "Name of the table storing alert logs"
  type        = string
  default     = "alert_log"
}

variable "commands_table_name" {
  description = "Name of the table storing command logs"
  type        = string
  default     = "command_log"
}

variable "environment" {
  description = "Deployment environment (e.g. dev, prod)"
  type        = string
  default     = "dev"
}

variable "tags" {
  description = "Tags to apply to resources"
  type        = map(string)
  default     = {
    Project = "Fleexa"
  }
}