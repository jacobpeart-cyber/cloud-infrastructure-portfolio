# Cost Optimization & Cleanup Guide

## 💰 Current Cost Breakdown

### Monthly Infrastructure Costs: ~$152/month

```
Service                    Monthly Cost    % of Total   Status
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
NAT Gateways (2x)          $65.00         43%          ALWAYS CHARGING ⚠️
RDS MySQL Multi-AZ         $30.00         20%          ALWAYS CHARGING ⚠️
ECS Fargate (2 tasks)      $25.00         16%          ALWAYS CHARGING ⚠️
ALB                        $22.00         14%          ALWAYS CHARGING ⚠️
ElastiCache Redis          $15.00         10%          ALWAYS CHARGING ⚠️
EC2 (2x t3.micro)          $13.00          9%          ALWAYS CHARGING ⚠️
CloudWatch + Logs           $8.00          5%          Usage-based
S3 + CloudFront             $5.00          3%          Usage-based
Other (SNS, X-Ray, ECR)     $4.00          3%          Minimal
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
TOTAL                     $152.00        100%
```

**⚠️ IMPORTANT**: You ARE being charged real money for these services **even when not using them**. Services marked "ALWAYS CHARGING" run 24/7 and cost money regardless of traffic.

---

## 🎯 Cost Optimization Strategies

### Option 1: Complete Teardown (Recommended for Portfolio)
**Cost: $0/month when destroyed**
**Rebuild Time: ~15 minutes**

Best for: Actively interviewing but not demoing daily

**How it works:**
- Destroy all infrastructure when not needed
- Rebuild quickly when you have an interview
- Keep Terraform code in GitHub (free)
- Screenshots and documentation prove you built it

**Commands:**
```bash
# BEFORE destroying - take screenshots!

# 1. Destroy all infrastructure
cd terraform/environments/dev
terraform destroy -auto-approve

# Cost: $0/month

# When you need to demo (before interview):
terraform apply -auto-approve  # Takes ~15 minutes
```

**Pros:**
- ✅ Zero cost when not demoing
- ✅ Infrastructure code proves your work
- ✅ Can rebuild anytime in 15 minutes

**Cons:**
- ❌ Can't access live demo instantly
- ❌ Need to rebuild for each demo

---

### Option 2: Scale to Zero (Demo-Ready Mode)
**Cost: ~$90/month**
**Instant Demo: Yes**

Best for: Want infrastructure ready but minimize costs

**Commands:**
```bash
# Stop ECS service (saves $25/month)
aws ecs update-service \
  --cluster cloud-portfolio-dev-cluster \
  --service cloud-portfolio-dev-web-service \
  --desired-count 0 \
  --region us-east-1

# Stop Auto Scaling (saves $13/month)
aws autoscaling set-desired-capacity \
  --auto-scaling-group-name cloud-portfolio-dev-web-asg \
  --desired-capacity 0 \
  --region us-east-1

# Stop RDS (saves $30/month, can only stop for 7 days)
aws rds stop-db-instance \
  --db-instance-identifier cloud-portfolio-dev-mysql \
  --region us-east-1

# Cost: ~$90/month (NAT + ALB + ElastiCache still running)

# To restart for demo:
aws ecs update-service --cluster cloud-portfolio-dev-cluster --service cloud-portfolio-dev-web-service --desired-count 2 --region us-east-1
aws autoscaling set-desired-capacity --auto-scaling-group-name cloud-portfolio-dev-web-asg --desired-capacity 2 --region us-east-1
aws rds start-db-instance --db-instance-identifier cloud-portfolio-dev-mysql --region us-east-1
# Ready in ~5 minutes
```

**Pros:**
- ✅ Infrastructure exists, quick to restart
- ✅ 40% cost savings ($152 → $90)
- ✅ No Terraform rebuild needed

**Cons:**
- ❌ Still paying $90/month
- ❌ RDS auto-starts after 7 days (AWS limitation)

---

### Option 3: Destroy Expensive Resources
**Cost: ~$60/month**
**Rebuild Time: ~5 minutes**

Best for: Keep basic infrastructure, destroy most expensive parts

**Commands:**
```bash
# Destroy expensive resources only
cd terraform/environments/dev

# Destroy RDS (saves $30/month)
terraform destroy -target=aws_db_instance.main -auto-approve

# Destroy 1 NAT Gateway (saves $32.50/month)
terraform destroy -target=module.vpc.aws_nat_gateway.this[1] -auto-approve

# Destroy ElastiCache (saves $15/month)
terraform destroy -target=aws_elasticache_cluster.main -auto-approve

# Destroy ECS (saves $25/month)
terraform destroy -target=aws_ecs_service.web -auto-approve

# Cost: ~$60/month (keeps VPC, ALB, basic networking)

# To rebuild:
terraform apply -auto-approve  # Recreates only destroyed resources
```

