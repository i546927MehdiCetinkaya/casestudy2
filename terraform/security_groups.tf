# Lambda Security Group
resource "aws_security_group" "lambda" {
  name_prefix = "${var.project_name}-${var.environment}-lambda-sg"
  description = "Security group for Lambda functions"
  vpc_id      = aws_vpc.main.id

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "${var.project_name}-${var.environment}-lambda-sg"
  }
}

# EKS Cluster Security Group
resource "aws_security_group" "eks_cluster" {
  name_prefix = "${var.project_name}-${var.environment}-eks-cluster-sg"
  description = "Security group for EKS cluster"
  vpc_id      = aws_vpc.main.id

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "${var.project_name}-${var.environment}-eks-cluster-sg"
  }
}

# EKS Node Security Group
resource "aws_security_group" "eks_nodes" {
  name_prefix = "${var.project_name}-${var.environment}-eks-nodes-sg"
  description = "Security group for EKS nodes"
  vpc_id      = aws_vpc.main.id

  ingress {
    from_port = 0
    to_port   = 0
    protocol  = "-1"
    self      = true
  }

  ingress {
    from_port       = 443
    to_port         = 443
    protocol        = "tcp"
    security_groups = [aws_security_group.eks_cluster.id]
  }

  ingress {
    from_port       = 1025
    to_port         = 65535
    protocol        = "tcp"
    security_groups = [aws_security_group.eks_cluster.id]
  }

  # Allow access from Client VPN for monitoring
  ingress {
    description = "Grafana from Client VPN"
    from_port   = 3000
    to_port     = 3000
    protocol    = "tcp"
    cidr_blocks = [var.client_vpn_cidr]
  }

  ingress {
    description = "Prometheus from Client VPN"
    from_port   = 9090
    to_port     = 9090
    protocol    = "tcp"
    cidr_blocks = [var.client_vpn_cidr]
  }

  ingress {
    description = "HTTP from Client VPN"
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = [var.client_vpn_cidr]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "${var.project_name}-${var.environment}-eks-nodes-sg"
  }
}

# ALB Security Group (Internal ALB in Private Subnet)
resource "aws_security_group" "alb" {
  name_prefix = "${var.project_name}-${var.environment}-alb-sg"
  description = "Security group for Internal Application Load Balancer"
  vpc_id      = aws_vpc.main.id

  ingress {
    description = "HTTP from VPC"
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = [var.vpc_cidr]
  }

  ingress {
    description = "HTTPS from VPC"
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = [var.vpc_cidr]
  }

  ingress {
    description = "HTTP from Client VPN"
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = [var.client_vpn_cidr]
  }

  ingress {
    description = "HTTPS from Client VPN"
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = [var.client_vpn_cidr]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "${var.project_name}-${var.environment}-alb-sg"
  }
}
