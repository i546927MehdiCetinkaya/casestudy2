# CloudWatch Alarms for Lambda Functions

# SNS Topic for Lambda Alarms
resource "aws_sns_topic" "lambda_alarms" {
  name = "${var.project_name}-${var.environment}-lambda-alarms"

  tags = {
    Name = "${var.project_name}-${var.environment}-lambda-alarms"
  }
}

resource "aws_sns_topic_subscription" "lambda_alarms_email" {
  topic_arn = aws_sns_topic.lambda_alarms.arn
  protocol  = "email"
  endpoint  = var.alert_email
}

# Parser Lambda Alarms
resource "aws_cloudwatch_metric_alarm" "parser_errors" {
  alarm_name          = "${var.project_name}-${var.environment}-parser-errors"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = 1
  metric_name         = "Errors"
  namespace           = "AWS/Lambda"
  period              = 300
  statistic           = "Sum"
  threshold           = 5
  alarm_description   = "Parser Lambda error count exceeded threshold"
  alarm_actions       = [aws_sns_topic.lambda_alarms.arn]

  dimensions = {
    FunctionName = aws_lambda_function.parser.function_name
  }
}

resource "aws_cloudwatch_metric_alarm" "parser_duration" {
  alarm_name          = "${var.project_name}-${var.environment}-parser-duration"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = 2
  metric_name         = "Duration"
  namespace           = "AWS/Lambda"
  period              = 300
  statistic           = "Average"
  threshold           = 3000
  alarm_description   = "Parser Lambda duration exceeded 3 seconds"
  alarm_actions       = [aws_sns_topic.lambda_alarms.arn]

  dimensions = {
    FunctionName = aws_lambda_function.parser.function_name
  }
}

# Engine Lambda Alarms
resource "aws_cloudwatch_metric_alarm" "engine_errors" {
  alarm_name          = "${var.project_name}-${var.environment}-engine-errors"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = 1
  metric_name         = "Errors"
  namespace           = "AWS/Lambda"
  period              = 300
  statistic           = "Sum"
  threshold           = 5
  alarm_description   = "Engine Lambda error count exceeded threshold"
  alarm_actions       = [aws_sns_topic.lambda_alarms.arn]

  dimensions = {
    FunctionName = aws_lambda_function.engine.function_name
  }
}

resource "aws_cloudwatch_metric_alarm" "engine_duration" {
  alarm_name          = "${var.project_name}-${var.environment}-engine-duration"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = 2
  metric_name         = "Duration"
  namespace           = "AWS/Lambda"
  period              = 300
  statistic           = "Average"
  threshold           = 5000
  alarm_description   = "Engine Lambda duration exceeded 5 seconds"
  alarm_actions       = [aws_sns_topic.lambda_alarms.arn]

  dimensions = {
    FunctionName = aws_lambda_function.engine.function_name
  }
}

# Ingress Lambda Alarms
resource "aws_cloudwatch_metric_alarm" "ingress_errors" {
  alarm_name          = "${var.project_name}-${var.environment}-ingress-errors"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = 1
  metric_name         = "Errors"
  namespace           = "AWS/Lambda"
  period              = 300
  statistic           = "Sum"
  threshold           = 10
  alarm_description   = "Ingress Lambda error count exceeded threshold"
  alarm_actions       = [aws_sns_topic.lambda_alarms.arn]

  dimensions = {
    FunctionName = aws_lambda_function.ingress.function_name
  }
}

resource "aws_cloudwatch_metric_alarm" "ingress_throttles" {
  alarm_name          = "${var.project_name}-${var.environment}-ingress-throttles"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = 1
  metric_name         = "Throttles"
  namespace           = "AWS/Lambda"
  period              = 300
  statistic           = "Sum"
  threshold           = 5
  alarm_description   = "Ingress Lambda is being throttled"
  alarm_actions       = [aws_sns_topic.lambda_alarms.arn]

  dimensions = {
    FunctionName = aws_lambda_function.ingress.function_name
  }
}

# Notify Lambda Alarms
resource "aws_cloudwatch_metric_alarm" "notify_errors" {
  alarm_name          = "${var.project_name}-${var.environment}-notify-errors"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = 1
  metric_name         = "Errors"
  namespace           = "AWS/Lambda"
  period              = 300
  statistic           = "Sum"
  threshold           = 3
  alarm_description   = "Notify Lambda error count exceeded threshold"
  alarm_actions       = [aws_sns_topic.lambda_alarms.arn]

  dimensions = {
    FunctionName = aws_lambda_function.notify.function_name
  }
}

# Remediate Lambda Alarms
resource "aws_cloudwatch_metric_alarm" "remediate_errors" {
  alarm_name          = "${var.project_name}-${var.environment}-remediate-errors"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = 1
  metric_name         = "Errors"
  namespace           = "AWS/Lambda"
  period              = 300
  statistic           = "Sum"
  threshold           = 3
  alarm_description   = "Remediate Lambda error count exceeded threshold"
  alarm_actions       = [aws_sns_topic.lambda_alarms.arn]

  dimensions = {
    FunctionName = aws_lambda_function.remediate.function_name
  }
}

# DynamoDB Alarms
resource "aws_cloudwatch_metric_alarm" "dynamodb_read_throttles" {
  alarm_name          = "${var.project_name}-${var.environment}-dynamodb-read-throttles"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = 1
  metric_name         = "ReadThrottleEvents"
  namespace           = "AWS/DynamoDB"
  period              = 300
  statistic           = "Sum"
  threshold           = 5
  alarm_description   = "DynamoDB read throttling detected"
  alarm_actions       = [aws_sns_topic.lambda_alarms.arn]

  dimensions = {
    TableName = aws_dynamodb_table.events.name
  }
}