**Pros:**
- ✅ Keeps network infrastructure intact
- ✅ 60% cost savings ($152 → $60)
- ✅ Fast rebuild when needed

**Cons:**
- ❌ Still paying $60/month
- ❌ Need to run terraform apply before demo

---

### Option 4: Minimal Demo Infrastructure
**Cost: ~$35/month**
**Demo Capability: Limited**

Best for: Maintaining presence with minimal cost

**What to Keep:**
- 1 EC2 instance in public subnet (no ALB, no Auto Scaling)
- S3 bucket + CloudFront
- Terraform state (free)
- GitHub repo (free)

**What to Destroy:**
- NAT Gateways (-$65)
- RDS MySQL (-$30)
- ECS Fargate (-$25)
- ALB (-$22)
- ElastiCache (-$15)
- Auto Scaling Group

**Commands:**
```bash
# Create minimal terraform config
cat > minimal.tf <<'EOF'
# Single EC2 in public subnet with Elastic IP
resource "aws_instance" "demo" {
  ami           = "ami-0c55b159cbfafe1f0"
  instance_type = "t3.micro"
  subnet_id     = module.vpc.public_subnet_ids[0]

  tags = { Name = "portfolio-demo" }
}

resource "aws_eip" "demo" {
  instance = aws_instance.demo.id
}
EOF

terraform destroy -auto-approve  # Destroy everything
terraform apply -target=module.vpc -target=aws_instance.demo -auto-approve

# Cost: ~$35/month
```

---

## 🚀 Smart Optimization Techniques

### 1. Use AWS Free Tier Strategically

**Free Tier Benefits (12 months for new accounts):**
- ✅ 750 hours/month t2.micro EC2 (not t3.micro)
- ✅ 5GB S3 storage
- ✅ 750 hours/month RDS db.t2.micro (Single-AZ)
- ✅ 1 million Lambda requests
- ✅ 10 custom CloudWatch metrics

**How to Modify for Free Tier:**
```hcl
# Change in terraform/environments/dev/variables.tf
instance_type = "t2.micro"  # Instead of t3.micro
db_instance_class = "db.t2.micro"  # Instead of db.t3.micro

# Disable Multi-AZ
multi_az = false

# This can reduce costs to ~$70/month (NAT still costs money)
```

---

### 2. Implement Scheduled Shutdown

**Auto-Stop After Hours (Saves ~40%)**

Create Lambda function to stop resources nights/weekends:

```python
# lambda/scheduler.py
import boto3
import os

ec2 = boto3.client('ec2')
rds = boto3.client('rds')
ecs = boto3.client('ecs')

def lambda_handler(event, context):
    action = event['action']  # 'stop' or 'start'

    if action == 'stop':
        # Stop Auto Scaling
        asg = boto3.client('autoscaling')
        asg.set_desired_capacity(
            AutoScalingGroupName='cloud-portfolio-dev-web-asg',
            DesiredCapacity=0
        )

        # Stop RDS
        rds.stop_db_instance(DBInstanceIdentifier='cloud-portfolio-dev-mysql')

        # Stop ECS
        ecs.update_service(
            cluster='cloud-portfolio-dev-cluster',
            service='cloud-portfolio-dev-web-service',
            desiredCount=0
        )

    elif action == 'start':
        # Start everything
        asg.set_desired_capacity(AutoScalingGroupName='cloud-portfolio-dev-web-asg', DesiredCapacity=2)
        rds.start_db_instance(DBInstanceIdentifier='cloud-portfolio-dev-mysql')
        ecs.update_service(cluster='cloud-portfolio-dev-cluster', service='cloud-portfolio-dev-web-service', desiredCount=2)

    return {'statusCode': 200}
```

**EventBridge Schedule:**
```hcl
# Stop at 6 PM weekdays, all day weekends
resource "aws_cloudwatch_event_rule" "stop_resources" {
  name = "stop-portfolio-resources"
  schedule_expression = "cron(0 18 ? * MON-FRI *)"  # 6 PM Mon-Fri
}

# Start at 8 AM weekdays
resource "aws_cloudwatch_event_rule" "start_resources" {
  name = "start-portfolio-resources"
  schedule_expression = "cron(0 8 ? * MON-FRI *)"  # 8 AM Mon-Fri
}
```

