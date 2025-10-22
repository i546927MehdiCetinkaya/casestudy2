# EventBridge for Lambda SOAR
# Receives security events and forwards them to SQS -> Lambda pipeline

# EventBridge Rule to receive security events
resource "aws_cloudwatch_event_rule" "security_events" {
  name        = "${var.project_name}-${var.environment}-security-events"
  description = "Capture security events for SOAR processing"

  event_pattern = jsonencode({
    source      = ["custom.security", "aws.guardduty", "aws.securityhub"]
    detail-type = ["Security Event", "GuardDuty Finding", "Security Hub Finding"]
  })

  tags = {
    Name = "${var.project_name}-${var.environment}-security-events"
  }
}

# EventBridge target: Forward to SQS Parser Queue
resource "aws_cloudwatch_event_target" "parser_queue" {
  rule      = aws_cloudwatch_event_rule.security_events.name
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
            "aws:SourceArn" = aws_cloudwatch_event_rule.security_events.arn
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
