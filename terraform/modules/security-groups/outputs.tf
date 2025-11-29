# Security Groups Module - Outputs

# ALB Security Group
output "alb_security_group_id" {
  description = "ID of the ALB security group"
  value       = aws_security_group.alb.id
}

output "alb_security_group_arn" {
  description = "ARN of the ALB security group"
  value       = aws_security_group.alb.arn
}

output "alb_security_group_name" {
  description = "Name of the ALB security group"
  value       = aws_security_group.alb.name
}

# Application Security Group
output "application_security_group_id" {
  description = "ID of the application security group"
  value       = aws_security_group.application.id
}

output "application_security_group_arn" {
  description = "ARN of the application security group"
  value       = aws_security_group.application.arn
}

output "application_security_group_name" {
  description = "Name of the application security group"
  value       = aws_security_group.application.name
}

# Database Security Group
output "database_security_group_id" {
  description = "ID of the database security group"
  value       = aws_security_group.database.id
}

output "database_security_group_arn" {
  description = "ARN of the database security group"
  value       = aws_security_group.database.arn
}

output "database_security_group_name" {
  description = "Name of the database security group"
  value       = aws_security_group.database.name
}

# ElastiCache Security Group (conditional)
output "elasticache_security_group_id" {
  description = "ID of the ElastiCache security group"
  value       = var.create_elasticache_sg ? aws_security_group.elasticache[0].id : null
}

output "elasticache_security_group_arn" {
  description = "ARN of the ElastiCache security group"
  value       = var.create_elasticache_sg ? aws_security_group.elasticache[0].arn : null
}

# Management Security Group
output "management_security_group_id" {
  description = "ID of the management security group"
  value       = aws_security_group.management.id
}

output "management_security_group_arn" {
  description = "ARN of the management security group"
  value       = aws_security_group.management.arn
}

output "management_security_group_name" {
  description = "Name of the management security group"
  value       = aws_security_group.management.name
}

# All Security Group IDs (for convenience)
output "all_security_group_ids" {
  description = "Map of all security group IDs"
  value = {
    alb         = aws_security_group.alb.id
    application = aws_security_group.application.id
    database    = aws_security_group.database.id
    elasticache = var.create_elasticache_sg ? aws_security_group.elasticache[0].id : null
    management  = aws_security_group.management.id
  }
}
