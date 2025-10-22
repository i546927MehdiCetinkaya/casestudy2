# IAM User voor Ubuntu server (gebruikt Role via AssumeRole)
# Deze user krijgt alleen permission om het ubuntu-eventbridge role te assume

resource "aws_iam_user" "ubuntu_server" {
  name = "${var.project_name}-${var.environment}-ubuntu-server"
  path = "/system/"

  tags = {
    Name        = "${var.project_name}-${var.environment}-ubuntu-server"
    Environment = var.environment
    Project     = var.project_name
    Purpose     = "Ubuntu server authentication for EventBridge"
  }
}

# Access key voor de Ubuntu server user
resource "aws_iam_access_key" "ubuntu_server" {
  user = aws_iam_user.ubuntu_server.name
}

# Policy die alleen AssumeRole toestaat voor het ubuntu-eventbridge role
resource "aws_iam_user_policy" "ubuntu_assume_role" {
  name = "${var.project_name}-${var.environment}-ubuntu-assume-role"
  user = aws_iam_user.ubuntu_server.name

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "sts:AssumeRole"
        ]
        Resource = [
          aws_iam_role.ubuntu_eventbridge.arn
        ]
      }
    ]
  })
}

# Outputs voor credentials (ALLEEN voor eerste setup)
output "ubuntu_user_access_key_id" {
  value       = aws_iam_access_key.ubuntu_server.id
  description = "Access Key ID voor Ubuntu server - gebruik dit eenmalig voor setup"
  sensitive   = true
}

output "ubuntu_user_secret_access_key" {
  value       = aws_iam_access_key.ubuntu_server.secret
  description = "Secret Access Key voor Ubuntu server - gebruik dit eenmalig voor setup"
  sensitive   = true
}

output "ubuntu_eventbridge_role_arn" {
  value       = aws_iam_role.ubuntu_eventbridge.arn
  description = "ARN van het Ubuntu EventBridge role"
}
