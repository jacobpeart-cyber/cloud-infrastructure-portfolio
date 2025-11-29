# CloudWatch Log Group for VPC Flow Logs
resource "aws_cloudwatch_log_group" "vpc_flow_logs" {
  name              = "/aws/vpc/${var.project_name}-${var.environment}-flow-logs"
  retention_in_days = 30

  tags = {
    Name = "${var.project_name}-${var.environment}-vpc-flow-logs"
  }
}

# IAM Role for VPC Flow Logs
resource "aws_iam_role" "vpc_flow_logs" {
  name = "${var.project_name}-${var.environment}-vpc-flow-logs-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "vpc-flow-logs.amazonaws.com"
        }
      }
    ]
  })

  tags = {
    Name = "${var.project_name}-${var.environment}-vpc-flow-logs-role"
  }
}

# IAM Policy for VPC Flow Logs
resource "aws_iam_role_policy" "vpc_flow_logs" {
  name = "${var.project_name}-${var.environment}-vpc-flow-logs-policy"
  role = aws_iam_role.vpc_flow_logs.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = [
          "logs:CreateLogGroup",
          "logs:CreateLogStream",
          "logs:PutLogEvents",
          "logs:DescribeLogGroups",
          "logs:DescribeLogStreams"
        ]
        Effect   = "Allow"
        Resource = "*"
      }
    ]
  })
}

# VPC Flow Logs
resource "aws_flow_log" "main" {
  iam_role_arn    = aws_iam_role.vpc_flow_logs.arn
  log_destination = aws_cloudwatch_log_group.vpc_flow_logs.arn
  traffic_type    = "ALL"
  vpc_id          = module.vpc.vpc_id

  tags = {
    Name = "${var.project_name}-${var.environment}-flow-logs"
  }
}

# CloudWatch Log Metric Filters for Security Monitoring
resource "aws_cloudwatch_log_metric_filter" "ssh_traffic" {
  name           = "${var.project_name}-${var.environment}-ssh-traffic"
  log_group_name = aws_cloudwatch_log_group.vpc_flow_logs.name
  pattern        = "[version, account, eni, source, destination, srcport, destport=\"22\", protocol=\"6\", packets, bytes, windowstart, windowend, action=\"ACCEPT\", flowlogstatus]"

  metric_transformation {
    name      = "SSHTraffic"
    namespace = "${var.project_name}/${var.environment}/VPCFlowLogs"
    value     = "1"
  }
}

resource "aws_cloudwatch_log_metric_filter" "rejected_traffic" {
  name           = "${var.project_name}-${var.environment}-rejected-traffic"
  log_group_name = aws_cloudwatch_log_group.vpc_flow_logs.name
  pattern        = "[version, account, eni, source, destination, srcport, destport, protocol, packets, bytes, windowstart, windowend, action=\"REJECT\", flowlogstatus]"

  metric_transformation {
    name      = "RejectedTraffic"
    namespace = "${var.project_name}/${var.environment}/VPCFlowLogs"
    value     = "1"
  }
}

# Alarm for high rejected traffic
resource "aws_cloudwatch_metric_alarm" "high_rejected_traffic" {
  alarm_name          = "${var.project_name}-${var.environment}-high-rejected-traffic"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = "2"
  metric_name         = "RejectedTraffic"
  namespace           = "${var.project_name}/${var.environment}/VPCFlowLogs"
  period              = "300"
  statistic           = "Sum"
  threshold           = "100"
  alarm_description   = "High number of rejected network connections"
  alarm_actions       = [aws_sns_topic.alarms.arn]

  tags = {
    Name = "${var.project_name}-${var.environment}-rejected-traffic-alarm"
  }
}
