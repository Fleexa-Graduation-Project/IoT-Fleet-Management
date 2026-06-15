resource "null_resource" "build_lambda" {
  triggers = {
    always_run = timestamp()
  }

  provisioner "local-exec" {
    command = <<-EOT
      set -e
      mkdir -p ${path.module}/../../backend/dist/ingestion
      cd ${path.module}/../../backend
      GOOS=linux GOARCH=arm64 go build -tags lambda.norpc -o dist/ingestion/bootstrap cmd/iot-ingestion/main.go
      chmod +x dist/ingestion/bootstrap
    EOT
  }
}

data "archive_file" "lambda_zip" {
  type        = "zip"
  source_file = "${path.module}/../../backend/dist/ingestion/bootstrap"
  output_path = "${path.module}/../../backend/dist/ingestion/iot-ingestion.zip"

  depends_on = [null_resource.build_lambda]
}

data "aws_iam_policy_document" "iot_ingestion_policy" {
  statement {
    effect = "Allow"
    actions = [
      "dynamodb:PutItem",
      "dynamodb:GetItem",
      "dynamodb:UpdateItem",
      "dynamodb:Query",
      "dynamodb:Scan"
    ]
    resources = ["*"]
  }
}

module "iot_ingestion_lambda" {
  source = "./modules/lambda"

  project_name = var.project_name
  environment  = var.environment

  function_name = "processing_main_lambda"

  lambda_zip_path  = data.archive_file.lambda_zip.output_path
  source_code_hash = data.archive_file.lambda_zip.output_base64sha256

  custom_policy_json = data.aws_iam_policy_document.iot_ingestion_policy.json

  # Env var names must match exactly what the Go code reads via os.Getenv()
  environment_variables = {
    ENVIRONMENT          = var.environment
    TELEMETRY_TABLE      = "${var.project_name}-${var.environment}-telemetry"
    ALERTS_TABLE         = "${var.project_name}-${var.environment}-alerts"
    STATE_TABLE          = "${var.project_name}-${var.environment}-device-state"
    COMMANDS_TABLE       = "${var.project_name}-${var.environment}-commands"
    USERS_TABLE          = "iot-fleet_Users"
    COGNITO_USER_POOL_ID = var.cognito_user_pool_id
    COGNITO_CLIENT_ID    = var.cognito_client_id
    FIREBASE_CREDENTIALS = "./firebase-adminsdk.json"
  }

  depends_on = [data.archive_file.lambda_zip]
}
