# GitHub Actions OIDC Integration
# This creates an IAM role that GitHub Actions can assume to deploy infrastructure

# Get current AWS account ID
data "aws_caller_identity" "current" {}

# IAM Role for GitHub Actions
resource "aws_iam_role" "github_actions" {
  name        = "${var.project_name}-github-actions-role"
  description = "Role for GitHub Actions to deploy Terraform infrastructure"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect = "Allow"
      Principal = {
        Federated = "arn:aws:iam::${data.aws_caller_identity.current.account_id}:oidc-provider/token.actions.githubusercontent.com"
      }
      Action = "sts:AssumeRoleWithWebIdentity"
      Condition = {
        StringEquals = {
          "token.actions.githubusercontent.com:aud" = "sts.amazonaws.com"
        }
        StringLike = {
          "token.actions.githubusercontent.com:sub" = "repo:jacobpeart-cyber/cloud-infrastructure-portfolio:*"
        }
      }
    }]
  })

  tags = {
    Name = "${var.project_name}-github-actions-role"
  }
}

# Attach AdministratorAccess policy (use more restrictive policy in production)
resource "aws_iam_role_policy_attachment" "github_actions_admin" {
  role       = aws_iam_role.github_actions.name
  policy_arn = "arn:aws:iam::aws:policy/AdministratorAccess"
}

# Output the role ARN to add to GitHub secrets
output "github_actions_role_arn" {
  value       = aws_iam_role.github_actions.arn
  description = "ARN of the IAM role for GitHub Actions - add this to GitHub secrets as AWS_ROLE_ARN"
}
