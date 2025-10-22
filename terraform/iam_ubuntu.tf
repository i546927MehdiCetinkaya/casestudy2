# IAM Role voor Ubuntu server EventBridge access
# Dit role kan worden assumed door SSO users en GitHub OIDC vanaf IP 192.168.154.13

resource "aws_iam_role" "ubuntu_eventbridge" {
  name               = "${var.project_name}-${var.environment}-ubuntu-eventbridge"
  description        = "Role for Ubuntu server to send EventBridge events"
  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Principal = {
          AWS = [
            "arn:aws:iam::${data.aws_caller_identity.current.account_id}:role/githubrepo",
            "arn:aws:iam::${data.aws_caller_identity.current.account_id}:role/aws-reserved/sso.amazonaws.com/eu-central-1/AWSReservedSSO_fictisb_IsbUsersPS_2f9b7e07b8441d9f"
          ]
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

# Output voor Role ARN
output "ubuntu_eventbridge_role_arn" {
  value       = aws_iam_role.ubuntu_eventbridge.arn
  description = "ARN van het Ubuntu EventBridge role"
}
