# Route53 Private Hosted Zone for Internal DNS Resolution
# This allows pods and Lambda to resolve internal service names

resource "aws_route53_zone" "private" {
  name = "${var.project_name}-${var.environment}.internal"

  vpc {
    vpc_id = aws_vpc.main.id
  }

  tags = {
    Name        = "${var.project_name}-${var.environment}-private-zone"
    Environment = var.environment
    Project     = var.project_name
  }
}

# DNS Record for Monitoring Service (Prometheus/Grafana)
resource "aws_route53_record" "monitoring" {
  zone_id = aws_route53_zone.private.zone_id
  name    = "monitoring.${aws_route53_zone.private.name}"
  type    = "A"
  ttl     = 300
  records = [var.monitoring_service_ip]

  # If monitoring is behind ALB, use alias instead
  # alias {
  #   name                   = aws_lb.main.dns_name
  #   zone_id                = aws_lb.main.zone_id
  #   evaluate_target_health = true
  # }
}

# DNS Record for Internal API
resource "aws_route53_record" "api" {
  zone_id = aws_route53_zone.private.zone_id
  name    = "api.${aws_route53_zone.private.name}"
  type    = "A"

  alias {
    name                   = aws_lb.main.dns_name
    zone_id                = aws_lb.main.zone_id
    evaluate_target_health = true
  }
}

# DNS Record for On-Premises Webserver
resource "aws_route53_record" "onprem_webserver" {
  count   = var.enable_vpn ? 1 : 0
  zone_id = aws_route53_zone.private.zone_id
  name    = "onprem.${aws_route53_zone.private.name}"
  type    = "A"
  ttl     = 300
  records = [var.onprem_webserver_ip]
}

# VPC Endpoint for Route53
resource "aws_vpc_endpoint" "route53" {
  vpc_id              = aws_vpc.main.id
  service_name        = "com.amazonaws.${var.aws_region}.route53resolver"
  vpc_endpoint_type   = "Interface"
  subnet_ids          = concat(aws_subnet.private[*].id, aws_subnet.lambda[*].id)
  security_group_ids  = [aws_security_group.vpc_endpoints.id]
  private_dns_enabled = true

  tags = {
    Name = "${var.project_name}-${var.environment}-route53-endpoint"
  }
}

# Route53 Resolver Rule for On-Premises DNS (optional)
resource "aws_route53_resolver_rule" "onprem_dns" {
  count                = var.enable_vpn && var.onprem_dns_ip != "" ? 1 : 0
  domain_name          = var.onprem_dns_domain
  name                 = "${var.project_name}-${var.environment}-onprem-dns"
  rule_type            = "FORWARD"
  resolver_endpoint_id = aws_route53_resolver_endpoint.outbound[0].id

  target_ip {
    ip = var.onprem_dns_ip
  }

  tags = {
    Name        = "${var.project_name}-${var.environment}-onprem-dns-rule"
    Environment = var.environment
    Project     = var.project_name
  }
}

# Route53 Resolver Outbound Endpoint (for forwarding to on-premises DNS)
resource "aws_route53_resolver_endpoint" "outbound" {
  count     = var.enable_vpn && var.onprem_dns_ip != "" ? 1 : 0
  name      = "${var.project_name}-${var.environment}-resolver-outbound"
  direction = "OUTBOUND"

  security_group_ids = [aws_security_group.route53_resolver[0].id]

  ip_address {
    subnet_id = aws_subnet.private[0].id
  }

  ip_address {
    subnet_id = aws_subnet.private[1].id
  }

  tags = {
    Name        = "${var.project_name}-${var.environment}-resolver-outbound"
    Environment = var.environment
    Project     = var.project_name
  }
}

# Security Group for Route53 Resolver
resource "aws_security_group" "route53_resolver" {
  count       = var.enable_vpn && var.onprem_dns_ip != "" ? 1 : 0
  name_prefix = "${var.project_name}-${var.environment}-resolver-"
  description = "Security group for Route53 Resolver"
  vpc_id      = aws_vpc.main.id

  ingress {
    description = "DNS from VPC"
    from_port   = 53
    to_port     = 53
    protocol    = "tcp"
    cidr_blocks = [var.vpc_cidr]
  }

  ingress {
    description = "DNS from VPC (UDP)"
    from_port   = 53
    to_port     = 53
    protocol    = "udp"
    cidr_blocks = [var.vpc_cidr]
  }

  egress {
    description = "DNS to on-premises"
    from_port   = 53
    to_port     = 53
    protocol    = "tcp"
    cidr_blocks = [var.onprem_cidr]
  }

  egress {
    description = "DNS to on-premises (UDP)"
    from_port   = 53
    to_port     = 53
    protocol    = "udp"
    cidr_blocks = [var.onprem_cidr]
  }

  tags = {
    Name        = "${var.project_name}-${var.environment}-resolver-sg"
    Environment = var.environment
    Project     = var.project_name
  }
}

# Route53 Resolver Rule Association
resource "aws_route53_resolver_rule_association" "onprem" {
  count            = var.enable_vpn && var.onprem_dns_ip != "" ? 1 : 0
  resolver_rule_id = aws_route53_resolver_rule.onprem_dns[0].id
  vpc_id           = aws_vpc.main.id
}

# Outputs
output "route53_zone_id" {
  description = "ID of the private hosted zone"
  value       = aws_route53_zone.private.zone_id
}

output "route53_zone_name" {
  description = "Name of the private hosted zone"
  value       = aws_route53_zone.private.name
}

output "monitoring_dns" {
  description = "DNS name for monitoring service"
  value       = aws_route53_record.monitoring.fqdn
}

output "api_dns" {
  description = "DNS name for internal API"
  value       = aws_route53_record.api.fqdn
}
