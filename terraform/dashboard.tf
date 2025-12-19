# CloudWatch Dashboard - Complete Security Monitoring
resource "aws_cloudwatch_dashboard" "soar_monitoring" {
  dashboard_name = "${var.project_name}-${var.environment}-soar-monitoring"

  dashboard_body = jsonencode({
    widgets = [
      # Row 1: Key Security Metrics (Single Value)
      {
        type   = "metric"
        x      = 0
        y      = 0
        width  = 6
        height = 6
        properties = {
          metrics = [
            ["AWS/Lambda", "Invocations", "FunctionName", "${var.project_name}-${var.environment}-ingress"]
          ]
          view    = "singleValue"
          region  = var.aws_region
          title   = "Total Events (24h)"
          period  = 86400
          stat    = "Sum"
        }
      },
      {
        type   = "metric"
        x      = 6
        y      = 0
        width  = 6
        height = 6
        properties = {
          metrics = [
            ["AWS/Lambda", "Invocations", "FunctionName", "${var.project_name}-${var.environment}-notify"]
          ]
          view    = "singleValue"
          region  = var.aws_region
          title   = "Alerts Sent (24h)"
          period  = 86400
          stat    = "Sum"
        }
      },
      {
        type   = "metric"
        x      = 12
        y      = 0
        width  = 6
        height = 6
        properties = {
          metrics = [
            ["AWS/Lambda", "Errors"]
          ]
          view    = "singleValue"
          region  = var.aws_region
          title   = "System Errors (24h)"
          period  = 86400
          stat    = "Sum"
        }
      },
      {
        type   = "metric"
        x      = 18
        y      = 0
        width  = 6
        height = 6
        properties = {
          metrics = [
            ["AWS/Lambda", "Duration", "FunctionName", "${var.project_name}-${var.environment}-engine"]
          ]
          view    = "singleValue"
          region  = var.aws_region
          title   = "Avg Response (ms)"
          period  = 3600
          stat    = "Average"
        }
      },
      
      # Row 2: Real-time Event Log & Top Attack Sources
      {
        type   = "log"
        x      = 0
        y      = 6
        width  = 16
        height = 8
        properties = {
          query   = "SOURCE '/aws/lambda/${var.project_name}-${var.environment}-parser'\n| fields @timestamp, @message\n| sort @timestamp desc\n| limit 20"
          region  = var.aws_region
          title   = "Recent Security Events (Real-time)"
          view    = "table"
        }
      },
      {
        type   = "log"
        x      = 16
        y      = 6
        width  = 8
        height = 8
        properties = {
          query   = "SOURCE '/aws/lambda/${var.project_name}-${var.environment}-parser'\n| filter @message like /PARSED_EVENT/\n| parse @message /sourceIP=(?<SourceIP>[0-9.]+)/ \n| parse @message /username=(?<Username>[\\w]+)/ \n| stats count(*) as FailedAttempts by SourceIP, Username\n| sort FailedAttempts desc\n| limit 10"
          region  = var.aws_region
          title   = "Top Failed SSH Sources"
          view    = "table"
        }
      },
      
      # Row 3: Event Flow Timeline (Full Width)
      {
        type   = "metric"
        x      = 0
        y      = 14
        width  = 24
        height = 8
        properties = {
          metrics = [
            ["AWS/Lambda", "Invocations", "FunctionName", "${var.project_name}-${var.environment}-ingress", { label = "Incoming Events", color = "#FF6B6B", stat = "Sum" }],
            ["AWS/Lambda", "Invocations", "FunctionName", "${var.project_name}-${var.environment}-parser", { label = "Parsed Events", color = "#4ECDC4", stat = "Sum" }],
            ["AWS/Lambda", "Invocations", "FunctionName", "${var.project_name}-${var.environment}-engine", { label = "Analyzed Events", color = "#45B7D1", stat = "Sum" }],
            ["AWS/Lambda", "Invocations", "FunctionName", "${var.project_name}-${var.environment}-notify", { label = "Alerts Sent", color = "#FFA07A", stat = "Sum" }],
            ["AWS/Lambda", "Errors", { label = "Total Errors", color = "#FF0000", stat = "Sum", yAxis = "right" }]
          ]
          view    = "timeSeries"
          region  = var.aws_region
          title   = "Security Event Pipeline - Real-time Flow"
          period  = 60
          stat    = "Sum"
          yAxis = {
            left = {
              label = "Event Count"
              min = 0
            }
            right = {
              label = "Errors"
              min = 0
            }
          }
          annotations = {
            horizontal = [
              {
                label = "High Activity Threshold"
                value = 10
                fill = "above"
                color = "#FFD700"
              }
            ]
          }
        }
      },
      
      # Row 4: Lambda Performance Deep Dive
      {
        type   = "metric"
        x      = 0
        y      = 22
        width  = 12
        height = 6
        properties = {
          metrics = [
            ["AWS/Lambda", "Duration", "FunctionName", "${var.project_name}-${var.environment}-ingress", { label = "Ingress", color = "#FF6B6B" }],
            ["AWS/Lambda", "Duration", "FunctionName", "${var.project_name}-${var.environment}-parser", { label = "Parser", color = "#4ECDC4" }],
            ["AWS/Lambda", "Duration", "FunctionName", "${var.project_name}-${var.environment}-engine", { label = "Engine (Threat Detection)", color = "#45B7D1" }],
            ["AWS/Lambda", "Duration", "FunctionName", "${var.project_name}-${var.environment}-notify", { label = "Notify", color = "#FFA07A" }]
          ]
          view    = "timeSeries"
          region  = var.aws_region
          title   = "Lambda Execution Times (Performance Monitor)"
          period  = 60
          stat    = "Average"
          yAxis = {
            left = {
              label = "Milliseconds"
              min = 0
            }
          }
        }
      },
      {
        type   = "metric"
        x      = 12
        y      = 22
        width  = 12
        height = 6
        properties = {
          metrics = [
            ["AWS/Lambda", "ConcurrentExecutions", "FunctionName", "${var.project_name}-${var.environment}-ingress", { label = "Ingress", stat = "Maximum" }],
            ["AWS/Lambda", "ConcurrentExecutions", "FunctionName", "${var.project_name}-${var.environment}-parser", { label = "Parser", stat = "Maximum" }],
            ["AWS/Lambda", "ConcurrentExecutions", "FunctionName", "${var.project_name}-${var.environment}-engine", { label = "Engine", stat = "Maximum" }],
            ["AWS/Lambda", "ConcurrentExecutions", "FunctionName", "${var.project_name}-${var.environment}-notify", { label = "Notify", stat = "Maximum" }]
          ]
          view    = "timeSeries"
          region  = var.aws_region
          title   = "Lambda Concurrent Executions (Load)"
          period  = 60
          stat    = "Maximum"
          yAxis = {
            left = {
              label = "Concurrent Executions"
              min = 0
            }
          }
        }
      },
      
      # Row 5: Infrastructure Health & Queue Monitoring
      {
        type   = "metric"
        x      = 0
        y      = 28
        width  = 8
        height = 6
        properties = {
          metrics = [
            ["AWS/SQS", "NumberOfMessagesSent", "QueueName", "${var.project_name}-${var.environment}-parser-queue", { label = "Parser In", color = "#4ECDC4" }],
            ["AWS/SQS", "NumberOfMessagesDeleted", "QueueName", "${var.project_name}-${var.environment}-parser-queue", { label = "Parser Out", color = "#95E1D3" }],
            ["AWS/SQS", "NumberOfMessagesSent", "QueueName", "${var.project_name}-${var.environment}-engine-queue", { label = "Engine In", color = "#45B7D1" }],
            ["AWS/SQS", "NumberOfMessagesDeleted", "QueueName", "${var.project_name}-${var.environment}-engine-queue", { label = "Engine Out", color = "#A8E6CF" }]
          ]
          view    = "timeSeries"
          region  = var.aws_region
          title   = "SQS Message Throughput"
          period  = 60
          stat    = "Sum"
          yAxis = {
            left = {
              label = "Messages"
              min = 0
            }
          }
        }
      },
      {
        type   = "metric"
        x      = 8
        y      = 28
        width  = 8
        height = 6
        properties = {
          metrics = [
            ["AWS/DynamoDB", "ConsumedWriteCapacityUnits", "TableName", "${var.project_name}-${var.environment}-events", { label = "Write Capacity", color = "#FF6B6B" }],
            ["AWS/DynamoDB", "ConsumedReadCapacityUnits", "TableName", "${var.project_name}-${var.environment}-events", { label = "Read Capacity", color = "#4ECDC4" }],
            ["AWS/DynamoDB", "UserErrors", "TableName", "${var.project_name}-${var.environment}-events", { label = "User Errors", color = "#FFD93D", yAxis = "right" }]
          ]
          view    = "timeSeries"
          region  = var.aws_region
          title   = "DynamoDB Capacity & Errors"
          period  = 60
          stat    = "Sum"
          yAxis = {
            left = {
              label = "Capacity Units"
              min = 0
            }
            right = {
              label = "Errors"
              min = 0
            }
          }
        }
      },
      {
        type   = "metric"
        x      = 16
        y      = 28
        width  = 8
        height = 6
        properties = {
          metrics = [
            ["AWS/ApiGateway", "Count", "ApiName", "casestudy2-dev-api", { label = "Total Requests", color = "#45B7D1" }],
            ["AWS/ApiGateway", "4XXError", "ApiName", "casestudy2-dev-api", { label = "4XX Errors", color = "#FFD93D" }],
            ["AWS/ApiGateway", "5XXError", "ApiName", "casestudy2-dev-api", { label = "5XX Errors", color = "#FF6B6B" }],
            ["AWS/ApiGateway", "Latency", "ApiName", "casestudy2-dev-api", { label = "Latency (ms)", stat = "Average", yAxis = "right", color = "#98D8C8" }]
          ]
          view    = "timeSeries"
          region  = var.aws_region
          title   = "API Gateway Health"
          period  = 60
          stat    = "Sum"
          yAxis = {
            left = {
              label = "Request Count"
              min = 0
            }
            right = {
              label = "Latency (ms)"
              min = 0
            }
          }
        }
      }
    ]
  })
}