resource "aws_cloudwatch_metric_alarm" "dynamodb_write_throttles" {
  alarm_name          = "${var.project_name}-${var.environment}-dynamodb-write-throttles"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = 1
  metric_name         = "WriteThrottleEvents"
  namespace           = "AWS/DynamoDB"
  period              = 300
  statistic           = "Sum"
  threshold           = 5
  alarm_description   = "DynamoDB write throttling detected"
  alarm_actions       = [aws_sns_topic.lambda_alarms.arn]

  dimensions = {
    TableName = aws_dynamodb_table.events.name
  }
}

# SQS Alarms
resource "aws_cloudwatch_metric_alarm" "parser_queue_age" {
  alarm_name          = "${var.project_name}-${var.environment}-parser-queue-age"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = 2
  metric_name         = "ApproximateAgeOfOldestMessage"
  namespace           = "AWS/SQS"
  period              = 300
  statistic           = "Maximum"
  threshold           = 600
  alarm_description   = "Parser queue has messages older than 10 minutes"
  alarm_actions       = [aws_sns_topic.lambda_alarms.arn]

  dimensions = {
    QueueName = aws_sqs_queue.parser_queue.name
  }
}

resource "aws_cloudwatch_metric_alarm" "engine_queue_age" {
  alarm_name          = "${var.project_name}-${var.environment}-engine-queue-age"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = 2
  metric_name         = "ApproximateAgeOfOldestMessage"
  namespace           = "AWS/SQS"
  period              = 300
  statistic           = "Maximum"
  threshold           = 600
  alarm_description   = "Engine queue has messages older than 10 minutes"
  alarm_actions       = [aws_sns_topic.lambda_alarms.arn]

  dimensions = {
    QueueName = aws_sqs_queue.engine_queue.name
  }
}

# API Gateway Alarms
resource "aws_cloudwatch_metric_alarm" "api_gateway_5xx_errors" {
  alarm_name          = "${var.project_name}-${var.environment}-api-5xx-errors"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = 1
  metric_name         = "5XXError"
  namespace           = "AWS/ApiGateway"
  period              = 300
  statistic           = "Sum"
  threshold           = 10
  alarm_description   = "API Gateway 5xx errors exceeded threshold"
  alarm_actions       = [aws_sns_topic.lambda_alarms.arn]

  dimensions = {
    ApiName = aws_api_gateway_rest_api.soar_ingress.name
  }
}

resource "aws_cloudwatch_metric_alarm" "api_gateway_latency" {
  alarm_name          = "${var.project_name}-${var.environment}-api-latency"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = 2
  metric_name         = "Latency"
  namespace           = "AWS/ApiGateway"
  period              = 300
  statistic           = "Average"
  threshold           = 2000
  alarm_description   = "API Gateway latency exceeded 2 seconds"
  alarm_actions       = [aws_sns_topic.lambda_alarms.arn]

  dimensions = {
    ApiName = aws_api_gateway_rest_api.soar_ingress.name
  }
}

# Dashboard
resource "aws_cloudwatch_dashboard" "soar_monitoring" {
  dashboard_name = "${var.project_name}-${var.environment}-soar-monitoring"

  dashboard_body = jsonencode({
    widgets = [
      {
        type = "metric"
        properties = {
          metrics = [
            ["AWS/Lambda", "Invocations", { stat = "Sum", label = "Parser Invocations" }],
            [".", "Errors", { stat = "Sum", label = "Parser Errors" }],
            [".", "Duration", { stat = "Average", label = "Parser Duration" }]
          ]
          period = 300
          stat   = "Average"
          region = var.aws_region
          title  = "Parser Lambda Metrics"
        }
      },
      {
        type = "metric"
        properties = {
          metrics = [
            ["AWS/Lambda", "Invocations", { stat = "Sum", label = "Engine Invocations" }],
            [".", "Errors", { stat = "Sum", label = "Engine Errors" }],
            [".", "Duration", { stat = "Average", label = "Engine Duration" }]
          ]
          period = 300
          stat   = "Average"
          region = var.aws_region
          title  = "Engine Lambda Metrics"
        }
      },
      {
        type = "metric"
        properties = {
          metrics = [
            ["AWS/SQS", "ApproximateNumberOfMessagesVisible", { stat = "Sum" }],
            [".", "ApproximateAgeOfOldestMessage", { stat = "Maximum" }]
          ]
          period = 300
          stat   = "Average"
          region = var.aws_region
          title  = "SQS Queue Metrics"
        }
      },
      {
        type = "metric"
        properties = {
          metrics = [
            ["AWS/DynamoDB", "ConsumedReadCapacityUnits", { stat = "Sum" }],
            [".", "ConsumedWriteCapacityUnits", { stat = "Sum" }]
          ]
          period = 300
          stat   = "Sum"
          region = var.aws_region
          title  = "DynamoDB Metrics"
        }
      }
    ]
  })
}

# Outputs
output "lambda_alarms_topic_arn" {
  value       = aws_sns_topic.lambda_alarms.arn
  description = "ARN of the Lambda alarms SNS topic"
}

output "cloudwatch_dashboard_name" {
  value       = aws_cloudwatch_dashboard.soar_monitoring.dashboard_name
  description = "Name of the CloudWatch dashboard"
}
