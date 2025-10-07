# DynamoDB Table for Event Storage
resource "aws_dynamodb_table" "events" {
  name           = "${var.project_name}-${var.environment}-events"
  billing_mode   = "PAY_PER_REQUEST"
  hash_key       = "event_id"
  range_key      = "timestamp"

  attribute {
    name = "event_id"
    type = "S"
  }

  attribute {
    name = "timestamp"
    type = "N"
  }

  attribute {
    name = "severity"
    type = "S"
  }

  global_secondary_index {
    name            = "severity-index"
    hash_key        = "severity"
    range_key       = "timestamp"
    projection_type = "ALL"
  }

  point_in_time_recovery {
    enabled = true
  }

  tags = {
    Name = "${var.project_name}-${var.environment}-events"
  }
}

# SQS Queues
resource "aws_sqs_queue" "parser_queue" {
  name                       = "${var.project_name}-${var.environment}-parser-queue"
  delay_seconds              = 0
  max_message_size           = 262144
  message_retention_seconds  = 1209600
  receive_wait_time_seconds  = 0
  visibility_timeout_seconds = 60

  tags = {
    Name = "${var.project_name}-${var.environment}-parser-queue"
  }
}

resource "aws_sqs_queue" "parser_dlq" {
  name = "${var.project_name}-${var.environment}-parser-dlq"

  tags = {
    Name = "${var.project_name}-${var.environment}-parser-dlq"
  }
}

resource "aws_sqs_queue_redrive_policy" "parser" {
  queue_url = aws_sqs_queue.parser_queue.id
  redrive_policy = jsonencode({
    deadLetterTargetArn = aws_sqs_queue.parser_dlq.arn
    maxReceiveCount     = 3
  })
}

resource "aws_sqs_queue" "engine_queue" {
  name                       = "${var.project_name}-${var.environment}-engine-queue"
  delay_seconds              = 0
  max_message_size           = 262144
  message_retention_seconds  = 1209600
  receive_wait_time_seconds  = 0
  visibility_timeout_seconds = 120

  tags = {
    Name = "${var.project_name}-${var.environment}-engine-queue"
  }
}

resource "aws_sqs_queue" "engine_dlq" {
  name = "${var.project_name}-${var.environment}-engine-dlq"

  tags = {
    Name = "${var.project_name}-${var.environment}-engine-dlq"
  }
}

resource "aws_sqs_queue_redrive_policy" "engine" {
  queue_url = aws_sqs_queue.engine_queue.id
  redrive_policy = jsonencode({
    deadLetterTargetArn = aws_sqs_queue.engine_dlq.arn
    maxReceiveCount     = 3
  })
}

resource "aws_sqs_queue" "notify_queue" {
  name                       = "${var.project_name}-${var.environment}-notify-queue"
  delay_seconds              = 0
  max_message_size           = 262144
  message_retention_seconds  = 1209600
  receive_wait_time_seconds  = 0
  visibility_timeout_seconds = 60

  tags = {
    Name = "${var.project_name}-${var.environment}-notify-queue"
  }
}

resource "aws_sqs_queue" "remediation_queue" {
  name                       = "${var.project_name}-${var.environment}-remediation-queue"
  delay_seconds              = 0
  max_message_size           = 262144
  message_retention_seconds  = 1209600
  receive_wait_time_seconds  = 0
  visibility_timeout_seconds = 600

  tags = {
    Name = "${var.project_name}-${var.environment}-remediation-queue"
  }
}

# SNS Topics
resource "aws_sns_topic" "security_alerts" {
  name = "${var.project_name}-${var.environment}-security-alerts"

  tags = {
    Name = "${var.project_name}-${var.environment}-security-alerts"
  }
}

resource "aws_sns_topic_subscription" "security_alerts_email" {
  topic_arn = aws_sns_topic.security_alerts.arn
  protocol  = "email"
  endpoint  = "security-team@example.com"  # Change this to your email
}

# EventBridge Rule for CloudTrail Events
resource "aws_cloudwatch_event_rule" "cloudtrail_events" {
  name        = "${var.project_name}-${var.environment}-cloudtrail-events"
  description = "Capture CloudTrail security events"

  event_pattern = jsonencode({
    source      = ["aws.cloudtrail"]
    detail-type = ["AWS API Call via CloudTrail"]
  })
}

resource "aws_cloudwatch_event_target" "parser_queue" {
  rule      = aws_cloudwatch_event_rule.cloudtrail_events.name
  target_id = "SendToParserQueue"
  arn       = aws_sqs_queue.parser_queue.arn
}

# Allow EventBridge to send messages to SQS
resource "aws_sqs_queue_policy" "parser_queue_policy" {
  queue_url = aws_sqs_queue.parser_queue.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Principal = {
          Service = "events.amazonaws.com"
        }
        Action   = "sqs:SendMessage"
        Resource = aws_sqs_queue.parser_queue.arn
        Condition = {
          ArnEquals = {
            "aws:SourceArn" = aws_cloudwatch_event_rule.cloudtrail_events.arn
          }
        }
      }
    ]
  })
}
