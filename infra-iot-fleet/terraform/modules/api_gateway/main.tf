resource "null_resource" "build_api_lambda" {
  triggers = { always_run = timestamp() }

  provisioner "local-exec" {
    command = <<-EOT
      set -e
      mkdir -p ${path.root}/../../backend/dist/api
      cd ${path.root}/../../backend
      GOOS=linux GOARCH=arm64 CGO_ENABLED=0 go build -tags lambda.norpc -o dist/api/bootstrap cmd/api-service/main.go
      chmod +x dist/api/bootstrap
    EOT
  }
}

data "archive_file" "api_lambda_zip" {
  type        = "zip"
  source_file = "${path.root}/../../backend/dist/api/bootstrap"
  output_path = "${path.root}/../../backend/dist/api/api-service.zip"
  depends_on  = [null_resource.build_api_lambda]
}

resource "aws_iam_role" "api_lambda_role" {
  name = "${var.project_name}-${var.environment}-api-lambda-role"
  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "lambda.amazonaws.com"
        }
      }
    ]
  })
}

resource "aws_iam_role_policy_attachment" "api_lambda_basic_execution" {
  role       = aws_iam_role.api_lambda_role.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSLambdaBasicExecutionRole"
}

resource "aws_lambda_function" "api_lambda" {
  function_name    = "${var.project_name}-${var.environment}-api-service"
  filename         = data.archive_file.api_lambda_zip.output_path
  source_code_hash = data.archive_file.api_lambda_zip.output_base64sha256
  role             = aws_iam_role.api_lambda_role.arn
  handler          = "bootstrap"
  runtime          = "provided.al2023"
  architectures    = ["arm64"]

  environment {
    variables = {
      ENVIRONMENT          = var.environment
      STATE_TABLE          = "${var.project_name}-${var.environment}-device-state"
      TELEMETRY_TABLE      = "${var.project_name}-${var.environment}-telemetry"
      ALERTS_TABLE         = "${var.project_name}-${var.environment}-alerts"
      COMMANDS_TABLE       = "${var.project_name}-${var.environment}-commands"
      COGNITO_USER_POOL_ID = var.cognito_user_pool_id
      COGNITO_CLIENT_ID    = var.cognito_client_id
      BUCKET_NAME          = var.bucket_name
    }
  }

  depends_on = [null_resource.build_api_lambda]
}

resource "aws_apigatewayv2_api" "api" {
  name          = "${var.project_name}-${var.environment}-api"
  protocol_type = "HTTP"
}

resource "aws_apigatewayv2_stage" "api" {
  api_id      = aws_apigatewayv2_api.api.id
  name        = "$default"
  auto_deploy = true
}

resource "aws_apigatewayv2_integration" "lambda_proxy" {
  api_id                 = aws_apigatewayv2_api.api.id
  integration_type       = "AWS_PROXY"
  integration_method     = "POST"
  integration_uri        = aws_lambda_function.api_lambda.invoke_arn
  payload_format_version = "2.0"
}

resource "aws_apigatewayv2_route" "proxy" {
  api_id    = aws_apigatewayv2_api.api.id
  route_key = "ANY /{proxy+}"
  target    = "integrations/${aws_apigatewayv2_integration.lambda_proxy.id}"
}

resource "aws_apigatewayv2_route" "proxy_root" {
  api_id    = aws_apigatewayv2_api.api.id
  route_key = "ANY /"
  target    = "integrations/${aws_apigatewayv2_integration.lambda_proxy.id}"
}

resource "aws_lambda_permission" "apigw_lambda" {
  statement_id  = "AllowExecutionFromAPIGateway"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.api_lambda.function_name
  principal     = "apigateway.amazonaws.com"
  source_arn    = "${aws_apigatewayv2_api.api.execution_arn}/*/*"
}

resource "aws_iam_role_policy" "api_lambda_permissions" {
  name = "api_lambda_permissions"
  role = aws_iam_role.api_lambda_role.id
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "dynamodb:PutItem",
          "dynamodb:GetItem",
          "dynamodb:UpdateItem",
          "dynamodb:Query",
          "dynamodb:Scan",
          "dynamodb:DeleteItem"
        ]
        Resource = "*"
      },
      {
        Effect = "Allow"
        Action = [
          "iot:Publish",
          "iot:Connect"
        ]
        Resource = "*"
      }
    ]
  })
}
