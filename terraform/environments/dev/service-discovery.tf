# Service Discovery Private DNS Namespace
resource "aws_service_discovery_private_dns_namespace" "main" {
  name        = "${var.project_name}.local"
  description = "Private DNS namespace for ${var.project_name} service discovery"
  vpc         = module.vpc.vpc_id

  tags = {
    Name = "${var.project_name}-${var.environment}-namespace"
  }
}

# Service Discovery Service for ECS
resource "aws_service_discovery_service" "app" {
  name = "app"

  dns_config {
    namespace_id = aws_service_discovery_private_dns_namespace.main.id

    dns_records {
      ttl  = 10
      type = "A"
    }

    routing_policy = "MULTIVALUE"
  }

  health_check_custom_config {
    failure_threshold = 1
  }

  tags = {
    Name = "${var.project_name}-${var.environment}-service-discovery"
  }
}

# Outputs
output "service_discovery_namespace" {
  description = "Service Discovery namespace"
  value       = aws_service_discovery_private_dns_namespace.main.name
}

output "service_discovery_service_name" {
  description = "Service Discovery service name"
  value       = aws_service_discovery_service.app.name
}

output "service_discovery_arn" {
  description = "Service Discovery service ARN"
  value       = aws_service_discovery_service.app.arn
}
