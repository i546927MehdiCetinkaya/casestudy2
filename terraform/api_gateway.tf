# API Gateway + Lambda in VPC Setup
# Voor Ubuntu monitoring zonder AWS credentials op server

# API Gateway Endpoint (public) voor Ubuntu
resource "aws_api_gateway_rest_api" "soar_ingress" {
  name        = "${var.project_name}-${var.environment}-ingress-api"
  description = "Public API endpoint for Ubuntu failed login events"

  endpoint_configuration {
    types = ["REGIONAL"]
  }

  tags = {
    Name = "${var.project_name}-${var.environment}-ingress-api"
  }
}

# API Gateway Resource (/events)
resource "aws_api_gateway_resource" "events" {
  rest_api_id = aws_api_gateway_rest_api.soar_ingress.id
  parent_id   = aws_api_gateway_rest_api.soar_ingress.root_resource_id
  path_part   = "events"
}

# API Gateway Method (POST)
resource "aws_api_gateway_method" "post_event" {
  rest_api_id   = aws_api_gateway_rest_api.soar_ingress.id
  resource_id   = aws_api_gateway_resource.events.id
  http_method   = "POST"
  authorization = "NONE"
  api_key_required = true  # Requires API key for security
}

# Lambda Integration
resource "aws_api_gateway_integration" "lambda_integration" {
  rest_api_id = aws_api_gateway_rest_api.soar_ingress.id
  resource_id = aws_api_gateway_resource.events.id
  http_method = aws_api_gateway_method.post_event.http_method

  integration_http_method = "POST"
  type                    = "AWS_PROXY"
  uri                     = aws_lambda_function.ingress.invoke_arn
}

# API Gateway Deployment
resource "aws_api_gateway_deployment" "ingress" {
  depends_on = [
    aws_api_gateway_integration.lambda_integration
  ]

  rest_api_id = aws_api_gateway_rest_api.soar_ingress.id

  lifecycle {
    create_before_destroy = true
  }
}

# API Gateway Stage
resource "aws_api_gateway_stage" "ingress" {
  deployment_id = aws_api_gateway_deployment.ingress.id
  rest_api_id   = aws_api_gateway_rest_api.soar_ingress.id
  stage_name    = var.environment
}

# API Key
resource "aws_api_gateway_api_key" "ubuntu_monitor" {
  name    = "${var.project_name}-${var.environment}-ubuntu-monitor-key"
  enabled = true
}

# Usage Plan
resource "aws_api_gateway_usage_plan" "ubuntu_monitor" {
  name = "${var.project_name}-${var.environment}-ubuntu-monitor-plan"

  api_stages {
    api_id = aws_api_gateway_rest_api.soar_ingress.id
    stage  = aws_api_gateway_stage.ingress.stage_name
  }

  quota_settings {
    limit  = 10000
    period = "DAY"
  }

  throttle_settings {
    burst_limit = 100
    rate_limit  = 50
  }
}

# Associate API Key with Usage Plan
resource "aws_api_gateway_usage_plan_key" "ubuntu_monitor" {
  key_id        = aws_api_gateway_api_key.ubuntu_monitor.id
  key_type      = "API_KEY"
  usage_plan_id = aws_api_gateway_usage_plan.ubuntu_monitor.id
}

# Lambda Permission for API Gateway
resource "aws_lambda_permission" "api_gateway_invoke" {
  statement_id  = "AllowAPIGatewayInvoke"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.ingress.function_name
  principal     = "apigateway.amazonaws.com"
  source_arn    = "${aws_api_gateway_rest_api.soar_ingress.execution_arn}/*/*/*"
}

# Output the API endpoint and key
output "api_gateway_endpoint" {
  description = "API Gateway endpoint URL for Ubuntu monitoring"
  value       = "${aws_api_gateway_stage.ingress.invoke_url}/events"
}

output "api_key_id" {
  description = "API Key ID (use this to get the actual key value)"
  value       = aws_api_gateway_api_key.ubuntu_monitor.id
}

output "get_api_key_command" {
  description = "Command to retrieve the API key"
  value       = "aws apigateway get-api-key --api-key ${aws_api_gateway_api_key.ubuntu_monitor.id} --include-value --query 'value' --output text"
}
