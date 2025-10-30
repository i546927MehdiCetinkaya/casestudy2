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
      # Top Row - Security Overview
      {
        type   = "metric"
        x      = 0
        y      = 0
        width  = 8
        height = 6
        properties = {
          metrics = [
            ["AWS/Lambda", "Invocations", { "stat" : "Sum", "label" : "Total Failed Logins Detected", "id" : "m1", "yAxis" : "left" }]
          ]
          view    = "singleValue"
          region  = var.aws_region
          title   = "📊 Total Security Events (24h)"
          period  = 86400
          stat    = "Sum"
          yAxis = {
            left = {
              min = 0
            }
          }
        }
      },
      {
        type   = "metric"
        x      = 8
        y      = 0
        width  = 8
        height = 6
        properties = {
          metrics = [
            ["AWS/Lambda", "Invocations", { "stat" : "Sum", "label" : "Alerts Sent", "id" : "m1" }]
          ]
          view    = "singleValue"
          region  = var.aws_region
          title   = "🚨 Email Alerts Sent (24h)"
          period  = 86400
          stat    = "Sum"
          yAxis = {
            left = {
              min = 0
            }
          }
        }
      },
      {
        type   = "metric"
        x      = 16
        y      = 0
        width  = 8
        height = 6
        properties = {
          metrics = [
            ["AWS/Lambda", "Errors", { "stat" : "Sum", "label" : "System Errors", "id" : "m1" }]
          ]
          view    = "singleValue"
          region  = var.aws_region
          title   = "⚠️ System Errors (24h)"
          period  = 86400
          stat    = "Sum"
          yAxis = {
            left = {
              min = 0
            }
          }
        }
      },
      
      # Second Row - Event Timeline
      {
        type   = "metric"
        x      = 0
        y      = 6
        width  = 12
        height = 6
        properties = {
          metrics = [
            ["AWS/Lambda", "Invocations", { "stat" : "Sum", "label" : "Failed Login Attempts", "color" : "#d62728" }]
          ]
          view    = "timeSeries"
          stacked = false
          region  = var.aws_region
          title   = "📈 Failed Login Timeline"
          period  = 300
          stat    = "Sum"
          yAxis = {
            left = {
              min       = 0
              showUnits = false
            }
          }
          annotations = {
            horizontal = [
              {
                label = "Normal Activity"
                value = 5
                fill  = "below"
                color = "#2ca02c"
              },
              {
                label = "Suspicious Activity"
                value = 10
                fill  = "between 5 and 10"
                color = "#ff7f0e"
              },
              {
                label = "Attack Detected"
                value = 10
                fill  = "above"
                color = "#d62728"
              }
            ]
          }
        }
      },
      {
        type   = "metric"
        x      = 12
        y      = 6
        width  = 12
        height = 6
        properties = {
          metrics = [
            ["AWS/Lambda", "Invocations", { "stat" : "Sum", "label" : "Email Alerts Sent", "color" : "#ff7f0e" }]
          ]
          view    = "timeSeries"
          stacked = false
          region  = var.aws_region
          title   = "📧 Alert Notifications Timeline"
          period  = 300
          stat    = "Sum"
          yAxis = {
            left = {
              min       = 0
              showUnits = false
            }
          }
        }
      },
      
      # Third Row - Lambda Performance
      {
        type   = "metric"
        x      = 0
        y      = 12
        width  = 8
        height = 6
        properties = {
          metrics = [
            ["AWS/Lambda", "Invocations", { "stat" : "Sum", "label" : "Ingress" }],
            ["...", { "stat" : "Sum", "label" : "Parser" }],
            ["...", { "stat" : "Sum", "label" : "Engine" }],
            ["...", { "stat" : "Sum", "label" : "Notify" }]
          ]
          view    = "timeSeries"
          stacked = false
          region  = var.aws_region
          title   = "⚡ Lambda Pipeline Activity"
          period  = 300
          stat    = "Sum"
          yAxis = {
            left = {
              min       = 0
              showUnits = false
            }
          }
        }
      },
      {
        type   = "metric"
        x      = 8
        y      = 12
        width  = 8
        height = 6
        properties = {
          metrics = [
            ["AWS/Lambda", "Duration", { "stat" : "Average", "label" : "Ingress" }],
            ["...", { "stat" : "Average", "label" : "Parser" }],
            ["...", { "stat" : "Average", "label" : "Engine" }],
            ["...", { "stat" : "Average", "label" : "Notify" }]
          ]
          view    = "timeSeries"
          stacked = false
          region  = var.aws_region
          title   = "⏱️ Lambda Response Times (ms)"
          period  = 300
          stat    = "Average"
          yAxis = {
            left = {
              min       = 0
              showUnits = true
            }
          }
        }
      },
      {
        type   = "metric"
        x      = 16
        y      = 12
        width  = 8
        height = 6
        properties = {
          metrics = [
            ["AWS/Lambda", "Errors", { "stat" : "Sum", "label" : "Ingress", "color" : "#d62728" }],
            ["...", { "stat" : "Sum", "label" : "Parser", "color" : "#d62728" }],
            ["...", { "stat" : "Sum", "label" : "Engine", "color" : "#d62728" }],
            ["...", { "stat" : "Sum", "label" : "Notify", "color" : "#d62728" }]
          ]
          view    = "timeSeries"
          stacked = true
          region  = var.aws_region
          title   = "❌ Lambda Errors"
          period  = 300
          stat    = "Sum"
          yAxis = {
            left = {
              min       = 0
              showUnits = false
            }
          }
        }
      },
      
      # Fourth Row - Infrastructure Health
      {
        type   = "metric"
        x      = 0
        y      = 18
        width  = 8
        height = 6
        properties = {
          metrics = [
            ["AWS/SQS", "ApproximateNumberOfMessagesVisible", { "stat" : "Average", "label" : "Parser Queue" }],
            ["...", { "stat" : "Average", "label" : "Engine Queue" }],
            ["...", { "stat" : "Average", "label" : "Notify Queue" }],
            ["...", { "stat" : "Average", "label" : "Remediation Queue" }]
          ]
          view    = "timeSeries"
          stacked = false
          region  = var.aws_region
          title   = "📬 SQS Queue Depth"
          period  = 300
          stat    = "Average"
          yAxis = {
            left = {
              min       = 0
              showUnits = false
            }
          }
        }
      },
      {
        type   = "metric"
        x      = 8
        y      = 18
        width  = 8
        height = 6
        properties = {
          metrics = [
            ["AWS/DynamoDB", "ConsumedWriteCapacityUnits", { "stat" : "Sum", "label" : "Writes" }],
            [".", "ConsumedReadCapacityUnits", { "stat" : "Sum", "label" : "Reads" }]
          ]
          view    = "timeSeries"
          stacked = false
          region  = var.aws_region
          title   = "💾 DynamoDB Activity"
          period  = 300
          stat    = "Sum"
          yAxis = {
            left = {
              min       = 0
              showUnits = false
            }
          }
        }
      },
      {
        type   = "metric"
        x      = 16
        y      = 18
        width  = 8
        height = 6
        properties = {
          metrics = [
            ["AWS/ApiGateway", "Count", { "stat" : "Sum", "label" : "Total Requests" }],
            [".", "4XXError", { "stat" : "Sum", "label" : "Client Errors" }],
            [".", "5XXError", { "stat" : "Sum", "label" : "Server Errors" }]
          ]
          view    = "timeSeries"
          stacked = false
          region  = var.aws_region
          title   = "🌐 API Gateway Status"
          period  = 300
          stat    = "Sum"
          yAxis = {
            left = {
              min       = 0
              showUnits = false
            }
          }
        }
      },
      
      # Fifth Row - Logs Insights
      {
        type   = "log"
        x      = 0
        y      = 24
        width  = 24
        height = 6
        properties = {
          query   = "SOURCE '/aws/lambda/${var.project_name}-${var.environment}-ingress'\n| SOURCE '/aws/lambda/${var.project_name}-${var.environment}-parser'\n| SOURCE '/aws/lambda/${var.project_name}-${var.environment}-engine'\n| SOURCE '/aws/lambda/${var.project_name}-${var.environment}-notify'\n| fields @timestamp, @message\n| filter @message like /ERROR/ or @message like /Error/ or @message like /Exception/\n| sort @timestamp desc\n| limit 20"
          region  = var.aws_region
          stacked = false
          title   = "🔍 Recent Errors & Exceptions"
          view    = "table"
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
output "cloudwatch_dashboard_url" {
  value       = "https://console.aws.amazon.com/cloudwatch/home?region=${var.aws_region}#dashboards:name=${aws_cloudwatch_dashboard.soar_monitoring.dashboard_name}"
  description = "URL to the CloudWatch dashboard"
}
