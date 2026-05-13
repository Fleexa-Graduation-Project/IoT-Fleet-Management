module "iot_core" {
  source       = "./modules/iot_core"
  project_name = var.project_name
  aws_region   = var.aws_region
}

module "dynamodb" {
  source       = "./modules/dynamodb"
  project_name = var.project_name
  environment  = var.environment
}
module "api_gateway" {
  source               = "./modules/api_gateway"
  project_name         = var.project_name
  environment          = var.environment
  aws_region           = var.aws_region
  cognito_user_pool_id = var.cognito_user_pool_id
  cognito_client_id    = var.cognito_client_id
  bucket_name          = var.bucket_name
}

module "s3" {
  source      = "./modules/s3"
  bucket_name = "${var.project_name}-data-lake-${var.environment}"
}

module "cognito" {
  source         = "./modules/cognito"
  user_pool_name = "${var.project_name}-users-${var.environment}"
  client_name    = "${var.project_name}-mobile-${var.environment}"
}
