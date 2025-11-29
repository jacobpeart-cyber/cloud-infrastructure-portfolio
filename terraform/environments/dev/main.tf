terraform {
  required_version = ">= 1.0"
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}

provider "aws" {
  region = var.aws_region

  default_tags {
    tags = {
      Environment = "dev"
      Project     = "cloud-portfolio"
      ManagedBy   = "terraform"
      Owner       = var.owner_email
    }
  }
}

# Provider for us-east-1 (required for CloudFront, WAF, Lambda@Edge)
provider "aws" {
  alias  = "us-east-1"
  region = "us-east-1"

  default_tags {
    tags = {
      Environment = "dev"
      Project     = "cloud-portfolio"
      ManagedBy   = "terraform"
      Owner       = var.owner_email
    }
  }
}

# VPC Module
module "vpc" {
  source = "../../modules/vpc"

  project_name         = var.project_name
  environment          = var.environment
  vpc_cidr             = "10.0.0.0/16"
  public_subnet_cidrs  = ["10.0.1.0/24", "10.0.2.0/24"]
  private_subnet_cidrs = ["10.0.11.0/24", "10.0.12.0/24"]
  availability_zones   = ["us-east-1a", "us-east-1b"]
}

# Security Groups Module
module "security_groups" {
  source = "../../modules/security-groups"

  project_name = var.project_name
  environment  = var.environment
  vpc_id       = module.vpc.vpc_id
  vpc_cidr     = module.vpc.vpc_cidr

  # SSH access - replace with your IP!
  # Find your IP: https://checkip.amazonaws.com
  allowed_ssh_cidrs   = var.allowed_ssh_cidrs
  allowed_https_cidrs = var.allowed_ssh_cidrs

  # Application configuration
  app_port   = var.app_port
  db_port    = var.db_port
  redis_port = var.redis_port

  # ElastiCache security group
  create_elasticache_sg = var.create_elasticache_sg

  tags = {}
}

# CI/CD Pipeline Enabled
# This infrastructure is now automatically deployed via GitHub Actions
# Workflows run on every push to master and pull request

