# AWS Backup Configuration
# Automated backup plan for RDS and S3

# IAM Role for AWS Backup
resource "aws_iam_role" "backup" {
  name        = "${var.project_name}-${var.environment}-backup-role"
  description = "IAM role for AWS Backup service"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Action = "sts:AssumeRole"
      Effect = "Allow"
      Principal = {
        Service = "backup.amazonaws.com"
      }
    }]
  })

  tags = {
    Name = "${var.project_name}-${var.environment}-backup-role"
  }
}

# Attach AWS managed backup policy
resource "aws_iam_role_policy_attachment" "backup" {
  role       = aws_iam_role.backup.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSBackupServiceRolePolicyForBackup"
}

resource "aws_iam_role_policy_attachment" "backup_restore" {
  role       = aws_iam_role.backup.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSBackupServiceRolePolicyForRestores"
}

# Backup Vault
resource "aws_backup_vault" "main" {
  name = "${var.project_name}-${var.environment}-backup-vault"

  tags = {
    Name = "${var.project_name}-${var.environment}-backup-vault"
  }
}

# Backup Vault Lock Configuration (optional - prevents deletion)
# Uncomment for production to prevent backup deletion
# resource "aws_backup_vault_lock_configuration" "main" {
#   backup_vault_name   = aws_backup_vault.main.name
#   min_retention_days  = 7
#   max_retention_days  = 365
# }

# SNS Topic for Backup Notifications
resource "aws_sns_topic" "backup_notifications" {
  name = "${var.project_name}-${var.environment}-backup-notifications"

  tags = {
    Name = "${var.project_name}-${var.environment}-backup-notifications"
  }
}

resource "aws_sns_topic_subscription" "backup_email" {
  topic_arn = aws_sns_topic.backup_notifications.arn
  protocol  = "email"
  endpoint  = var.owner_email
}

# Backup Plan - Daily backups with 30-day retention
resource "aws_backup_plan" "daily" {
  name = "${var.project_name}-${var.environment}-daily-backup"

  rule {
    rule_name         = "daily_backup_rule"
    target_vault_name = aws_backup_vault.main.name
    schedule          = "cron(0 5 * * ? *)" # Daily at 5 AM UTC

    lifecycle {
      delete_after = 30 # Retain for 30 days
    }

    recovery_point_tags = {
      BackupType = "Automated"
      Frequency  = "Daily"
    }
  }

  # Weekly backup with longer retention
  rule {
    rule_name         = "weekly_backup_rule"
    target_vault_name = aws_backup_vault.main.name
    schedule          = "cron(0 3 ? * SUN *)" # Weekly on Sunday at 3 AM UTC

    lifecycle {
      delete_after = 90 # Retain for 90 days
    }

    recovery_point_tags = {
      BackupType = "Automated"
      Frequency  = "Weekly"
    }
  }

  # Monthly backup with longest retention
  rule {
    rule_name         = "monthly_backup_rule"
    target_vault_name = aws_backup_vault.main.name
    schedule          = "cron(0 2 1 * ? *)" # Monthly on 1st at 2 AM UTC

    lifecycle {
      delete_after = 365 # Retain for 1 year
    }

    recovery_point_tags = {
      BackupType = "Automated"
      Frequency  = "Monthly"
    }
  }

  tags = {
    Name = "${var.project_name}-${var.environment}-daily-backup"
  }
}

# Backup Selection - RDS Database
resource "aws_backup_selection" "rds" {
  name         = "${var.project_name}-${var.environment}-rds-backup"
  plan_id      = aws_backup_plan.daily.id
  iam_role_arn = aws_iam_role.backup.arn

  resources = [
    aws_db_instance.main.arn
  ]

  selection_tag {
    type  = "STRINGEQUALS"
    key   = "BackupEnabled"
    value = "true"
  }
}

# Backup Selection - S3 Buckets
resource "aws_backup_selection" "s3" {
  name         = "${var.project_name}-${var.environment}-s3-backup"
  plan_id      = aws_backup_plan.daily.id
  iam_role_arn = aws_iam_role.backup.arn

  resources = [
    aws_s3_bucket.static_content.arn
  ]

  selection_tag {
    type  = "STRINGEQUALS"
    key   = "BackupEnabled"
    value = "true"
  }
}

# CloudWatch Event Rule for Backup Success
resource "aws_cloudwatch_event_rule" "backup_success" {
  name        = "${var.project_name}-${var.environment}-backup-success"
  description = "Trigger on successful backup completion"

  event_pattern = jsonencode({
    source      = ["aws.backup"]
    detail-type = ["Backup Job State Change"]
    detail = {
      state = ["COMPLETED"]
    }
  })
}

resource "aws_cloudwatch_event_target" "backup_success_sns" {
  rule      = aws_cloudwatch_event_rule.backup_success.name
  target_id = "SendToSNS"
  arn       = aws_sns_topic.backup_notifications.arn
}

# CloudWatch Event Rule for Backup Failure
resource "aws_cloudwatch_event_rule" "backup_failure" {
  name        = "${var.project_name}-${var.environment}-backup-failure"
  description = "Trigger on backup failure"

  event_pattern = jsonencode({
    source      = ["aws.backup"]
    detail-type = ["Backup Job State Change"]
    detail = {
      state = ["FAILED", "ABORTED"]
    }
  })
}

resource "aws_cloudwatch_event_target" "backup_failure_sns" {
  rule      = aws_cloudwatch_event_rule.backup_failure.name
  target_id = "SendToSNS"
  arn       = aws_sns_topic.backup_notifications.arn
}

# SNS Topic Policy to allow CloudWatch Events
resource "aws_sns_topic_policy" "backup_notifications" {
  arn = aws_sns_topic.backup_notifications.arn

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect = "Allow"
      Principal = {
        Service = "events.amazonaws.com"
      }
      Action   = "SNS:Publish"
      Resource = aws_sns_topic.backup_notifications.arn
    }]
  })
}

# Note: Backup tags are managed directly in database.tf and storage.tf
# RDS and S3 resources already have BackupEnabled = "true" tag

# Outputs
output "backup_vault_arn" {
  value       = aws_backup_vault.main.arn
  description = "ARN of the backup vault"
}

output "backup_plan_id" {
  value       = aws_backup_plan.daily.id
  description = "ID of the backup plan"
}

output "backup_vault_name" {
  value       = aws_backup_vault.main.name
  description = "Name of the backup vault"
}
