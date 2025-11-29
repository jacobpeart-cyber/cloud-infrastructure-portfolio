# Lambda@Edge for Security Headers
# Must be created in us-east-1 for CloudFront

# IAM Role for Lambda@Edge
resource "aws_iam_role" "lambda_edge" {
  provider = aws.us-east-1
  name     = "${var.project_name}-${var.environment}-lambda-edge-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = [
            "lambda.amazonaws.com",
            "edgelambda.amazonaws.com"
          ]
        }
      }
    ]
  })

  tags = {
    Name = "${var.project_name}-${var.environment}-lambda-edge-role"
  }
}

# Attach basic Lambda execution policy
resource "aws_iam_role_policy_attachment" "lambda_edge_basic" {
  provider   = aws.us-east-1
  role       = aws_iam_role.lambda_edge.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSLambdaBasicExecutionRole"
}

# Archive Lambda function
data "archive_file" "security_headers" {
  type        = "zip"
  source_file = "${path.root}/../../../lambda/security-headers.js"
  output_path = "${path.root}/../../../lambda/security-headers.zip"
}

# Lambda Function for Security Headers
resource "aws_lambda_function" "security_headers" {
  provider         = aws.us-east-1
  filename         = data.archive_file.security_headers.output_path
  function_name    = "${var.project_name}-${var.environment}-security-headers"
  role             = aws_iam_role.lambda_edge.arn
  handler          = "security-headers.handler"
  source_code_hash = data.archive_file.security_headers.output_base64sha256
  runtime          = "nodejs18.x"
  publish          = true # Required for Lambda@Edge
  timeout          = 5

  tags = {
    Name = "${var.project_name}-${var.environment}-security-headers"
  }
}
