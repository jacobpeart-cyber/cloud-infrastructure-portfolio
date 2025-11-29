# X-Ray Sampling Rule
resource "aws_xray_sampling_rule" "main" {
  rule_name      = "${var.project_name}-${var.environment}-sampling"
  priority       = 1000
  version        = 1
  reservoir_size = 1
  fixed_rate     = 0.1 # 10% of requests
  url_path       = "*"
  host           = "*"
  http_method    = "*"
  service_type   = "*"
  service_name   = "*"
  resource_arn   = "*"

  attributes = {
    Project     = var.project_name
    Environment = var.environment
  }

  tags = {
    Name = "${var.project_name}-${var.environment}-xray-sampling"
  }
}

# X-Ray Group for filtering traces
resource "aws_xray_group" "main" {
  group_name        = "${var.project_name}-${var.environment}"
  filter_expression = "service(\"${var.project_name}-app\") OR annotation.project = \"${var.project_name}\""

  insights_configuration {
    insights_enabled      = true
    notifications_enabled = false
  }

  tags = {
    Name = "${var.project_name}-${var.environment}-xray-group"
  }
}

# Output X-Ray URLs
output "xray_traces_url" {
  description = "X-Ray Traces Console URL"
  value       = "https://console.aws.amazon.com/xray/home?region=us-east-1#/traces"
}

output "xray_service_map_url" {
  description = "X-Ray Service Map Console URL"
  value       = "https://console.aws.amazon.com/xray/home?region=us-east-1#/service-map"
}

output "xray_group_name" {
  description = "X-Ray Group Name"
  value       = aws_xray_group.main.group_name
}
