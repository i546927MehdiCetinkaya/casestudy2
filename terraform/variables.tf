variable "aws_region" {
  description = "AWS region"
  type        = string
  default     = "eu-central-1"
}

variable "environment" {
  description = "Environment name"
  type        = string
  default     = "dev"
}

variable "project_name" {
  description = "Project name"
  type        = string
  default     = "casestudy2"
}

variable "vpc_cidr" {
  description = "VPC CIDR block"
  type        = string
  default     = "10.0.0.0/16"
}

variable "github_repo" {
  description = "GitHub repository"
  type        = string
  default     = "i546927MehdiCetinkaya/casestudy2"
}

variable "github_oidc_role_arn" {
  description = "GitHub OIDC IAM Role ARN"
  type        = string
  default     = "arn:aws:iam::920120424621:role/githubrepo"
}

# VPN Configuration
variable "onprem_public_ip" {
  description = "Public IP address of on-premises VPN endpoint (Fontys Netlab)"
  type        = string
  default     = "REPLACE_WITH_YOUR_PUBLIC_IP"  # Get from: curl ifconfig.me or https://whatismyipaddress.com
}

variable "onprem_cidr" {
  description = "CIDR block of on-premises network"
  type        = string
  default     = "192.168.154.0/24"
}

variable "enable_vpn" {
  description = "Enable VPN Site-to-Site connection to on-premises"
  type        = bool
  default     = false  # Set to true after configuring onprem_public_ip
}
