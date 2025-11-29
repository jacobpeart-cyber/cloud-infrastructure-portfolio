# Systems Manager Parameter Store for application configuration
resource "aws_ssm_parameter" "redis_endpoint" {
  name        = "/${var.project_name}/${var.environment}/redis/endpoint"
  description = "ElastiCache Redis endpoint"
  type        = "String"
  value       = aws_elasticache_cluster.main.cache_nodes[0].address

  tags = {
    Name = "${var.project_name}-${var.environment}-redis-endpoint"
  }
}

resource "aws_ssm_parameter" "database_endpoint" {
  name        = "/${var.project_name}/${var.environment}/database/endpoint"
  description = "RDS database endpoint"
  type        = "String"
  value       = aws_db_instance.main.endpoint

  tags = {
    Name = "${var.project_name}-${var.environment}-db-endpoint"
  }
}

resource "aws_ssm_parameter" "s3_bucket" {
  name        = "/${var.project_name}/${var.environment}/s3/bucket"
  description = "S3 bucket name"
  type        = "String"
  value       = aws_s3_bucket.static_content.id

  tags = {
    Name = "${var.project_name}-${var.environment}-s3-bucket"
  }
}

# Additional Parameter Store entries for Week 6
resource "aws_ssm_parameter" "cloudfront_distribution" {
  name        = "/${var.project_name}/${var.environment}/cloudfront/distribution_id"
  description = "CloudFront distribution ID"
  type        = "String"
  value       = aws_cloudfront_distribution.main.id

  tags = {
    Name = "${var.project_name}-${var.environment}-cloudfront-distribution"
  }
}

resource "aws_ssm_parameter" "cloudfront_domain" {
  name        = "/${var.project_name}/${var.environment}/cloudfront/domain"
  description = "CloudFront distribution domain name"
  type        = "String"
  value       = aws_cloudfront_distribution.main.domain_name

  tags = {
    Name = "${var.project_name}-${var.environment}-cloudfront-domain"
  }
}

resource "aws_ssm_parameter" "alb_dns" {
  name        = "/${var.project_name}/${var.environment}/alb/dns_name"
  description = "Application Load Balancer DNS name"
  type        = "String"
  value       = aws_lb.main.dns_name

  tags = {
    Name = "${var.project_name}-${var.environment}-alb-dns"
  }
}

resource "aws_ssm_parameter" "lambda_function_url" {
  name        = "/${var.project_name}/${var.environment}/lambda/api_processor_url"
  description = "Lambda API processor function URL"
  type        = "String"
  value       = aws_lambda_function_url.api_processor.function_url

  tags = {
    Name = "${var.project_name}-${var.environment}-lambda-url"
  }
}

resource "aws_ssm_parameter" "api_gateway_url" {
  name        = "/${var.project_name}/${var.environment}/api_gateway/url"
  description = "API Gateway invoke URL"
  type        = "String"
  value       = aws_api_gateway_stage.main.invoke_url

  tags = {
    Name = "${var.project_name}-${var.environment}-api-gateway-url"
  }
}

resource "aws_ssm_parameter" "backup_vault" {
  name        = "/${var.project_name}/${var.environment}/backup/vault_name"
  description = "AWS Backup vault name"
  type        = "String"
  value       = aws_backup_vault.main.name

  tags = {
    Name = "${var.project_name}-${var.environment}-backup-vault"
  }
}

resource "aws_ssm_parameter" "ecs_cluster" {
  name        = "/${var.project_name}/${var.environment}/ecs/cluster_name"
  description = "ECS cluster name"
  type        = "String"
  value       = aws_ecs_cluster.main.name

  tags = {
    Name = "${var.project_name}-${var.environment}-ecs-cluster"
  }
}

# Systems Manager Session Manager logging
resource "aws_s3_bucket" "session_logs" {
  bucket = "${var.project_name}-${var.environment}-session-logs-${random_string.bucket_suffix.result}"

  tags = {
    Name = "${var.project_name}-${var.environment}-session-logs"
  }
}

resource "aws_s3_bucket_versioning" "session_logs" {
  bucket = aws_s3_bucket.session_logs.id

  versioning_configuration {
    status = "Enabled"
  }
}

resource "aws_s3_bucket_server_side_encryption_configuration" "session_logs" {
  bucket = aws_s3_bucket.session_logs.id

  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
  }
}

resource "aws_s3_bucket_public_access_block" "session_logs" {
  bucket = aws_s3_bucket.session_logs.id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

# SSM Document for Session Manager logging
resource "aws_ssm_document" "session_manager_prefs" {
  name            = "${var.project_name}-${var.environment}-session-manager-prefs"
  document_type   = "Session"
  document_format = "JSON"

  content = jsonencode({
    schemaVersion = "1.0"
    description   = "Document to configure session logging"
    sessionType   = "Standard_Stream"
    inputs = {
      s3BucketName                = aws_s3_bucket.session_logs.id
      s3KeyPrefix                 = "session-logs/"
      s3EncryptionEnabled         = true
      cloudWatchLogGroupName      = aws_cloudwatch_log_group.session_logs.name
      cloudWatchEncryptionEnabled = true
      cloudWatchStreamingEnabled  = true
    }
  })

  tags = {
    Name = "${var.project_name}-${var.environment}-session-manager-prefs"
  }
}

# CloudWatch Log Group for Session Manager
resource "aws_cloudwatch_log_group" "session_logs" {
  name              = "/aws/ssm/${var.project_name}-${var.environment}-session-logs"
  retention_in_days = 30

  tags = {
    Name = "${var.project_name}-${var.environment}-session-logs"
  }
}

# Update IAM role to include Session Manager permissions (already has SSM policy attached)
# The SSM policy from iam.tf already includes session manager permissions