**Savings**: ~$60/month (40% reduction) by running only 50 hours/week instead of 168 hours/week

---

### 3. Replace NAT Gateway with NAT Instance

**NAT Gateway Cost**: $65/month (biggest expense)
**NAT Instance Cost**: $7/month (t3.nano)

**Trade-off**: NAT Gateway is managed, highly available. NAT Instance requires management but saves $58/month.

```hcl
# Instead of NAT Gateway
resource "aws_instance" "nat" {
  ami           = "ami-nat-instance"  # Amazon NAT AMI
  instance_type = "t3.nano"
  subnet_id     = module.vpc.public_subnet_ids[0]

  source_dest_check = false  # Required for NAT

  tags = { Name = "nat-instance" }
}

# Update private route table
resource "aws_route" "private_nat" {
  route_table_id         = module.vpc.private_route_table_id
  destination_cidr_block = "0.0.0.0/0"
  instance_id            = aws_instance.nat.id
}

# Savings: $58/month
```

**Cons**:
- Single point of failure (not multi-AZ)
- Manual management required
- Lower bandwidth vs NAT Gateway

---

### 4. Use Fargate Spot (70% Savings)

**Standard Fargate**: $25/month
**Fargate Spot**: $7.50/month (70% discount)

**Risk**: Tasks can be interrupted with 2-minute warning

```hcl
# In ecs.tf
resource "aws_ecs_service" "web" {
  capacity_provider_strategy {
    capacity_provider = "FARGATE_SPOT"
    weight            = 100
    base              = 0
  }

  # Savings: $17.50/month
}
```

**Best for**: Fault-tolerant workloads, dev/staging environments

---

### 5. Reduce RDS to Single-AZ (Save 50%)

**Multi-AZ RDS**: $30/month
**Single-AZ RDS**: $15/month

**Trade-off**: No automatic failover, ~5-10 min downtime for maintenance

```hcl
# In rds.tf
resource "aws_db_instance" "main" {
  multi_az = false  # Change from true

  # Savings: $15/month
}
```

**Acceptable for**: Demo/portfolio projects, non-production environments

---

## 📊 Cost Optimization Scenarios Comparison

| Scenario | Monthly Cost | Rebuild Time | Demo Ready | Best For |
|----------|-------------|--------------|-----------|----------|
| **Full Production** | $152 | N/A | Always | Active use, interviews |
| **Complete Teardown** | $0 | 15 min | No | Storage only |
| **Scale to Zero** | $90 | 5 min | Partial | Ready for quick demos |
| **Destroy Expensive** | $60 | 5 min | Partial | Budget-conscious |
| **Minimal Demo** | $35 | 30 min | Limited | Long-term low cost |
| **Free Tier Optimized** | $70 | N/A | Always | New AWS accounts |
| **Scheduled Shutdown** | $90 | Automatic | Scheduled | Business hours only |
| **Fargate Spot + Single-AZ RDS** | $115 | N/A | Always | Acceptable risk |
| **NAT Instance** | $95 | N/A | Always | Cost-conscious |

---

## 🛠️ Step-by-Step Cleanup Procedures

### Pre-Cleanup Checklist (DO THIS FIRST!)

```bash
# ✅ 1. Take screenshots of ALL services (use PORTFOLIO_SCREENSHOTS.md guide)

# ✅ 2. Export Terraform outputs
cd terraform/environments/dev
terraform output -json > infrastructure-outputs.json

# ✅ 3. Document current infrastructure state
terraform show > infrastructure-state.txt

# ✅ 4. Verify GitHub has latest code
git status  # Ensure clean working directory
git log -1  # Confirm latest commit is pushed

# ✅ 5. Download any important logs
aws logs tail /aws/ec2/cloud-portfolio-dev --since 1w > logs-ec2.txt
aws logs tail /aws/ecs/cloud-portfolio-dev --since 1w > logs-ecs.txt

# ✅ 6. Export RDS data (if needed)
aws rds create-db-snapshot \
  --db-instance-identifier cloud-portfolio-dev-mysql \
  --db-snapshot-identifier portfolio-final-snapshot-$(date +%Y%m%d) \
  --region us-east-1

# ✅ 7. Verify S3 bucket contents
aws s3 ls s3://cloud-portfolio-dev-static-g8al5lmt --recursive > s3-contents.txt
```

---

