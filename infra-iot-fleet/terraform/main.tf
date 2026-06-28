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
  cognito_user_pool_id = module.cognito.user_pool_id
  cognito_client_id    = module.cognito.client_id
  bucket_name          = module.s3.bucket_id
  iot_endpoint         = var.iot_endpoint
  users_table_name     = var.users_table_name
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

module "cron_aggregator" {
  source           = "./modules/cron_aggregator"
  project_name     = var.project_name
  environment      = var.environment
  bucket_name      = module.s3.bucket_id
  lambda_zip_path  = data.archive_file.aggregator_lambda_zip.output_path
  source_code_hash = data.archive_file.aggregator_lambda_zip.output_base64sha256
}

module "door_watch_lambda" {
  source = "./modules/lambda"

  project_name = var.project_name
  environment  = var.environment

  function_name = "door-watch-service"

  lambda_zip_path  = data.archive_file.door_watch_lambda_zip.output_path
  source_code_hash = data.archive_file.door_watch_lambda_zip.output_base64sha256

  custom_policy_json = data.aws_iam_policy_document.iot_ingestion_policy.json

  environment_variables = {
    ENVIRONMENT          = var.environment
    TELEMETRY_TABLE      = "${var.project_name}-${var.environment}-telemetry"
    ALERTS_TABLE         = "${var.project_name}-${var.environment}-alerts"
    STATE_TABLE          = "${var.project_name}-${var.environment}-device-state"
    COMMANDS_TABLE       = "${var.project_name}-${var.environment}-commands"
    USERS_TABLE          = "iot-fleet_Users"
    COGNITO_USER_POOL_ID = module.cognito.user_pool_id
    COGNITO_CLIENT_ID    = module.cognito.client_id
    FIREBASE_CREDENTIALS = "./firebase-adminsdk.json"
  }

  depends_on = [data.archive_file.door_watch_lambda_zip]
}

resource "aws_cloudwatch_event_rule" "every_minute" {
  name                = "${var.project_name}-${var.environment}-every-minute"
  description         = "Trigger door-watch lambda every minute"
  schedule_expression = "rate(1 minute)"
}

resource "aws_cloudwatch_event_target" "door_watch_target" {
  rule      = aws_cloudwatch_event_rule.every_minute.name
  target_id = "TriggerDoorWatchLambda"
  arn       = module.door_watch_lambda.function_arn
}

resource "aws_lambda_permission" "allow_eventbridge_door_watch" {
  statement_id  = "AllowExecutionFromEventBridgeDoorWatch"
  action        = "lambda:InvokeFunction"
  function_name = module.door_watch_lambda.function_name
  principal     = "events.amazonaws.com"
  source_arn    = aws_cloudwatch_event_rule.every_minute.arn
}

