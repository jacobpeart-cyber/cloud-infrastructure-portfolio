variable "aws_region" {
  description = "AWS region for resources"
  type        = string
  default     = "us-east-1"
}

variable "owner_email" {
  description = "Email of the infrastructure owner"
  type        = string
  default     = "jacobspeart@gmail.com"
}

variable "project_name" {
  description = "Name of the project"
  type        = string
  default     = "cloud-portfolio"
}

variable "environment" {
  description = "Environment name"
  type        = string
  default     = "dev"
}

# Security Group Configuration
variable "allowed_ssh_cidrs" {
  description = "CIDR blocks allowed to SSH (your IP address)"
  type        = list(string)
  default     = []
}

variable "app_port" {
  description = "Application server port"
  type        = number
  default     = 8080
}

variable "db_port" {
  description = "Database port"
  type        = number
  default     = 3306
}

variable "redis_port" {
  description = "Redis/ElastiCache port"
  type        = number
  default     = 6379
}

variable "create_elasticache_sg" {
  description = "Create ElastiCache security group"
  type        = bool
  default     = true
}
