# Security Groups Module - Variables

variable "project_name" {
  description = "Name of the project"
  type        = string
}

variable "environment" {
  description = "Environment name (dev, staging, production)"
  type        = string
}

variable "vpc_id" {
  description = "ID of the VPC where security groups will be created"
  type        = string
}

variable "vpc_cidr" {
  description = "CIDR block of the VPC (used for internal communication rules)"
  type        = string
}

# Application Configuration
variable "app_port" {
  description = "Port the application listens on"
  type        = number
  default     = 8080
}

variable "db_port" {
  description = "Port for database connections"
  type        = number
  default     = 3306
}

variable "redis_port" {
  description = "Port for Redis/ElastiCache connections"
  type        = number
  default     = 6379
}

# Access Control
variable "allowed_ssh_cidrs" {
  description = "CIDR blocks allowed to SSH to management instances (your IP)"
  type        = list(string)
  default     = []
}

variable "allowed_https_cidrs" {
  description = "CIDR blocks allowed HTTPS access to management instances"
  type        = list(string)
  default     = []
}

# Feature Flags
variable "create_elasticache_sg" {
  description = "Create security group for ElastiCache"
  type        = bool
  default     = true
}

variable "tags" {
  description = "Additional tags for all resources"
  type        = map(string)
  default     = {}
}
