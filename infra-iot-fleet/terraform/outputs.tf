output "api_endpoint" {
  description = "The endpoint URL for the API Gateway"
  value       = module.api_gateway.api_endpoint
}

output "api_url" {
  description = "Base URL for Flutter app — e.g. https://xxx.execute-api.us-east-1.amazonaws.com/dev"
  value       = module.api_gateway.api_url
}
