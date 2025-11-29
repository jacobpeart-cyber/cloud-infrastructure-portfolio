# Security Groups Module - Main Configuration
# Implements defense-in-depth security model with layered security groups

# ============================================================================
# ALB SECURITY GROUP
# Purpose: Controls traffic to/from Application Load Balancer
# ============================================================================

resource "aws_security_group" "alb" {
  name        = "${var.project_name}-${var.environment}-alb-sg"
  description = "Security group for Application Load Balancer"
  vpc_id      = var.vpc_id

  tags = merge(
    var.tags,
    {
      Name = "${var.project_name}-${var.environment}-alb-sg"
      Tier = "load-balancer"
    }
  )

  lifecycle {
    create_before_destroy = true
  }
}

# ALB Inbound: Allow HTTP from internet (will redirect to HTTPS)
resource "aws_vpc_security_group_ingress_rule" "alb_http" {
  security_group_id = aws_security_group.alb.id
  description       = "Allow HTTP from internet (for redirect to HTTPS)"
  from_port         = 80
  to_port           = 80
  ip_protocol       = "tcp"
  cidr_ipv4         = "0.0.0.0/0"

  tags = {
    Name = "${var.project_name}-${var.environment}-alb-http-ingress"
  }
}

# ALB Inbound: Allow HTTPS from internet
resource "aws_vpc_security_group_ingress_rule" "alb_https" {
  security_group_id = aws_security_group.alb.id
  description       = "Allow HTTPS from internet"
  from_port         = 443
  to_port           = 443
  ip_protocol       = "tcp"
  cidr_ipv4         = "0.0.0.0/0"

  tags = {
    Name = "${var.project_name}-${var.environment}-alb-https-ingress"
  }
}

# ALB Outbound: Allow traffic to application servers
resource "aws_vpc_security_group_egress_rule" "alb_to_app" {
  security_group_id            = aws_security_group.alb.id
  description                  = "Allow traffic to application servers"
  from_port                    = var.app_port
  to_port                      = var.app_port
  ip_protocol                  = "tcp"
  referenced_security_group_id = aws_security_group.application.id

  tags = {
    Name = "${var.project_name}-${var.environment}-alb-to-app-egress"
  }
}

# ============================================================================
# APPLICATION SECURITY GROUP
# Purpose: Controls traffic to/from application servers (EC2 instances)
# ============================================================================

resource "aws_security_group" "application" {
  name        = "${var.project_name}-${var.environment}-app-sg"
  description = "Security group for application servers"
  vpc_id      = var.vpc_id

  tags = merge(
    var.tags,
    {
      Name = "${var.project_name}-${var.environment}-app-sg"
      Tier = "application"
    }
  )

  lifecycle {
    create_before_destroy = true
  }
}

# App Inbound: Allow traffic from ALB
resource "aws_vpc_security_group_ingress_rule" "app_from_alb" {
  security_group_id            = aws_security_group.application.id
  description                  = "Allow traffic from ALB"
  from_port                    = var.app_port
  to_port                      = var.app_port
  ip_protocol                  = "tcp"
  referenced_security_group_id = aws_security_group.alb.id

  tags = {
    Name = "${var.project_name}-${var.environment}-app-from-alb-ingress"
  }
}

# App Inbound: Allow SSH from Management security group
resource "aws_vpc_security_group_ingress_rule" "app_ssh_from_mgmt" {
  security_group_id            = aws_security_group.application.id
  description                  = "Allow SSH from management instances"
  from_port                    = 22
  to_port                      = 22
  ip_protocol                  = "tcp"
  referenced_security_group_id = aws_security_group.management.id

  tags = {
    Name = "${var.project_name}-${var.environment}-app-ssh-from-mgmt-ingress"
  }
}

# App Outbound: Allow traffic to database
resource "aws_vpc_security_group_egress_rule" "app_to_db" {
  security_group_id            = aws_security_group.application.id
  description                  = "Allow traffic to database"
  from_port                    = var.db_port
  to_port                      = var.db_port
  ip_protocol                  = "tcp"
  referenced_security_group_id = aws_security_group.database.id

  tags = {
    Name = "${var.project_name}-${var.environment}-app-to-db-egress"
  }
}

