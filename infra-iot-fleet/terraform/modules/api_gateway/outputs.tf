output "api_endpoint" {
  description = "The endpoint URL for the API Gateway"
  value       = aws_apigatewayv2_stage.api.invoke_url
}

output "api_url" {
  value       = aws_apigatewayv2_stage.api.invoke_url
  description = "Base URL for Flutter app — e.g. https://xxx.execute-api.us-east-1.amazonaws.com/dev"
}
