# CI/CD Setup Completion Guide

## What Has Been Done

### ✅ 1. AWS OIDC Provider Created

```bash
Provider ARN: arn:aws:iam::298393324887:oidc-provider/token.actions.githubusercontent.com
Status: Active
```

This allows GitHub Actions to authenticate with AWS without storing long-lived credentials.

### ✅ 2. IAM Role for GitHub Actions Created

```bash
Role Name: cloud-portfolio-github-actions-role
Role ARN: arn:aws:iam::298393324887:role/cloud-portfolio-github-actions-role
Permissions: AdministratorAccess
Trust Policy: Configured for repo jacobpeart-cyber/cloud-infrastructure-portfolio
```

### ✅ 3. Terraform Configuration Updated

- File: `terraform/environments/dev/github-actions-role.tf`
- Contains IAM role and policy configuration
- Outputs role ARN for easy reference

### ✅ 4. Setup Scripts Created

- `scripts/setup-github-secret.py` - Automated GitHub API secret setup
- `scripts/add-github-secret.bat` - Windows helper script

## What You Need to Do

### Step 1: Add GitHub Secret (REQUIRED)

The GitHub repository needs the AWS role ARN as a secret:

**Option A: Via Web UI (Easiest)**

1. Go to: https://github.com/jacobpeart-cyber/cloud-infrastructure-portfolio/settings/secrets/actions/new
2. Name: `AWS_ROLE_ARN`
3. Value: `arn:aws:iam::298393324887:role/cloud-portfolio-github-actions-role`
4. Click "Add secret"

**Option B: Via Command Line (if you have GitHub CLI)**

```bash
gh secret set AWS_ROLE_ARN --body "arn:aws:iam::298393324887:role/cloud-portfolio-github-actions-role"
```

**Option C: Via Python Script**

```bash
# You'll need a GitHub Personal Access Token
python scripts/setup-github-secret.py
```

### Step 2: Create Production Environment (OPTIONAL but Recommended)

This adds an approval gate before deploying infrastructure changes:

1. Go to: https://github.com/jacobpeart-cyber/cloud-infrastructure-portfolio/settings/environments/new
2. Name: `production`
3. (Optional) Add protection rules:
   - Required reviewers: Add yourself
   - Wait timer: 5 minutes
   - Deployment branches: Select "Selected branches" → Add "master"
4. Click "Save protection rules"

**Note**: If you skip this step, you need to remove `environment: production` from `.github/workflows/terraform-apply.yml` or the workflow will fail.

## Testing the CI/CD Pipeline

### Test the Plan Workflow (Pull Request)

1. Create a test branch:
   ```bash
   git checkout -b test-cicd
   ```

2. Make a small change (e.g., add a comment to a Terraform file):
   ```bash
   echo "# Test CI/CD" >> terraform/environments/dev/main.tf
   git add terraform/environments/dev/main.tf
   git commit -m "Test CI/CD pipeline"
   ```

3. Push and create a pull request:
   ```bash
   git push origin test-cicd
   ```

4. Go to GitHub and create a PR from `test-cicd` to `master`

5. Check the PR - you should see:
   - ✓ Terraform Format check
   - ✓ Terraform Init
   - ✓ Terraform Validate
   - ✓ Terraform Plan (with plan output as comment)

### Test the Apply Workflow (Production Deployment)

1. Merge the pull request on GitHub

2. Go to Actions tab: https://github.com/jacobpeart-cyber/cloud-infrastructure-portfolio/actions

3. Watch the "Terraform Apply" workflow run:
   - If you set up the production environment with approvals, you'll need to approve it
   - The workflow will run `terraform apply -auto-approve`
   - Outputs will be uploaded as artifacts

## Workflow Files

### Terraform Plan (`.github/workflows/terraform-plan.yml`)

**Trigger**: Pull requests to master with Terraform changes

**Actions**:
- Format check
- Initialize Terraform
- Validate configuration
- Generate plan
- Post plan as PR comment

### Terraform Apply (`.github/workflows/terraform-apply.yml`)

**Trigger**: Push to master branch with Terraform changes

**Actions**:
- Initialize Terraform
- Apply infrastructure changes
- Upload outputs as artifacts

**Environment**: production (requires manual approval if configured)

## Current Infrastructure

All infrastructure is deployed and operational:

