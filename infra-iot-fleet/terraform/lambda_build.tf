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
    # In a real environment, restrict to the specific tables from the dynamodb module
    resources = [
      "*"
    ]
  }
}

module "iot_ingestion_lambda" {
  source = "./modules/lambda"

  project_name = var.project_name
  environment  = var.environment

  # explicitly define lambda name for AWS as requested
  function_name = "processing_main_lambda"

  lambda_zip_path  = data.archive_file.lambda_zip.output_path
  source_code_hash = data.archive_file.lambda_zip.output_base64sha256

  custom_policy_json = data.aws_iam_policy_document.iot_ingestion_policy.json

  environment_variables = {

    ENVIRONMENT                 = var.environment
    DYNAMODB_TABLE_NAME         = "${var.project_name}-${var.environment}-telemetry"
    DYNAMODB_ALERTS_TABLE       = "${var.project_name}-${var.environment}-alerts"
    DYNAMODB_DEVICE_STATE_TABLE = "${var.project_name}-${var.environment}-device-state"
    DYNAMODB_COMMANDS_TABLE     = "${var.project_name}-${var.environment}-commands"
  }

  depends_on = [data.archive_file.lambda_zip]

}
