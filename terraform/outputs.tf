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

output "ingress_lambda_arn" {
  description = "Ingress Lambda ARN"
  value       = aws_lambda_function.ingress.arn
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

output "dynamodb_table_name" {
  description = "DynamoDB Table Name"
  value       = aws_dynamodb_table.events.name
}

output "sns_topic_arn" {
  description = "SNS Topic ARN"
  value       = aws_sns_topic.security_alerts.arn
}

output "cloudwatch_dashboard_name" {
  description = "Name of the CloudWatch dashboard"
  value       = aws_cloudwatch_dashboard.soar_monitoring.dashboard_name
}