### Core Infrastructure (Weeks 1-5)
- ✓ VPC with public/private subnets
- ✓ Security Groups (5 types)
- ✓ EC2 Auto Scaling Group (2-4 instances)
- ✓ Application Load Balancer
- ✓ RDS MySQL database
- ✓ S3 bucket for static content
- ✓ CloudFront CDN
- ✓ CloudWatch monitoring

### Optional Enhancements
- ✓ AWS WAF with 5 security rules
- ✓ Lambda@Edge for security headers
- ✓ ElastiCache Redis cluster
- ✓ VPC Flow Logs with metric filters
- ✓ Systems Manager (Parameter Store + Session Manager)
- ✓ API Gateway REST API
- ✓ ECS Fargate cluster and service
- ✓ GitHub Actions CI/CD (pending secret configuration)

## Troubleshooting

### Error: "failed to assume role"

**Cause**: AWS_ROLE_ARN secret not set

**Solution**: Complete Step 1 above to add the secret

### Error: "production environment not found"

**Cause**: GitHub environment not configured

**Solution**: Either:
- Create the environment (Step 2 above), OR
- Remove `environment: production` from terraform-apply.yml

### Workflow doesn't trigger

**Cause**: No Terraform file changes

**Solution**: Workflows only run when files in `terraform/**` are modified

### Permission denied errors in workflow

**Cause**: IAM role lacks necessary permissions

**Solution**: Role has AdministratorAccess, but you can create a more restrictive policy if needed

## Security Considerations

### Current Setup

- ✓ OIDC authentication (no long-lived credentials)
- ✓ Role scoped to specific repository
- ⚠ AdministratorAccess policy (convenient but broad)

### Production Recommendations

1. **Replace AdministratorAccess** with a custom policy:
   ```json
   {
     "Version": "2012-10-17",
     "Statement": [
       {
         "Effect": "Allow",
         "Action": [
           "ec2:*",
           "rds:*",
           "s3:*",
           "cloudfront:*",
           "wafv2:*",
           "lambda:*",
           "elasticache:*",
           "ecs:*",
           "apigateway:*",
           "iam:GetRole",
           "iam:PassRole",
           "logs:*",
           "cloudwatch:*",
           "sns:*",
           "secretsmanager:*"
         ],
         "Resource": "*"
       }
     ]
   }
   ```

2. **Add branch protection** to master:
   - Require pull request reviews
   - Require status checks to pass
   - Require conversation resolution

3. **Enable deployment protection** on production environment:
   - Required reviewers
   - Wait timer
   - Restrict to master branch only

## Next Actions Checklist

- [ ] Add `AWS_ROLE_ARN` secret to GitHub repository
- [ ] (Optional) Create `production` environment with approval gates
- [ ] Test plan workflow by creating a PR
- [ ] Test apply workflow by merging PR
- [ ] Review workflow run logs
- [ ] (Optional) Tighten IAM permissions for production use

## Quick Reference

### Important URLs

- **Repository**: https://github.com/jacobpeart-cyber/cloud-infrastructure-portfolio
- **Add Secret**: https://github.com/jacobpeart-cyber/cloud-infrastructure-portfolio/settings/secrets/actions/new
- **Create Environment**: https://github.com/jacobpeart-cyber/cloud-infrastructure-portfolio/settings/environments/new
- **Actions Dashboard**: https://github.com/jacobpeart-cyber/cloud-infrastructure-portfolio/actions

### Important Values

```bash
# AWS Role ARN (for GitHub secret)
arn:aws:iam::298393324887:role/cloud-portfolio-github-actions-role

# Secret Name
AWS_ROLE_ARN

# Environment Name
production

# Repository
jacobpeart-cyber/cloud-infrastructure-portfolio
```

## Success Criteria

Your CI/CD is fully operational when:

✓ GitHub secret `AWS_ROLE_ARN` is configured
✓ A test PR triggers the plan workflow successfully
✓ Merging the PR triggers the apply workflow
✓ Infrastructure changes deploy without errors
✓ Workflow outputs are accessible as artifacts

---

**Last Updated**: 2025-11-28
**Infrastructure Version**: All optional enhancements deployed
**Total AWS Services**: 25+
**Estimated Monthly Cost**: ~$30-40 (with free tier) / ~$120 (without)
