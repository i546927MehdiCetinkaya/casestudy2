output "vpc_id" {
  description = "VPC ID"
  value       = aws_vpc.main.id
}

output "public_subnet_ids" {
  description = "Public Subnet IDs"
  value       = aws_subnet.public[*].id
}

output "private_subnet_ids" {
  description = "Private Subnet IDs"
  value       = aws_subnet.private[*].id
}

output "lambda_private_subnet_id" {
  description = "Lambda Private Subnet ID"
  value       = aws_subnet.lambda_private.id
}

output "parser_lambda_arn" {
  description = "Parser Lambda ARN"
  value       = aws_lambda_function.parser.arn
}

output "engine_lambda_arn" {
  description = "Engine Lambda ARN"
  value       = aws_lambda_function.engine.arn
}

output "notify_lambda_arn" {
  description = "Notify Lambda ARN"
  value       = aws_lambda_function.notify.arn
}

output "remediate_lambda_arn" {
  description = "Remediate Lambda ARN"
  value       = aws_lambda_function.remediate.arn
}

output "dynamodb_table_name" {
  description = "DynamoDB Table Name"
  value       = aws_dynamodb_table.events.name
}

output "sns_topic_arn" {
  description = "SNS Topic ARN"
  value       = aws_sns_topic.security_alerts.arn
}

output "vpn_status" {
  description = "VPN Connection Status"
  value       = var.enable_vpn ? "Enabled" : "Disabled"
}

output "client_vpn_endpoint" {
  description = "Client VPN Endpoint ID"
  value       = var.enable_client_vpn ? aws_ec2_client_vpn_endpoint.main[0].id : null
}
