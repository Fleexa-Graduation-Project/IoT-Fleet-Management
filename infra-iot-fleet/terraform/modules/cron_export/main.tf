resource "aws_iam_role" "export_lambda_role" {
  name = "${var.project_name}-${var.environment}-export-lambda-role"
  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action    = "sts:AssumeRole"
        Effect    = "Allow"
        Principal = { Service = "lambda.amazonaws.com" }
      }
    ]
  })
}

resource "aws_iam_role_policy_attachment" "export_lambda_basic_execution" {
  role       = aws_iam_role.export_lambda_role.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSLambdaBasicExecutionRole"
}

resource "aws_iam_role_policy" "export_lambda_permissions" {
  name = "export_lambda_permissions"
  role = aws_iam_role.export_lambda_role.id
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "dynamodb:Scan"
        ]
        Resource = "*"
      },
      {
        Effect = "Allow"
        Action = [
          "s3:PutObject"
        ]
        Resource = "arn:aws:s3:::${var.bucket_name}/*"
      }
    ]
  })
}

resource "aws_lambda_function" "export_lambda" {
  function_name    = "${var.project_name}-${var.environment}-db-export"
  filename         = var.lambda_zip_path
  source_code_hash = var.source_code_hash
  role             = aws_iam_role.export_lambda_role.arn
  handler          = "bootstrap"
  runtime          = "provided.al2023"
  architectures    = ["arm64"]
  timeout          = 300 # 5 minutes

  environment {
    variables = {
      BUCKET_NAME      = var.bucket_name
      TABLES_TO_EXPORT = var.tables_to_export
    }
  }
}

resource "aws_cloudwatch_event_rule" "every_24_hours" {
  name                = "${var.project_name}-${var.environment}-daily-db-export"
  description         = "Trigger IoT daily db export every 24 hours"
  schedule_expression = "cron(0 0 * * ? *)"
}

resource "aws_cloudwatch_event_target" "export_target" {
  rule      = aws_cloudwatch_event_rule.every_24_hours.name
  target_id = "TriggerExportLambda"
  arn       = aws_lambda_function.export_lambda.arn
}

resource "aws_lambda_permission" "allow_eventbridge" {
  statement_id  = "AllowExecutionFromEventBridge"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.export_lambda.function_name
  principal     = "events.amazonaws.com"
  source_arn    = aws_cloudwatch_event_rule.every_24_hours.arn
}
