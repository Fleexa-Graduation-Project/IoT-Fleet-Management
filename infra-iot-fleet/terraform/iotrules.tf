# ─── IoT Rule: Telemetry → Lambda ───────────────────────────────────────────
resource "aws_iot_topic_rule" "telemetry_processor" {
  name        = "${replace(var.project_name, "-", "_")}_telemetry_processor"
  description = "Route telemetry messages to Lambda for DynamoDB storage"
  enabled     = true
  sql         = "SELECT * FROM 'devices/+/telemetry'"
  sql_version = "2016-03-23"

  lambda {
    function_arn = aws_lambda_function.telemetry_processor.arn
  }
}

# ─── IoT Rule: Alerts → Lambda ───────────────────────────────────────────────
resource "aws_iot_topic_rule" "alert_processor" {
  name        = "${replace(var.project_name, "-", "_")}_alert_processor"
  description = "Route alert messages to Lambda for alert log storage"
  enabled     = true
  sql         = "SELECT * FROM 'devices/+/alerts'"
  sql_version = "2016-03-23"

  lambda {
    function_arn = aws_lambda_function.alert_processor.arn
  }
}

# ─── Lambda Invoke Permissions ───────────────────────────────────────────────
resource "aws_lambda_permission" "iot_invoke_telemetry" {
  statement_id  = "AllowIoTInvokeTelemetry"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.telemetry_processor.function_name
  principal     = "iot.amazonaws.com"
  source_arn    = aws_iot_topic_rule.telemetry_processor.arn
}

resource "aws_lambda_permission" "iot_invoke_alert" {
  statement_id  = "AllowIoTInvokeAlert"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.alert_processor.function_name
  principal     = "iot.amazonaws.com"
  source_arn    = aws_iot_topic_rule.alert_processor.arn
}
