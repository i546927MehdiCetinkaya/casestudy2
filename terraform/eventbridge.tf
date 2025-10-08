# EventBridge for On-Premises Webserver Integration
# This receives HTTP events from the on-premises webserver (192.168.154.13)
# and forwards them to SQS -> Lambda pipeline

# EventBridge API Destination (HTTP endpoint target)
resource "aws_cloudwatch_event_connection" "onprem_webserver" {
  count = var.enable_vpn ? 1 : 0
  
  name               = "${var.project_name}-${var.environment}-onprem-connection"
  description        = "Connection to on-premises webserver (192.168.154.13)"
  authorization_type = "BASIC"

  auth_parameters {
    basic {
      username = var.onprem_webserver_username
      password = var.onprem_webserver_password
    }
  }
}

resource "aws_cloudwatch_event_api_destination" "onprem_webserver" {
  count = var.enable_vpn ? 1 : 0
  
  name                             = "${var.project_name}-${var.environment}-onprem-destination"
  description                      = "On-premises webserver API destination"
  invocation_endpoint              = "http://${var.onprem_webserver_ip}"
  http_method                      = "POST"
  invocation_rate_limit_per_second = 10
  connection_arn                   = aws_cloudwatch_event_connection.onprem_webserver[0].arn
}

# EventBridge Rule to receive events from on-premises
resource "aws_cloudwatch_event_rule" "onprem_events" {
  name        = "${var.project_name}-${var.environment}-onprem-events"
  description = "Capture events from on-premises webserver"

  event_pattern = jsonencode({
    source      = ["custom.onprem"]
    detail-type = ["Security Event", "System Alert"]
  })

  tags = {
    Name = "${var.project_name}-${var.environment}-onprem-events"
  }
}

# EventBridge target: Forward to SQS Parser Queue
resource "aws_cloudwatch_event_target" "parser_queue" {
  rule      = aws_cloudwatch_event_rule.onprem_events.name
  target_id = "ParserQueue"
  arn       = aws_sqs_queue.parser_queue.arn

  input_transformer {
    input_paths = {
      detail     = "$.detail"
      time       = "$.time"
      source     = "$.source"
      detailType = "$.detail-type"
    }
    input_template = <<EOF
{
  "event": <detail>,
  "timestamp": "<time>",
  "source": "<source>",
  "type": "<detailType>"
}
EOF
  }
}

# SQS Queue Policy to allow EventBridge to send messages
resource "aws_sqs_queue_policy" "parser_queue_eventbridge" {
  queue_url = aws_sqs_queue.parser_queue.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid    = "AllowEventBridgeToSendMessage"
        Effect = "Allow"
        Principal = {
          Service = "events.amazonaws.com"
        }
        Action   = "sqs:SendMessage"
        Resource = aws_sqs_queue.parser_queue.arn
        Condition = {
          ArnEquals = {
            "aws:SourceArn" = aws_cloudwatch_event_rule.onprem_events.arn
          }
        }
      }
    ]
  })
}

# CloudWatch Log Group for EventBridge
resource "aws_cloudwatch_log_group" "eventbridge" {
  name              = "/aws/events/${var.project_name}-${var.environment}"
  retention_in_days = 7

  tags = {
    Name = "${var.project_name}-${var.environment}-eventbridge-logs"
  }
}

# EventBridge Rule for API Gateway events (if using API Gateway as well)
resource "aws_cloudwatch_event_rule" "api_events" {
  name        = "${var.project_name}-${var.environment}-api-events"
  description = "Capture events from API Gateway/ALB"

  event_pattern = jsonencode({
    source      = ["aws.apigateway", "custom.alb"]
    detail-type = ["API Call", "HTTP Request"]
  })

  tags = {
    Name = "${var.project_name}-${var.environment}-api-events"
  }
}

# EventBridge target for API events: Forward to SQS Parser Queue
resource "aws_cloudwatch_event_target" "api_parser_queue" {
  rule      = aws_cloudwatch_event_rule.api_events.name
  target_id = "ApiParserQueue"
  arn       = aws_sqs_queue.parser_queue.arn
}
