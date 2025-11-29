# Lambda Function for API Processing
# This is a regular Lambda function (not Lambda@Edge) for backend API processing

# Get current AWS region
data "aws_region" "current" {}

# IAM Role for Lambda Function
resource "aws_iam_role" "lambda_api_processor" {
  name        = "${var.project_name}-${var.environment}-lambda-api-processor"
  description = "IAM role for Lambda API processor function"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Action = "sts:AssumeRole"
      Effect = "Allow"
      Principal = {
        Service = "lambda.amazonaws.com"
      }
    }]
  })

  tags = {
    Name = "${var.project_name}-${var.environment}-lambda-api-processor"
  }
}

# Attach basic Lambda execution policy
resource "aws_iam_role_policy_attachment" "lambda_api_processor_basic" {
  role       = aws_iam_role.lambda_api_processor.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSLambdaBasicExecutionRole"
}

# Additional policy for accessing VPC resources (if needed)
resource "aws_iam_role_policy" "lambda_api_processor_vpc" {
  name = "${var.project_name}-${var.environment}-lambda-vpc-policy"
  role = aws_iam_role.lambda_api_processor.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "ec2:CreateNetworkInterface",
          "ec2:DescribeNetworkInterfaces",
          "ec2:DeleteNetworkInterface",
          "ec2:AssignPrivateIpAddresses",
          "ec2:UnassignPrivateIpAddresses"
        ]
        Resource = "*"
      },
      {
        Effect = "Allow"
        Action = [
          "ssm:GetParameter",
          "ssm:GetParameters"
        ]
        Resource = "arn:aws:ssm:${data.aws_region.current.name}:${data.aws_caller_identity.current.account_id}:parameter/${var.project_name}/*"
      }
    ]
  })
}

# CloudWatch Log Group for Lambda
resource "aws_cloudwatch_log_group" "lambda_api_processor" {
  name              = "/aws/lambda/${var.project_name}-${var.environment}-api-processor"
  retention_in_days = 14

  tags = {
    Name = "${var.project_name}-${var.environment}-lambda-api-processor-logs"
  }
}

# Package Lambda function code
data "archive_file" "lambda_api_processor" {
  type        = "zip"
  source_file = "${path.module}/../../../lambda/api-processor.js"
  output_path = "${path.module}/../../../lambda/api-processor.zip"
}

# Lambda Function
resource "aws_lambda_function" "api_processor" {
  filename         = data.archive_file.lambda_api_processor.output_path
  function_name    = "${var.project_name}-${var.environment}-api-processor"
  role             = aws_iam_role.lambda_api_processor.arn
  handler          = "api-processor.handler"
  runtime          = "nodejs18.x"
  timeout          = 30
  memory_size      = 512
  source_code_hash = data.archive_file.lambda_api_processor.output_base64sha256

  environment {
    variables = {
      ENVIRONMENT    = var.environment
      PROJECT_NAME   = var.project_name
      S3_BUCKET      = aws_s3_bucket.static_content.id
      RDS_ENDPOINT   = aws_db_instance.main.endpoint
      REDIS_ENDPOINT = aws_elasticache_cluster.main.cache_nodes[0].address
    }
  }

  # VPC Configuration (optional - uncomment if Lambda needs VPC access)
  # vpc_config {
  #   subnet_ids         = module.vpc.private_subnet_ids
  #   security_group_ids = [aws_security_group.lambda.id]
  # }

  tags = {
    Name = "${var.project_name}-${var.environment}-api-processor"
  }

  depends_on = [
    aws_iam_role_policy_attachment.lambda_api_processor_basic,
    aws_cloudwatch_log_group.lambda_api_processor
  ]
}

# Lambda Function URL (for direct HTTPS access)
resource "aws_lambda_function_url" "api_processor" {
  function_name      = aws_lambda_function.api_processor.function_name
  authorization_type = "NONE" # Change to "AWS_IAM" for authenticated access

  cors {
    allow_credentials = true
    allow_origins     = ["*"]
    allow_methods     = ["GET", "POST"]
    allow_headers     = ["content-type", "x-api-key"]
    max_age           = 86400
  }
}

# CloudWatch Alarm for Lambda Errors
resource "aws_cloudwatch_metric_alarm" "lambda_errors" {
  alarm_name          = "${var.project_name}-${var.environment}-lambda-errors"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = "2"
  metric_name         = "Errors"
  namespace           = "AWS/Lambda"
  period              = "300"
  statistic           = "Sum"
  threshold           = "5"
  alarm_description   = "This metric monitors Lambda function errors"
  alarm_actions       = [aws_sns_topic.alarms.arn]

  dimensions = {
    FunctionName = aws_lambda_function.api_processor.function_name
  }
}

# CloudWatch Alarm for Lambda Duration
resource "aws_cloudwatch_metric_alarm" "lambda_duration" {
  alarm_name          = "${var.project_name}-${var.environment}-lambda-duration"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = "2"
  metric_name         = "Duration"
  namespace           = "AWS/Lambda"
  period              = "300"
  statistic           = "Average"
  threshold           = "25000" # 25 seconds (timeout is 30s)
  alarm_description   = "This metric monitors Lambda function duration"
  alarm_actions       = [aws_sns_topic.alarms.arn]

  dimensions = {
    FunctionName = aws_lambda_function.api_processor.function_name
  }
}

# Output Lambda Function URL
output "lambda_api_processor_url" {
  value       = aws_lambda_function_url.api_processor.function_url
  description = "URL for the Lambda API processor function"
}

output "lambda_api_processor_arn" {
  value       = aws_lambda_function.api_processor.arn
  description = "ARN of the Lambda API processor function"
}
