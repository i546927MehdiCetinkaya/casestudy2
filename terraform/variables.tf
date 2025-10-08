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
  default     = "145.93.176.197"  # Fontys Netlab public IP
}

variable "onprem_cidr" {
  description = "CIDR block of on-premises network"
  type        = string
  default     = "192.168.154.0/24"
}

variable "enable_vpn" {
  description = "Enable VPN Site-to-Site connection to on-premises"
  type        = bool
  default     = false  # Disabled by default - enable when Fontys Netlab is configured
}

# On-Premises Webserver Configuration
variable "onprem_webserver_ip" {
  description = "IP address of on-premises webserver"
  type        = string
  default     = "192.168.154.13"
}

variable "onprem_webserver_username" {
  description = "Username for on-premises webserver authentication"
  type        = string
  default     = "admin"
  sensitive   = true
}

variable "onprem_webserver_password" {
  description = "Password for on-premises webserver authentication"
  type        = string
  default     = ""
  sensitive   = true
}

# DNS Configuration
variable "monitoring_service_ip" {
  description = "IP address of monitoring service (Prometheus/Grafana)"
  type        = string
  default     = "10.0.0.100"  # Internal IP, adjust if needed
}

variable "onprem_dns_ip" {
  description = "IP address of on-premises DNS server"
  type        = string
  default     = ""  # Leave empty if not using on-premises DNS
}

variable "onprem_dns_domain" {
  description = "Domain name for on-premises DNS forwarding"
  type        = string
  default     = "fontysict.nl"
}

# Client VPN Configuration
variable "enable_client_vpn" {
  description = "Enable Client VPN for remote access to monitoring"
  type        = bool
  default     = false  # Disabled by default - enable when certificates are configured
}

variable "client_vpn_cidr" {
  description = "CIDR block for Client VPN users"
  type        = string
  default     = "172.16.0.0/22"  # VPN client IP range
}
