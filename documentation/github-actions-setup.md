# GitHub Actions Setup Guide

This guide explains how to configure GitHub Actions to automatically deploy your Terraform infrastructure.

## Prerequisites

Your AWS infrastructure is already deployed manually via Terraform. GitHub Actions will handle future deployments automatically when you push changes.

## Configuration Required

### 1. AWS OIDC Provider Setup (One-time)

GitHub Actions uses OpenID Connect (OIDC) to authenticate with AWS without storing long-lived credentials.

#### Create OIDC Provider in AWS

```bash
# Using AWS CLI
aws iam create-open-id-connect-provider \
  --url https://token.actions.githubusercontent.com \
  --client-id-list sts.amazonaws.com \
  --thumbprint-list 6938fd4d98bab03faadb97b34396831e3780aea1
```

Or via AWS Console:
1. Go to IAM → Identity providers → Add provider
2. Provider type: OpenID Connect
3. Provider URL: `https://token.actions.githubusercontent.com`
4. Audience: `sts.amazonaws.com`

### 2. Create IAM Role for GitHub Actions

Create an IAM role that GitHub Actions can assume:

```hcl
# Save this as terraform/github-actions-role.tf

resource "aws_iam_role" "github_actions" {
  name = "GitHubActionsRole"

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
          "token.actions.githubusercontent.com:sub" = "repo:YOUR_GITHUB_USERNAME/cloud-infrastructure-portfolio:*"
        }
      }
    }]
  })
}

resource "aws_iam_role_policy_attachment" "github_actions_admin" {
  role       = aws_iam_role.github_actions.name
  policy_arn = "arn:aws:iam::aws:policy/AdministratorAccess"
}

data "aws_caller_identity" "current" {}

output "github_actions_role_arn" {
  value       = aws_iam_role.github_actions.arn
  description = "ARN of the IAM role for GitHub Actions - add this to GitHub secrets as AWS_ROLE_ARN"
}
```

**Important**: Replace `YOUR_GITHUB_USERNAME` with your actual GitHub username.

### 3. Configure GitHub Repository Secrets

1. Go to your GitHub repository
2. Navigate to Settings → Secrets and variables → Actions
3. Click "New repository secret"
4. Add the following secret:
   - **Name**: `AWS_ROLE_ARN`
   - **Value**: The role ARN from the Terraform output (format: `arn:aws:iam::123456789012:role/GitHubActionsRole`)

### 4. Create GitHub Environment (Optional but Recommended)

For the `terraform-apply` workflow, create a "production" environment:

1. Go to Settings → Environments
2. Click "New environment"
3. Name: `production`
4. (Optional) Add protection rules:
   - Required reviewers: Add yourself
   - Wait timer: 5 minutes
   - Deployment branches: Only `master`

This adds an approval gate before applying infrastructure changes.

## Workflow Behavior

### Terraform Plan (Pull Requests)

**Trigger**: When you create a pull request with Terraform changes

**Actions**:
- Runs `terraform fmt` check
- Runs `terraform init`
- Runs `terraform validate`
- Runs `terraform plan`
- Posts plan output as a PR comment

### Terraform Apply (Master Branch)

**Trigger**: When you push to the `master` branch

**Actions**:
- Runs `terraform init`
- Runs `terraform apply -auto-approve`
- Generates `terraform output` JSON
- Uploads outputs as artifacts

## Troubleshooting

### Error: "failed to assume role"

**Cause**: AWS_ROLE_ARN secret not set or OIDC provider not configured

**Solution**:
1. Verify OIDC provider exists in AWS IAM
2. Verify GitHub secret `AWS_ROLE_ARN` is set correctly
3. Check that the IAM role trust policy includes your repository name

### Error: "Error loading state"

**Cause**: Terraform state is local, not shared

**Solution**: Configure remote state backend (S3 + DynamoDB) - see below

### Error: "production environment not found"

**Cause**: GitHub environment not configured

**Solution**: Either create the "production" environment or remove `environment: production` from terraform-apply.yml

## Remote State Backend (Recommended)

For team collaboration and CI/CD, store Terraform state in S3:

```hcl
# Add to terraform/environments/dev/main.tf

terraform {
  backend "s3" {
    bucket         = "cloud-portfolio-terraform-state"
    key            = "dev/terraform.tfstate"
    region         = "us-east-1"
    encrypt        = true
    dynamodb_table = "terraform-state-lock"
  }
}
```

Create the S3 bucket and DynamoDB table:

```bash
# Create S3 bucket for state
aws s3 mb s3://cloud-portfolio-terraform-state --region us-east-1
aws s3api put-bucket-versioning \
  --bucket cloud-portfolio-terraform-state \
  --versioning-configuration Status=Enabled

# Create DynamoDB table for state locking
aws dynamodb create-table \
  --table-name terraform-state-lock \
  --attribute-definitions AttributeName=LockID,AttributeType=S \
  --key-schema AttributeName=LockID,KeyType=HASH \
  --billing-mode PAY_PER_REQUEST \
  --region us-east-1
```

Then migrate existing state:

```bash
cd terraform/environments/dev
terraform init -migrate-state
```

## Testing the Workflows

### Test Plan Workflow

1. Create a test branch: `git checkout -b test-workflows`
2. Make a small change to any Terraform file
3. Commit and push: `git push origin test-workflows`
4. Create a pull request on GitHub
5. Check the PR for the plan comment

### Test Apply Workflow

1. Merge the pull request to master
2. Go to Actions tab in GitHub
3. Watch the "Terraform Apply" workflow run
4. Download the outputs artifact to see the results

## Current Status

✅ Workflows created and committed
❌ AWS OIDC provider not configured
❌ IAM role for GitHub Actions not created
❌ GitHub secrets not configured
❌ GitHub environment not created

## Quick Start (If You Want to Enable CI/CD Now)

1. Create the OIDC provider (see step 1 above)
2. Create `terraform/github-actions-role.tf` with the role definition
3. Apply it: `cd terraform/environments/dev && terraform apply`
4. Copy the `github_actions_role_arn` output
5. Add it as `AWS_ROLE_ARN` secret in GitHub
6. Create the "production" environment (optional)
7. Push a test change to trigger the workflows

## Alternative: Disable CI/CD Temporarily

If you want to keep the workflows but disable them temporarily:

1. Rename the workflow files to `.disabled`:
   ```bash
   mv .github/workflows/terraform-apply.yml .github/workflows/terraform-apply.yml.disabled
   mv .github/workflows/terraform-plan.yml .github/workflows/terraform-plan.yml.disabled
   ```

2. Commit the changes

The workflows won't run but will be preserved for future use.