### Method 1: Complete Infrastructure Teardown

**When to use**: Done with project, want $0 costs

```bash
# Step 1: Navigate to Terraform directory
cd c:\Users\jacob\cloud-infrastructure-portfolio\terraform\environments\dev

# Step 2: Review what will be destroyed
terraform plan -destroy

# Step 3: Destroy all resources
terraform destroy -auto-approve

# Expected output:
# Destroy complete! Resources: 75 destroyed.

# Step 4: Verify S3 state bucket (optional - keep for free)
# If you want to delete state:
aws s3 rb s3://cloud-portfolio-terraform-state --force --region us-east-1

# Step 5: Verify cleanup
aws ec2 describe-instances --region us-east-1 --filters "Name=tag:Project,Values=cloud-portfolio"
# Should return empty

# Result: $0/month cost
```

---

### Method 2: Selective Resource Destruction

**When to use**: Keep some infrastructure, destroy expensive parts

```bash
cd terraform/environments/dev

# Destroy in order (most expensive first):

# 1. NAT Gateways (-$65/month)
terraform destroy -target=module.vpc.aws_nat_gateway.this -auto-approve

# 2. RDS Database (-$30/month)
terraform destroy -target=aws_db_instance.main -auto-approve

# 3. ECS Service (-$25/month)
terraform destroy -target=aws_ecs_service.web -target=aws_ecs_cluster.main -auto-approve

# 4. Application Load Balancer (-$22/month)
terraform destroy -target=module.alb.aws_lb.this -auto-approve

# 5. ElastiCache (-$15/month)
terraform destroy -target=aws_elasticache_cluster.main -auto-approve

# 6. Auto Scaling Group (-$13/month)
terraform destroy -target=module.asg -auto-approve

# Total savings: ~$170/month destroyed, keep VPC/S3/CloudFront (~$10/month)
```

---

### Method 3: Graceful Scale-Down

**When to use**: Keep infrastructure alive but minimal

```bash
# Stop services without destroying

# 1. Scale ECS to 0 tasks
aws ecs update-service \
  --cluster cloud-portfolio-dev-cluster \
  --service cloud-portfolio-dev-web-service \
  --desired-count 0 \
  --region us-east-1

# 2. Scale Auto Scaling Group to 0
aws autoscaling set-desired-capacity \
  --auto-scaling-group-name cloud-portfolio-dev-web-asg \
  --desired-capacity 0 \
  --region us-east-1

# 3. Stop RDS (can stay stopped for 7 days)
aws rds stop-db-instance \
  --db-instance-identifier cloud-portfolio-dev-mysql \
  --region us-east-1

# 4. Verify scaled down
aws ecs describe-services --cluster cloud-portfolio-dev-cluster --services cloud-portfolio-dev-web-service --region us-east-1 | grep runningCount
# Should show: "runningCount": 0

aws autoscaling describe-auto-scaling-groups --auto-scaling-group-names cloud-portfolio-dev-web-asg --region us-east-1 | grep DesiredCapacity
# Should show: "DesiredCapacity": 0

aws rds describe-db-instances --db-instance-identifier cloud-portfolio-dev-mysql --region us-east-1 | grep DBInstanceStatus
# Should show: "DBInstanceStatus": "stopped"

# Savings: ~$68/month, infrastructure still exists
```

---

## 💡 Cost Monitoring & Alerts

### Set Up Budget Alerts

```bash
# Create budget alert at $200/month
aws budgets create-budget \
  --account-id $(aws sts get-caller-identity --query Account --output text) \
  --budget file://budget-config.json \
  --notifications-with-subscribers file://budget-notifications.json \
  --region us-east-1
```

**budget-config.json:**
```json
{
  "BudgetName": "cloud-portfolio-monthly",
  "BudgetLimit": {
    "Amount": "200",
    "Unit": "USD"
  },
  "TimeUnit": "MONTHLY",
  "BudgetType": "COST"
}
```

**budget-notifications.json:**
```json
[
  {
    "Notification": {
      "NotificationType": "ACTUAL",
      "ComparisonOperator": "GREATER_THAN",
      "Threshold": 80,
      "ThresholdType": "PERCENTAGE"
    },
    "Subscribers": [
      {
        "SubscriptionType": "EMAIL",
        "Address": "your-email@example.com"
      }
    ]
  }
]
```

### Check Current Costs

