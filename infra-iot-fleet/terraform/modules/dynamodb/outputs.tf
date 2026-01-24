# Export Table Names (for Lambda Environment Variables)
output "telemetry_table_name" {
  value = aws_dynamodb_table.telemetry.name
}

output "state_table_name" {
  value = aws_dynamodb_table.device_state.name
}

output "alerts_table_name" {
  value = aws_dynamodb_table.alerts.name
}

output "commands_table_name" {
  value = aws_dynamodb_table.commands.name
}

# Export Table ARNs (for IAM Policies)
output "telemetry_table_arn" {
  value = aws_dynamodb_table.telemetry.arn
}

output "state_table_arn" {
  value = aws_dynamodb_table.device_state.arn
}

output "alerts_table_arn" {
  value = aws_dynamodb_table.alerts.arn
}

output "commands_table_arn" {
  value = aws_dynamodb_table.commands.arn
}