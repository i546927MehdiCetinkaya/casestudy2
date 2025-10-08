# AWS Client VPN for Remote Access to Monitoring Services
# This allows you (and other authorized users) to connect to the VPC
# and access monitoring services (Prometheus/Grafana) via DNS

# Client VPN Endpoint
resource "aws_ec2_client_vpn_endpoint" "main" {
  count                  = var.enable_client_vpn ? 1 : 0
  description            = "Client VPN for monitoring access"
  server_certificate_arn = aws_acm_certificate.vpn_server[0].arn
  client_cidr_block      = var.client_vpn_cidr
  split_tunnel           = true  # Only VPC traffic goes through VPN
  
  authentication_options {
    type                       = "certificate-authentication"
    root_certificate_chain_arn = aws_acm_certificate.vpn_client[0].arn
  }

  connection_log_options {
    enabled               = true
    cloudwatch_log_group  = aws_cloudwatch_log_group.client_vpn[0].name
    cloudwatch_log_stream = aws_cloudwatch_log_stream.client_vpn[0].name
  }

  dns_servers = [cidrhost(var.vpc_cidr, 2)]  # VPC DNS resolver

  tags = {
    Name        = "${var.project_name}-${var.environment}-client-vpn"
    Environment = var.environment
    Project     = var.project_name
  }
}

# Client VPN Network Association (attach to subnets)
resource "aws_ec2_client_vpn_network_association" "main" {
  count                  = var.enable_client_vpn ? length(aws_subnet.public) : 0
  client_vpn_endpoint_id = aws_ec2_client_vpn_endpoint.main[0].id
  subnet_id              = aws_subnet.public[count.index].id
}

# Client VPN Authorization Rule (allow access to VPC)
resource "aws_ec2_client_vpn_authorization_rule" "vpc_access" {
  count                  = var.enable_client_vpn ? 1 : 0
  client_vpn_endpoint_id = aws_ec2_client_vpn_endpoint.main[0].id
  target_network_cidr    = var.vpc_cidr
  authorize_all_groups   = true
  description            = "Allow access to VPC"
}

# Client VPN Authorization Rule (allow access to monitoring)
resource "aws_ec2_client_vpn_authorization_rule" "monitoring_access" {
  count                  = var.enable_client_vpn ? 1 : 0
  client_vpn_endpoint_id = aws_ec2_client_vpn_endpoint.main[0].id
  target_network_cidr    = "10.0.0.0/24"  # Adjust to monitoring subnet
  authorize_all_groups   = true
  description            = "Allow access to monitoring services"
}

# Client VPN Route (route to VPC)
resource "aws_ec2_client_vpn_route" "vpc" {
  count                  = var.enable_client_vpn ? length(aws_subnet.public) : 0
  client_vpn_endpoint_id = aws_ec2_client_vpn_endpoint.main[0].id
  destination_cidr_block = var.vpc_cidr
  target_vpc_subnet_id   = aws_subnet.public[count.index].id
}

# CloudWatch Log Group for Client VPN
resource "aws_cloudwatch_log_group" "client_vpn" {
  count             = var.enable_client_vpn ? 1 : 0
  name              = "/aws/clientvpn/${var.project_name}-${var.environment}"
  retention_in_days = 7

  tags = {
    Name = "${var.project_name}-${var.environment}-client-vpn-logs"
  }
}

resource "aws_cloudwatch_log_stream" "client_vpn" {
  count          = var.enable_client_vpn ? 1 : 0
  name           = "connections"
  log_group_name = aws_cloudwatch_log_group.client_vpn[0].name
}

# Security Group for Client VPN
resource "aws_security_group" "client_vpn" {
  count       = var.enable_client_vpn ? 1 : 0
  name_prefix = "${var.project_name}-${var.environment}-client-vpn-"
  description = "Security group for Client VPN access"
  vpc_id      = aws_vpc.main.id

  # Allow all traffic from VPN clients
  ingress {
    description = "Allow all from VPN clients"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = [var.client_vpn_cidr]
  }

  # Allow access to monitoring (Prometheus/Grafana)
  ingress {
    description = "HTTP for Grafana"
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = [var.client_vpn_cidr]
  }

  ingress {
    description = "HTTPS for Grafana"
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = [var.client_vpn_cidr]
  }

  ingress {
    description = "Prometheus"
    from_port   = 9090
    to_port     = 9090
    protocol    = "tcp"
    cidr_blocks = [var.client_vpn_cidr]
  }

  ingress {
    description = "Grafana"
    from_port   = 3000
    to_port     = 3000
    protocol    = "tcp"
    cidr_blocks = [var.client_vpn_cidr]
  }

  egress {
    description = "Allow all outbound"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name        = "${var.project_name}-${var.environment}-client-vpn-sg"
    Environment = var.environment
    Project     = var.project_name
  }
}

