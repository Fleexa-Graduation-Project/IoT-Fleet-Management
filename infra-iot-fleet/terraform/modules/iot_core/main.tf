# AWS IoT Core Thing Type (Device Classification)
resource "aws_iot_thing_type" "fleet_device" {
  name = "${var.project_name}-device-type"

  properties {
    searchable_attributes = ["deviceType", "location", "version"]
    description = "IoT Fleet Device Type for smart home sensors"
  }
}

# AWS IoT Core Thing (Actual Device Registration)
resource "aws_iot_thing" "sample_device" {
  name            = "${var.project_name}-device"
  thing_type_name = aws_iot_thing_type.fleet_device.name

  attributes = {
    deviceType = "sensor"
    location   = "default"
    version    = "1.0"
  }
}

# AWS IoT Core Policy (Permissions)
resource "aws_iot_policy" "device_policy" {
  name = "${var.project_name}-device-policy"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "iot:Connect"
        ]
        Resource = "arn:aws:iot:${data.aws_region.current.name}:${data.aws_caller_identity.current.account_id}:client/$${iot:Connection.Thing.ThingName}"
      },
      {
        Effect = "Allow"
        Action = [
          "iot:Publish"
        ]
        Resource = [
          "arn:aws:iot:${data.aws_region.current.name}:${data.aws_caller_identity.current.account_id}:topicfilter/$aws/things/$${iot:Connection.Thing.ThingName}/shadow/update",
          "arn:aws:iot:${data.aws_region.current.name}:${data.aws_caller_identity.current.account_id}:topicfilter/devices/$${iot:Connection.Thing.ThingName}/telemetry"
        ]
      },
      {
        Effect = "Allow"
        Action = [
          "iot:Subscribe"
        ]
        Resource = [
          "arn:aws:iot:${data.aws_region.current.name}:${data.aws_caller_identity.current.account_id}:topicfilter/$aws/things/$${iot:Connection.Thing.ThingName}/shadow/update/accepted",
          "arn:aws:iot:${data.aws_region.current.name}:${data.aws_caller_identity.current.account_id}:topicfilter/$aws/things/$${iot:Connection.Thing.ThingName}/shadow/update/rejected"
        ]
      },
      {
        Effect = "Allow"
        Action = [
          "iot:Receive"
        ]
        Resource = [
          "arn:aws:iot:${data.aws_region.current.name}:${data.aws_caller_identity.current.account_id}:topicfilter/$aws/things/$${iot:Connection.Thing.ThingName}/shadow/update/accepted",
          "arn:aws:iot:${data.aws_region.current.name}:${data.aws_caller_identity.current.account_id}:topicfilter/$aws/things/$${iot:Connection.Thing.ThingName}/shadow/update/rejected"
        ]
      }
    ]
  })
}