```bash
# Get current month costs
aws ce get-cost-and-usage \
  --time-period Start=$(date +%Y-%m-01),End=$(date +%Y-%m-%d) \
  --granularity MONTHLY \
  --metrics BlendedCost \
  --group-by Type=DIMENSION,Key=SERVICE \
  --region us-east-1

# Get daily costs for last 7 days
aws ce get-cost-and-usage \
  --time-period Start=$(date -d '7 days ago' +%Y-%m-%d),End=$(date +%Y-%m-%d) \
  --granularity DAILY \
  --metrics BlendedCost \
  --region us-east-1
```

---

## 🎬 Quick Reference Commands

### Get Current Infrastructure Cost
```bash
aws ce get-cost-and-usage \
  --time-period Start=2025-11-01,End=2025-11-28 \
  --granularity MONTHLY \
  --metrics BlendedCost \
  --filter file://filter.json \
  --region us-east-1

# filter.json
{
  "Tags": {
    "Key": "Project",
    "Values": ["cloud-portfolio"]
  }
}
```

### List All Resources (Before Deletion)
```bash
# EC2 Instances
aws ec2 describe-instances --region us-east-1 --filters "Name=tag:Project,Values=cloud-portfolio" --query "Reservations[].Instances[].[InstanceId,State.Name,InstanceType]" --output table

# ECS Services
aws ecs list-services --cluster cloud-portfolio-dev-cluster --region us-east-1

# RDS Instances
aws rds describe-db-instances --region us-east-1 --query "DBInstances[?contains(DBInstanceIdentifier, 'cloud-portfolio')].[DBInstanceIdentifier,DBInstanceStatus,DBInstanceClass]" --output table

# Load Balancers
aws elbv2 describe-load-balancers --region us-east-1 --query "LoadBalancers[?contains(LoadBalancerName, 'cloud-portfolio')].[LoadBalancerName,State.Code]" --output table

# NAT Gateways
aws ec2 describe-nat-gateways --region us-east-1 --filter "Name=tag:Project,Values=cloud-portfolio" --query "NatGateways[].[NatGatewayId,State]" --output table

# S3 Buckets
aws s3 ls | grep cloud-portfolio

# ElastiCache
aws elasticache describe-cache-clusters --region us-east-1 --query "CacheClusters[?contains(CacheClusterId, 'cloud-portfolio')].[CacheClusterId,CacheNodeType,CacheClusterStatus]" --output table
```

### Rebuild After Teardown
```bash
cd terraform/environments/dev
terraform init
terraform apply -auto-approve

# Takes ~15 minutes
# Recreates entire infrastructure from code
```

---

## 📈 Recommended Strategy for Portfolio Project

### **Best Approach: Complete Teardown + Documentation**

**Reasoning:**
1. You have comprehensive documentation proving you built it
2. Screenshots demonstrate the working infrastructure
3. Terraform code shows technical expertise
4. GitHub history proves it's your work
5. Can rebuild in 15 minutes before interview
6. **Zero ongoing costs**

**What to Keep:**
- ✅ GitHub repository (free)
- ✅ Terraform code (free)
- ✅ Screenshots (free)
- ✅ Architecture diagrams (free)
- ✅ Documentation (free)
- ✅ PORTFOLIO_SUMMARY.md (free)
- ✅ Resume bullet points (free)

**What to Destroy:**
- ❌ All AWS resources ($0/month)

**Interview Preparation:**
```bash
# 2 days before interview:
terraform apply -auto-approve  # 15 minutes
# Take new screenshots if needed
# Test application
# Practice demo talking points

# After interview:
terraform destroy -auto-approve  # 10 minutes
# Cost for 2-day demo: ~$10
```

**Annual Cost Comparison:**
- Always-on: $152/month × 12 = **$1,824/year**
- 2-day demos × 6 interviews = **$60/year**

**Savings: $1,764/year** 🎉

---

## ⚠️ Important Reminders

1. **Always take screenshots before destroying anything**
2. **Verify GitHub has latest code pushed**
3. **Export Terraform state before destroying**
4. **Create RDS snapshot if database has important data**
5. **Download CloudWatch logs if needed**
6. **Update resume with quantifiable metrics from live system**
7. **Test rebuild process at least once**
8. **Set up AWS Budget alerts to catch unexpected costs**
9. **Check for orphaned resources after destroy (EBS snapshots, Elastic IPs)**
10. **Terraform state files contain sensitive data - don't commit to public repos**

---

This guide provides comprehensive cost optimization strategies for your cloud portfolio project. The recommended approach (complete teardown with rebuild capability) gives you maximum cost savings while maintaining full demo capability when needed!
