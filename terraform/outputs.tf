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

output "eks_cluster_endpoint" {
  description = "EKS Cluster Endpoint"
  value       = aws_eks_cluster.main.endpoint
}

output "eks_cluster_name" {
  description = "EKS Cluster Name"
  value       = aws_eks_cluster.main.name
}

output "eks_cluster_security_group_id" {
  description = "EKS Cluster Security Group ID"
  value       = aws_security_group.eks_cluster.id
}

output "alb_dns_name" {
  description = "ALB DNS Name"
  value       = aws_lb.main.dns_name
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

output "ecr_soar_api_url" {
  description = "ECR SOAR API Repository URL"
  value       = aws_ecr_repository.soar_api.repository_url
}

output "ecr_soar_processor_url" {
  description = "ECR SOAR Processor Repository URL"
  value       = aws_ecr_repository.soar_processor.repository_url
}

output "ecr_soar_remediation_url" {
  description = "ECR SOAR Remediation Repository URL"
  value       = aws_ecr_repository.soar_remediation.repository_url
}

output "soar_pods_role_arn" {
  description = "IAM Role ARN for SOAR Pods"
  value       = aws_iam_role.soar_pods.arn
}

output "vpn_connection_id" {
  description = "VPN Connection ID"
  value       = var.enable_vpn ? aws_vpn_connection.main[0].id : null
}

output "customer_gateway_id" {
  description = "Customer Gateway ID"
  value       = var.enable_vpn ? aws_customer_gateway.main[0].id : null
}