# ACM Certificate for VPN Server (self-signed for testing)
# In production, use proper certificates
resource "aws_acm_certificate" "vpn_server" {
  count            = var.enable_client_vpn ? 1 : 0
  private_key      = tls_private_key.vpn_server[0].private_key_pem
  certificate_body = tls_self_signed_cert.vpn_server[0].cert_pem

  tags = {
    Name = "${var.project_name}-${var.environment}-vpn-server-cert"
  }
}

resource "aws_acm_certificate" "vpn_client" {
  count            = var.enable_client_vpn ? 1 : 0
  private_key      = tls_private_key.vpn_client[0].private_key_pem
  certificate_body = tls_self_signed_cert.vpn_client[0].cert_pem

  tags = {
    Name = "${var.project_name}-${var.environment}-vpn-client-cert"
  }
}

# TLS Private Keys
resource "tls_private_key" "vpn_server" {
  count     = var.enable_client_vpn ? 1 : 0
  algorithm = "RSA"
  rsa_bits  = 2048
}

resource "tls_private_key" "vpn_client" {
  count     = var.enable_client_vpn ? 1 : 0
  algorithm = "RSA"
  rsa_bits  = 2048
}

# Self-Signed Certificates
resource "tls_self_signed_cert" "vpn_server" {
  count           = var.enable_client_vpn ? 1 : 0
  private_key_pem = tls_private_key.vpn_server[0].private_key_pem

  subject {
    common_name  = "${var.project_name}-${var.environment}-vpn-server"
    organization = "Fontys ICT"
  }

  validity_period_hours = 87600  # 10 years
  allowed_uses = [
    "key_encipherment",
    "digital_signature",
    "server_auth",
  ]
}

resource "tls_self_signed_cert" "vpn_client" {
  count           = var.enable_client_vpn ? 1 : 0
  private_key_pem = tls_private_key.vpn_client[0].private_key_pem

  subject {
    common_name  = "${var.project_name}-${var.environment}-vpn-client"
    organization = "Fontys ICT"
  }

  validity_period_hours = 87600  # 10 years
  allowed_uses = [
    "key_encipherment",
    "digital_signature",
    "client_auth",
  ]
}

# Outputs
output "client_vpn_endpoint_id" {
  description = "ID of the Client VPN endpoint"
  value       = var.enable_client_vpn ? aws_ec2_client_vpn_endpoint.main[0].id : null
}

output "client_vpn_dns_name" {
  description = "DNS name of the Client VPN endpoint"
  value       = var.enable_client_vpn ? aws_ec2_client_vpn_endpoint.main[0].dns_name : null
}

output "client_vpn_config_instructions" {
  description = "Instructions for downloading VPN client configuration"
  value = var.enable_client_vpn ? join("", [
    "To connect to the VPN:\n",
    "1. Download AWS VPN Client: https://aws.amazon.com/vpn/client-vpn-download/\n",
    "2. Download configuration file:\n",
    "   aws ec2 export-client-vpn-client-configuration --client-vpn-endpoint-id ${aws_ec2_client_vpn_endpoint.main[0].id} --output text > vpn-config.ovpn\n",
    "3. Add the client certificate and key to the config file\n",
    "4. Import the config file into AWS VPN Client\n",
    "5. Connect to access monitoring services\n\n",
    "Monitoring DNS: monitoring.${var.project_name}-${var.environment}.internal\n",
    "Grafana: http://monitoring.${var.project_name}-${var.environment}.internal:3000\n",
    "Prometheus: http://monitoring.${var.project_name}-${var.environment}.internal:9090"
  ]) : null
}

output "client_vpn_client_certificate" {
  description = "Client certificate for VPN authentication"
  value       = var.enable_client_vpn ? tls_self_signed_cert.vpn_client[0].cert_pem : null
  sensitive   = true
}

output "client_vpn_client_key" {
  description = "Client private key for VPN authentication"
  value       = var.enable_client_vpn ? tls_private_key.vpn_client[0].private_key_pem : null
  sensitive   = true
}
