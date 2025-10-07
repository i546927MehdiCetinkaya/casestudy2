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
