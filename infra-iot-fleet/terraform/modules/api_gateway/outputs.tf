output "api_endpoint" {
  description = "The endpoint URL for the API Gateway"
  value       = aws_api_gateway_stage.api.invoke_url
}
