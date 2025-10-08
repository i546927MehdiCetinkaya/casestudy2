# VPC Configuration
resource "aws_vpc" "main" {
  cidr_block           = var.vpc_cidr
  enable_dns_hostnames = true
  enable_dns_support   = true

  tags = {
    Name = "${var.project_name}-${var.environment}-vpc"
    "kubernetes.io/cluster/${var.project_name}-${var.environment}-eks" = "shared"
  }
}

# Public Subnets
resource "aws_subnet" "public" {
  count                   = 2
  vpc_id                  = aws_vpc.main.id
  cidr_block              = cidrsubnet(var.vpc_cidr, 8, count.index)
  availability_zone       = data.aws_availability_zones.available.names[count.index]
  map_public_ip_on_launch = true

  tags = {
    Name = "${var.project_name}-${var.environment}-public-${count.index + 1}"
    "kubernetes.io/cluster/${var.project_name}-${var.environment}-eks" = "shared"
    "kubernetes.io/role/elb" = "1"
  }
}

# Private Subnets for EKS (AZ A and AZ B)
resource "aws_subnet" "private" {
  count             = 2
  vpc_id            = aws_vpc.main.id
  cidr_block        = cidrsubnet(var.vpc_cidr, 8, count.index + 10)
  availability_zone = data.aws_availability_zones.available.names[count.index]

  tags = {
    Name = "${var.project_name}-${var.environment}-private-${count.index + 1}"
    "kubernetes.io/cluster/${var.project_name}-${var.environment}-eks" = "shared"
    "kubernetes.io/role/internal-elb" = "1"
  }
}

# ALB Private Subnet (AZ A only)
resource "aws_subnet" "alb_private" {
  vpc_id            = aws_vpc.main.id
  cidr_block        = cidrsubnet(var.vpc_cidr, 8, 30)
  availability_zone = data.aws_availability_zones.available.names[0]  # AZ A

  tags = {
    Name = "${var.project_name}-${var.environment}-alb-private-az-a"
  }
}

# Lambda Private Subnet (AZ A only) - 10.0.2.0/24 as per diagram
resource "aws_subnet" "lambda_private" {
  vpc_id            = aws_vpc.main.id
  cidr_block        = cidrsubnet(var.vpc_cidr, 8, 2)  # 10.0.2.0/24
  availability_zone = data.aws_availability_zones.available.names[0]  # AZ A

  tags = {
    Name = "${var.project_name}-${var.environment}-lambda-private-az-a"
  }
}

# Internet Gateway
resource "aws_internet_gateway" "main" {
  vpc_id = aws_vpc.main.id

  tags = {
    Name = "${var.project_name}-${var.environment}-igw"
  }
}

# NAT Gateway
resource "aws_eip" "nat" {
  count  = 2
  domain = "vpc"

  tags = {
    Name = "${var.project_name}-${var.environment}-nat-eip-${count.index + 1}"
  }
}

resource "aws_nat_gateway" "main" {
  count         = 2
  allocation_id = aws_eip.nat[count.index].id
  subnet_id     = aws_subnet.public[count.index].id

  tags = {
    Name = "${var.project_name}-${var.environment}-nat-${count.index + 1}"
  }

  depends_on = [aws_internet_gateway.main]
}

# Route Tables
resource "aws_route_table" "public" {
  vpc_id = aws_vpc.main.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.main.id
  }

  tags = {
    Name = "${var.project_name}-${var.environment}-public-rt"
  }
}

resource "aws_route_table" "private" {
  count  = 2
  vpc_id = aws_vpc.main.id

  route {
    cidr_block     = "0.0.0.0/0"
    nat_gateway_id = aws_nat_gateway.main[count.index].id
  }

  tags = {
    Name = "${var.project_name}-${var.environment}-private-rt-${count.index + 1}"
  }
}

# Route Table for ALB Private Subnet (AZ A)
resource "aws_route_table" "alb_private" {
  vpc_id = aws_vpc.main.id

  route {
    cidr_block     = "0.0.0.0/0"
    nat_gateway_id = aws_nat_gateway.main[0].id  # Use NAT in AZ A
  }

  tags = {
    Name = "${var.project_name}-${var.environment}-alb-private-rt-az-a"
  }
}

# Route Table for Lambda Private Subnet (AZ A)
resource "aws_route_table" "lambda_private" {
  vpc_id = aws_vpc.main.id

  route {
    cidr_block     = "0.0.0.0/0"
    nat_gateway_id = aws_nat_gateway.main[0].id  # Use NAT in AZ A
  }

  tags = {
    Name = "${var.project_name}-${var.environment}-lambda-private-rt-az-a"
  }
}

# Route Table Associations
resource "aws_route_table_association" "public" {
  count          = 2
  subnet_id      = aws_subnet.public[count.index].id
  route_table_id = aws_route_table.public.id
}

resource "aws_route_table_association" "private" {
  count          = 2
  subnet_id      = aws_subnet.private[count.index].id
  route_table_id = aws_route_table.private[count.index].id
}

resource "aws_route_table_association" "alb_private" {
  subnet_id      = aws_subnet.alb_private.id
  route_table_id = aws_route_table.alb_private.id
}

resource "aws_route_table_association" "lambda_private" {
  subnet_id      = aws_subnet.lambda_private.id
  route_table_id = aws_route_table.lambda_private.id
}