# App Outbound: Allow HTTPS to internet (for external APIs, package updates)
resource "aws_vpc_security_group_egress_rule" "app_https_out" {
  security_group_id = aws_security_group.application.id
  description       = "Allow HTTPS to internet for external APIs"
  from_port         = 443
  to_port           = 443
  ip_protocol       = "tcp"
  cidr_ipv4         = "0.0.0.0/0"

  tags = {
    Name = "${var.project_name}-${var.environment}-app-https-egress"
  }
}

# App Outbound: Allow HTTP to internet (for package updates)
resource "aws_vpc_security_group_egress_rule" "app_http_out" {
  security_group_id = aws_security_group.application.id
  description       = "Allow HTTP to internet for package updates"
  from_port         = 80
  to_port           = 80
  ip_protocol       = "tcp"
  cidr_ipv4         = "0.0.0.0/0"

  tags = {
    Name = "${var.project_name}-${var.environment}-app-http-egress"
  }
}

# App Outbound: Allow traffic to ElastiCache (conditional)
resource "aws_vpc_security_group_egress_rule" "app_to_cache" {
  count = var.create_elasticache_sg ? 1 : 0

  security_group_id            = aws_security_group.application.id
  description                  = "Allow traffic to ElastiCache"
  from_port                    = var.redis_port
  to_port                      = var.redis_port
  ip_protocol                  = "tcp"
  referenced_security_group_id = aws_security_group.elasticache[0].id

  tags = {
    Name = "${var.project_name}-${var.environment}-app-to-cache-egress"
  }
}

# ============================================================================
# DATABASE SECURITY GROUP
# Purpose: Controls traffic to RDS instances (most restrictive)
# ============================================================================

resource "aws_security_group" "database" {
  name        = "${var.project_name}-${var.environment}-db-sg"
  description = "Security group for RDS database instances"
  vpc_id      = var.vpc_id

  tags = merge(
    var.tags,
    {
      Name = "${var.project_name}-${var.environment}-db-sg"
      Tier = "database"
    }
  )

  lifecycle {
    create_before_destroy = true
  }
}

# DB Inbound: Allow traffic from application servers only
resource "aws_vpc_security_group_ingress_rule" "db_from_app" {
  security_group_id            = aws_security_group.database.id
  description                  = "Allow MySQL from application servers"
  from_port                    = var.db_port
  to_port                      = var.db_port
  ip_protocol                  = "tcp"
  referenced_security_group_id = aws_security_group.application.id

  tags = {
    Name = "${var.project_name}-${var.environment}-db-from-app-ingress"
  }
}

# DB Inbound: Allow traffic from management (for DB administration)
resource "aws_vpc_security_group_ingress_rule" "db_from_mgmt" {
  security_group_id            = aws_security_group.database.id
  description                  = "Allow MySQL from management instances for administration"
  from_port                    = var.db_port
  to_port                      = var.db_port
  ip_protocol                  = "tcp"
  referenced_security_group_id = aws_security_group.management.id

  tags = {
    Name = "${var.project_name}-${var.environment}-db-from-mgmt-ingress"
  }
}

# NOTE: Database has NO outbound rules - it should never initiate connections

# ============================================================================
# ELASTICACHE SECURITY GROUP (Optional)
# Purpose: Controls traffic to Redis/ElastiCache clusters
# ============================================================================

resource "aws_security_group" "elasticache" {
  count = var.create_elasticache_sg ? 1 : 0

  name        = "${var.project_name}-${var.environment}-cache-sg"
  description = "Security group for ElastiCache Redis cluster"
  vpc_id      = var.vpc_id

  tags = merge(
    var.tags,
    {
      Name = "${var.project_name}-${var.environment}-cache-sg"
      Tier = "cache"
    }
  )

  lifecycle {
    create_before_destroy = true
  }
}

