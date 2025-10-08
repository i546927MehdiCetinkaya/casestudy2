# Customer Gateway (On-Premises VPN endpoint - Fontys Netlab)
resource "aws_customer_gateway" "onprem" {
  count = var.enable_vpn ? 1 : 0
  
  bgp_asn    = 65000
  ip_address = var.onprem_public_ip
  type       = "ipsec.1"
  
  tags = {
    Name        = "${var.project_name}-${var.environment}-customer-gateway"
    Environment = var.environment
    Project     = var.project_name
    Description = "Customer Gateway for Fontys Netlab (192.168.154.0/24)"
  }
}

# Virtual Private Gateway
resource "aws_vpn_gateway" "main" {
  count = var.enable_vpn ? 1 : 0
  
  vpc_id = aws_vpc.main.id
  
  tags = {
    Name        = "${var.project_name}-${var.environment}-vpn-gateway"
    Environment = var.environment
    Project     = var.project_name
  }
}

# VPN Gateway Attachment
resource "aws_vpn_gateway_attachment" "main" {
  count = var.enable_vpn ? 1 : 0
  
  vpc_id         = aws_vpc.main.id
  vpn_gateway_id = aws_vpn_gateway.main[0].id
}

# VPN Gateway Route Propagation to Private Subnets
resource "aws_vpn_gateway_route_propagation" "private" {
  count = var.enable_vpn ? length(aws_route_table.private) : 0
  
  vpn_gateway_id = aws_vpn_gateway.main[0].id
  route_table_id = aws_route_table.private[count.index].id
}

# VPN Gateway Route Propagation to Lambda Subnets
resource "aws_vpn_gateway_route_propagation" "lambda" {
  count = var.enable_vpn ? length(aws_route_table.lambda) : 0
  
  vpn_gateway_id = aws_vpn_gateway.main[0].id
  route_table_id = aws_route_table.lambda[count.index].id
}

# Site-to-Site VPN Connection
resource "aws_vpn_connection" "main" {
  count = var.enable_vpn ? 1 : 0
  
  vpn_gateway_id      = aws_vpn_gateway.main[0].id
  customer_gateway_id = aws_customer_gateway.onprem[0].id
  type                = "ipsec.1"
  static_routes_only  = true
  
  # On-premises network (Fontys Netlab)
  local_ipv4_network_cidr  = var.onprem_cidr
  # AWS VPC network
  remote_ipv4_network_cidr = var.vpc_cidr
  
  tags = {
    Name        = "${var.project_name}-${var.environment}-vpn-connection"
    Environment = var.environment
    Project     = var.project_name
  }
}

# Static Route for On-Premises Network (Fontys Netlab)
resource "aws_vpn_connection_route" "onprem" {
  count = var.enable_vpn ? 1 : 0
  
  destination_cidr_block = var.onprem_cidr
  vpn_connection_id      = aws_vpn_connection.main[0].id
}

# Security Group for VPN Traffic - Allow on-premises access
resource "aws_security_group" "vpn" {
  count = var.enable_vpn ? 1 : 0
  
  name_prefix = "${var.project_name}-${var.environment}-vpn-"
  description = "Security group for VPN traffic from on-premises (Fontys Netlab)"
  vpc_id      = aws_vpc.main.id
  
  # Allow ALL traffic from on-premises network (192.168.154.0/24)
  ingress {
    description = "Allow all traffic from on-premises Fontys Netlab"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = [var.onprem_cidr]
  }
  
  egress {
    description = "Allow all outbound traffic to anywhere"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
  
  tags = {
    Name        = "${var.project_name}-${var.environment}-vpn-sg"
    Environment = var.environment
    Project     = var.project_name
    Description = "Allows traffic from Fontys Netlab via VPN"
  }
  
  lifecycle {
    create_before_destroy = true
  }
}

# Output VPN Configuration
output "vpn_connection_id" {
  description = "ID of the VPN connection"
  value       = var.enable_vpn ? aws_vpn_connection.main[0].id : null
}

output "vpn_configuration" {
  description = "VPN configuration for on-premises device (Cisco format)"
  value       = var.enable_vpn ? aws_vpn_connection.main[0].customer_gateway_configuration : null
  sensitive   = true
}

output "vpn_tunnel1_address" {
  description = "Public IP of VPN tunnel 1 (AWS endpoint)"
  value       = var.enable_vpn ? aws_vpn_connection.main[0].tunnel1_address : null
}

output "vpn_tunnel2_address" {
  description = "Public IP of VPN tunnel 2 (AWS endpoint)"
  value       = var.enable_vpn ? aws_vpn_connection.main[0].tunnel2_address : null
}

output "vpn_tunnel1_preshared_key" {
  description = "Pre-shared key for VPN tunnel 1"
  value       = var.enable_vpn ? aws_vpn_connection.main[0].tunnel1_preshared_key : null
  sensitive   = true
}

output "vpn_tunnel2_preshared_key" {
  description = "Pre-shared key for VPN tunnel 2"
  value       = var.enable_vpn ? aws_vpn_connection.main[0].tunnel2_preshared_key : null
  sensitive   = true
}

output "vpn_status" {
  description = "VPN connection status"
  value = var.enable_vpn ? {
    enabled              = true
    onprem_network       = var.onprem_cidr
    onprem_public_ip     = var.onprem_public_ip
    aws_vpc_cidr         = var.vpc_cidr
    tunnel1_address      = aws_vpn_connection.main[0].tunnel1_address
    tunnel2_address      = aws_vpn_connection.main[0].tunnel2_address
    connection_id        = aws_vpn_connection.main[0].id
    customer_gateway_id  = aws_customer_gateway.onprem[0].id
    vpn_gateway_id       = aws_vpn_gateway.main[0].id
  } : {
    enabled = false
    message = "VPN is disabled. Set var.enable_vpn=true and configure onprem_public_ip to enable."
  }
}
