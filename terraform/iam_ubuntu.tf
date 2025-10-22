# IAM Role voor Ubuntu server EventBridge access
# Dit role kan alleen worden assumed vanaf IP 192.168.154.13

resource "aws_iam_role" "ubuntu_eventbridge" {
  name               = "${var.project_name}-${var.environment}-ubuntu-eventbridge"
  description        = "Role for Ubuntu server to send EventBridge events"
  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Principal = {
          AWS = "arn:aws:iam::${data.aws_caller_identity.current.account_id}:root"
        }
        Action = "sts:AssumeRole"
        Condition = {
          IpAddress = {
            "aws:SourceIp" = "192.168.154.13/32"
          }
        }
      }
    ]
  })

  tags = {
    Name        = "${var.project_name}-${var.environment}-ubuntu-eventbridge-role"
    Environment = var.environment
    Project     = var.project_name
    Purpose     = "Ubuntu failed login monitoring"
  }
}

# Policy voor EventBridge PutEvents
resource "aws_iam_role_policy" "ubuntu_eventbridge_policy" {
  name = "${var.project_name}-${var.environment}-ubuntu-eventbridge-policy"
  role = aws_iam_role.ubuntu_eventbridge.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "events:PutEvents"
        ]
        Resource = [
          "arn:aws:events:${var.aws_region}:${data.aws_caller_identity.current.account_id}:event-bus/default"
        ]
      }
    ]
  })
}

# Data source voor account ID
data "aws_caller_identity" "current" {}
