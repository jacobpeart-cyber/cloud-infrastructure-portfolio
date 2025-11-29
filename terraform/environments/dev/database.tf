# Create parameter group for custom settings
resource "aws_db_parameter_group" "main" {
  name   = "${var.project_name}-${var.environment}-mysql-params"
  family = "mysql8.0"

  parameter {
    name  = "character_set_server"
    value = "utf8mb4"
  }

  parameter {
    name  = "collation_server"
    value = "utf8mb4_unicode_ci"
  }

  parameter {
    name  = "max_connections"
    value = "150"
  }

  tags = {
    Name = "${var.project_name}-${var.environment}-mysql-params"
  }
}

# RDS MySQL Database
resource "aws_db_instance" "main" {
  identifier = "${var.project_name}-${var.environment}-mysql"

  # Engine
  engine               = "mysql"
  engine_version       = "8.0"
  instance_class       = "db.t3.micro" # Free tier eligible!
  parameter_group_name = aws_db_parameter_group.main.name

  # Storage
  allocated_storage     = 20
  max_allocated_storage = 100
  storage_type          = "gp3"
  storage_encrypted     = true

  # Credentials
  db_name  = "cloudportfolio"
  username = "admin"
  password = random_password.db_password.result

  # Network
  db_subnet_group_name   = module.vpc.db_subnet_group_name
  vpc_security_group_ids = [module.security_groups.database_security_group_id]
  publicly_accessible    = false

  # High Availability
  multi_az = false # Set to true for production (costs more)

  # Backup
  backup_retention_period = 7
  backup_window           = "03:00-04:00"
  maintenance_window      = "sun:04:00-sun:05:00"

  # Performance Insights (not available for db.t3.micro)
  performance_insights_enabled = false

  # Other settings
  skip_final_snapshot = true  # For dev only!
  deletion_protection = false # For dev only!
  apply_immediately   = true

  tags = {
    Name          = "${var.project_name}-${var.environment}-mysql"
    BackupEnabled = "true"
  }
}