# Cache Inbound: Allow traffic from application servers only
resource "aws_vpc_security_group_ingress_rule" "cache_from_app" {
  count = var.create_elasticache_sg ? 1 : 0

  security_group_id            = aws_security_group.elasticache[0].id
  description                  = "Allow Redis from application servers"
  from_port                    = var.redis_port
  to_port                      = var.redis_port
  ip_protocol                  = "tcp"
  referenced_security_group_id = aws_security_group.application.id

  tags = {
    Name = "${var.project_name}-${var.environment}-cache-from-app-ingress"
  }
}

# ============================================================================
# MANAGEMENT SECURITY GROUP
# Purpose: Controls traffic to bastion hosts and management instances
# ============================================================================

resource "aws_security_group" "management" {
  name        = "${var.project_name}-${var.environment}-mgmt-sg"
  description = "Security group for management/bastion instances"
  vpc_id      = var.vpc_id

  tags = merge(
    var.tags,
    {
      Name = "${var.project_name}-${var.environment}-mgmt-sg"
      Tier = "management"
    }
  )

  lifecycle {
    create_before_destroy = true
  }
}

# Mgmt Inbound: Allow SSH from specific IPs (your IP or corporate network)
resource "aws_vpc_security_group_ingress_rule" "mgmt_ssh" {
  for_each = toset(var.allowed_ssh_cidrs)

  security_group_id = aws_security_group.management.id
  description       = "Allow SSH from ${each.value}"
  from_port         = 22
  to_port           = 22
  ip_protocol       = "tcp"
  cidr_ipv4         = each.value

  tags = {
    Name = "${var.project_name}-${var.environment}-mgmt-ssh-ingress"
  }
}

# Mgmt Inbound: Allow HTTPS from specific IPs (for web-based tools)
resource "aws_vpc_security_group_ingress_rule" "mgmt_https" {
  for_each = toset(var.allowed_https_cidrs)

  security_group_id = aws_security_group.management.id
  description       = "Allow HTTPS from ${each.value}"
  from_port         = 443
  to_port           = 443
  ip_protocol       = "tcp"
  cidr_ipv4         = each.value

  tags = {
    Name = "${var.project_name}-${var.environment}-mgmt-https-ingress"
  }
}

# Mgmt Outbound: Allow SSH to application servers
resource "aws_vpc_security_group_egress_rule" "mgmt_to_app_ssh" {
  security_group_id            = aws_security_group.management.id
  description                  = "Allow SSH to application servers"
  from_port                    = 22
  to_port                      = 22
  ip_protocol                  = "tcp"
  referenced_security_group_id = aws_security_group.application.id

  tags = {
    Name = "${var.project_name}-${var.environment}-mgmt-to-app-ssh-egress"
  }
}

# Mgmt Outbound: Allow MySQL to database (for administration)
resource "aws_vpc_security_group_egress_rule" "mgmt_to_db" {
  security_group_id            = aws_security_group.management.id
  description                  = "Allow MySQL to database for administration"
  from_port                    = var.db_port
  to_port                      = var.db_port
  ip_protocol                  = "tcp"
  referenced_security_group_id = aws_security_group.database.id

  tags = {
    Name = "${var.project_name}-${var.environment}-mgmt-to-db-egress"
  }
}

# Mgmt Outbound: Allow HTTPS to internet (for updates, AWS APIs)
resource "aws_vpc_security_group_egress_rule" "mgmt_https_out" {
  security_group_id = aws_security_group.management.id
  description       = "Allow HTTPS to internet"
  from_port         = 443
  to_port           = 443
  ip_protocol       = "tcp"
  cidr_ipv4         = "0.0.0.0/0"

  tags = {
    Name = "${var.project_name}-${var.environment}-mgmt-https-egress"
  }
}

# Mgmt Outbound: Allow HTTP to internet (for package updates)
resource "aws_vpc_security_group_egress_rule" "mgmt_http_out" {
  security_group_id = aws_security_group.management.id
  description       = "Allow HTTP to internet"
  from_port         = 80
  to_port           = 80
  ip_protocol       = "tcp"
  cidr_ipv4         = "0.0.0.0/0"

  tags = {
    Name = "${var.project_name}-${var.environment}-mgmt-http-egress"
  }
}
