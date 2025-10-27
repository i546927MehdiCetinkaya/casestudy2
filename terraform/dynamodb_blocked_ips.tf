# DynamoDB table for blocked IPs
resource "aws_dynamodb_table" "blocked_ips" {
  name           = "${var.project_name}-${var.environment}-blocked-ips"
  billing_mode   = "PAY_PER_REQUEST"
  hash_key       = "ip_address"

  attribute {
    name = "ip_address"
    type = "S"
  }

  attribute {
    name = "blocked_at"
    type = "N"
  }

  global_secondary_index {
    name            = "blocked_at-index"
    hash_key        = "blocked_at"
    projection_type = "ALL"
  }

  ttl {
    attribute_name = "expiration_time"
    enabled        = true
  }

  point_in_time_recovery {
    enabled = true
  }

  tags = {
    Name = "${var.project_name}-${var.environment}-blocked-ips"
  }
}

# Output
output "blocked_ips_table_name" {
  value       = aws_dynamodb_table.blocked_ips.name
  description = "Name of the blocked IPs DynamoDB table"
}
