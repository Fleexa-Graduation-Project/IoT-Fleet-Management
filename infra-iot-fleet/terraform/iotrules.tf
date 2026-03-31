data "aws_lambda_function" "telemetry_processor" {
  count         = var.enable_iot_lambda_rules ? 1 : 0
  function_name = var.telemetry_processor_lambda_name
}

data "aws_lambda_function" "alert_processor" {
  count         = var.enable_iot_lambda_rules ? 1 : 0
  function_name = var.alert_processor_lambda_name
}

# ─── IoT Rule: Telemetry → Lambda ───────────────────────────────────────────
resource "aws_iot_topic_rule" "telemetry_processor" {
  count       = var.enable_iot_lambda_rules ? 1 : 0
  name        = "${replace(var.project_name, "-", "_")}_telemetry_processor"
  description = "Route telemetry messages to Lambda for DynamoDB storage"
  enabled     = true
  sql         = "SELECT * FROM 'devices/+/telemetry'"
  sql_version = "2016-03-23"

  lambda {
    function_arn = data.aws_lambda_function.telemetry_processor[0].arn
  }
}

# ─── IoT Rule: Alerts → Lambda ───────────────────────────────────────────────
resource "aws_iot_topic_rule" "alert_processor" {
  count       = var.enable_iot_lambda_rules ? 1 : 0
  name        = "${replace(var.project_name, "-", "_")}_alert_processor"
  description = "Route alert messages to Lambda for alert log storage"
  enabled     = true
  sql         = "SELECT * FROM 'devices/+/alerts'"
  sql_version = "2016-03-23"

  lambda {
    function_arn = data.aws_lambda_function.alert_processor[0].arn
  }
}

# ─── Lambda Invoke Permissions ───────────────────────────────────────────────
resource "aws_lambda_permission" "iot_invoke_telemetry" {
  count         = var.enable_iot_lambda_rules ? 1 : 0
  statement_id  = "AllowIoTInvokeTelemetry"
  action        = "lambda:InvokeFunction"
  function_name = data.aws_lambda_function.telemetry_processor[0].function_name
  principal     = "iot.amazonaws.com"
  source_arn    = aws_iot_topic_rule.telemetry_processor[0].arn
}

resource "aws_lambda_permission" "iot_invoke_alert" {
  count         = var.enable_iot_lambda_rules ? 1 : 0
  statement_id  = "AllowIoTInvokeAlert"
  action        = "lambda:InvokeFunction"
  function_name = data.aws_lambda_function.alert_processor[0].function_name
  principal     = "iot.amazonaws.com"
  source_arn    = aws_iot_topic_rule.alert_processor[0].arn
}
