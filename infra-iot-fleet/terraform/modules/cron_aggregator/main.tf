resource "aws_iam_role" "aggregator_lambda_role" {
  name = "${var.project_name}-${var.environment}-aggregator-lambda-role"
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

resource "aws_iam_role_policy_attachment" "aggregator_lambda_basic_execution" {
  role       = aws_iam_role.aggregator_lambda_role.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSLambdaBasicExecutionRole"
}

resource "aws_iam_role_policy" "aggregator_lambda_permissions" {
  name = "aggregator_lambda_permissions"
  role = aws_iam_role.aggregator_lambda_role.id
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "dynamodb:Scan",
          "dynamodb:Query",
          "dynamodb:GetItem"
        ]
        Resource = "*"
      },
      {
        Effect = "Allow"
        Action = [
          "s3:PutObject",
          "s3:GetObject"
        ]
        Resource = "arn:aws:s3:::${var.bucket_name}/*"
      },
      {
        Effect = "Allow"
        Action = "s3:ListBucket"
        Resource = "arn:aws:s3:::${var.bucket_name}"
      }
    ]
  })
}

resource "aws_lambda_function" "aggregator_lambda" {
  function_name    = "${var.project_name}-${var.environment}-daily-aggregator"
  filename         = var.lambda_zip_path
  source_code_hash = var.source_code_hash
  role             = aws_iam_role.aggregator_lambda_role.arn
  handler          = "daily_aggregator.lambda_handler"
  runtime          = "python3.10"
  timeout          = 300

  environment {
    variables = {
      STATE_TABLE     = "${var.project_name}-${var.environment}-device-state"
      TELEMETRY_TABLE = "${var.project_name}-${var.environment}-telemetry"
      ALERTS_TABLE    = "${var.project_name}-${var.environment}-alerts"
      BUCKET_NAME     = var.bucket_name
    }
  }
}

resource "aws_cloudwatch_event_rule" "every_24_hours" {
  name                = "${var.project_name}-${var.environment}-daily-aggregation"
  description         = "Trigger IoT daily aggregation every 24 hours"
  schedule_expression = "rate(24 hours)"
}

resource "aws_cloudwatch_event_target" "aggregator_target" {
  rule      = aws_cloudwatch_event_rule.every_24_hours.name
  target_id = "TriggerAggregatorLambda"
  arn       = aws_lambda_function.aggregator_lambda.arn
}

resource "aws_lambda_permission" "allow_eventbridge" {
  statement_id  = "AllowExecutionFromEventBridge"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.aggregator_lambda.function_name
  principal     = "events.amazonaws.com"
  source_arn    = aws_cloudwatch_event_rule.every_24_hours.arn
}
