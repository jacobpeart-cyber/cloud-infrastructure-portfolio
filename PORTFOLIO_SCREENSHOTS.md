# AWS Console Screenshot Guide

## 📸 Screenshots to Capture for Portfolio

### 1. VPC & Networking
- **VPC Dashboard**: https://console.aws.amazon.com/vpc/home?region=us-east-1#vpcs:
  - Show: cloud-portfolio-dev VPC with 10.0.0.0/16 CIDR
  - Highlight: 2 public subnets, 2 private subnets, multi-AZ setup

- **Subnets**: https://console.aws.amazon.com/vpc/home?region=us-east-1#subnets:
  - Show: 4 subnets across 2 availability zones
  - Highlight: Auto-assign public IP on public subnets

- **Route Tables**: https://console.aws.amazon.com/vpc/home?region=us-east-1#RouteTables:
  - Show: Public route table with IGW, Private route tables with NAT Gateways
  - Highlight: Multi-AZ NAT Gateway setup

- **NAT Gateways**: https://console.aws.amazon.com/vpc/home?region=us-east-1#NatGateways:
  - Show: 2 NAT Gateways (one per AZ) in public subnets
  - Highlight: High availability configuration

- **Security Groups**: https://console.aws.amazon.com/vpc/home?region=us-east-1#SecurityGroups:
  - Show: ALB SG, EC2 SG, RDS SG, ECS Tasks SG, ElastiCache SG
  - Highlight: Layered security with least privilege

### 2. EC2 & Compute
- **EC2 Instances**: https://console.aws.amazon.com/ec2/home?region=us-east-1#Instances:
  - Show: Running EC2 instances in Auto Scaling Group
  - Highlight: Multi-AZ deployment, instance health

- **Auto Scaling Groups**: https://console.aws.amazon.com/ec2/home?region=us-east-1#AutoScalingGroups:
  - Show: cloud-portfolio-dev-asg configuration
  - Highlight: Desired: 2, Min: 1, Max: 4
  - Show: Scaling policies (CPU-based)

- **Launch Template**: https://console.aws.amazon.com/ec2/home?region=us-east-1#LaunchTemplates:
  - Show: cloud-portfolio-dev-lt configuration
  - Highlight: User data, security groups, instance type

- **Load Balancers**: https://console.aws.amazon.com/ec2/home?region=us-east-1#LoadBalancers:
  - Show: cloud-portfolio-dev-alb
  - Highlight: Multi-AZ, listener rules, target groups

- **Target Groups**: https://console.aws.amazon.com/ec2/home?region=us-east-1#TargetGroups:
  - Show: Both EC2 and ECS target groups
  - Highlight: Health check configuration, healthy targets

### 3. ECS & Containers
- **ECS Clusters**: https://console.aws.amazon.com/ecs/home?region=us-east-1#/clusters
  - Show: cloud-portfolio-dev-cluster
  - Highlight: Fargate service, task count

- **ECS Services**: https://console.aws.amazon.com/ecs/home?region=us-east-1#/clusters/cloud-portfolio-dev-cluster/services
  - Show: cloud-portfolio-dev-web-service
  - Highlight: Desired: 2, Running: 2, Service Discovery integration

- **ECS Tasks**: https://console.aws.amazon.com/ecs/home?region=us-east-1#/clusters/cloud-portfolio-dev-cluster/tasks
  - Show: Running Fargate tasks
  - Highlight: Task definition with X-Ray sidecar, networking

- **ECR Repository**: https://console.aws.amazon.com/ecr/repositories?region=us-east-1
  - Show: cloud-portfolio-dev-app repository
  - Highlight: Docker images, lifecycle policy

### 4. Database & Caching
- **RDS Instances**: https://console.aws.amazon.com/rds/home?region=us-east-1#databases:
  - Show: cloud-portfolio-dev-mysql
  - Highlight: Multi-AZ deployment, automated backups

- **RDS Snapshots**: https://console.aws.amazon.com/rds/home?region=us-east-1#db-snapshots:
  - Show: Automated snapshots
  - Highlight: Daily backup retention

- **ElastiCache**: https://console.aws.amazon.com/elasticache/home?region=us-east-1#/redis
  - Show: cloud-portfolio-dev-redis cluster
  - Highlight: Redis engine version, node type

### 5. Storage & CDN
- **S3 Buckets**: https://console.aws.amazon.com/s3/buckets?region=us-east-1
  - Show: cloud-portfolio-dev-static-content bucket
  - Highlight: Versioning, encryption, lifecycle policies

- **CloudFront Distributions**: https://console.aws.amazon.com/cloudfront/home
  - Show: Distribution with S3 origin
  - Highlight: Global edge locations, SSL certificate, caching behavior

### 6. Monitoring & Observability
- **CloudWatch Dashboards**: https://console.aws.amazon.com/cloudwatch/home?region=us-east-1#dashboards:
  - Show: Custom dashboard with key metrics
  - Highlight: CPU, memory, request count, latency

- **CloudWatch Alarms**: https://console.aws.amazon.com/cloudwatch/home?region=us-east-1#alarmsV2:
  - Show: High CPU alarm, unhealthy target alarm
  - Highlight: SNS notification integration

- **CloudWatch Logs**: https://console.aws.amazon.com/cloudwatch/home?region=us-east-1#logsV2:streams
  - Show: EC2 and ECS log groups
  - Highlight: Log retention, filtering

- **X-Ray Service Map**: https://console.aws.amazon.com/xray/home?region=us-east-1#/service-map
  - Show: Service dependencies and trace visualization
  - Highlight: Response times, error rates

- **X-Ray Traces**: https://console.aws.amazon.com/xray/home?region=us-east-1#/traces
  - Show: Individual request traces
  - Highlight: Trace timeline, subsegments

### 7. Networking & DNS
- **Route 53 Hosted Zones**: https://console.aws.amazon.com/route53/v2/hostedzones
  - Show: Hosted zone (if configured)
  - Highlight: DNS records, health checks

- **Cloud Map (Service Discovery)**: https://console.aws.amazon.com/cloudmap/home?region=us-east-1#/namespaces
  - Show: cloud-portfolio.local namespace
  - Highlight: Service discovery for ECS

### 8. Security & IAM
- **IAM Roles**: https://console.aws.amazon.com/iam/home#/roles
  - Show: EC2 instance role, ECS task execution role, ECS task role
  - Highlight: Least privilege policies

- **SNS Topics**: https://console.aws.amazon.com/sns/v3/home?region=us-east-1#/topics
  - Show: cloud-portfolio-dev-alerts topic
  - Highlight: Email subscription for alarms

### 9. Cost Management
- **Cost Explorer**: https://console.aws.amazon.com/cost-management/home#/cost-explorer
  - Show: Monthly costs breakdown by service
  - Highlight: Cost trends, top services

- **Billing Dashboard**: https://console.aws.amazon.com/billing/home#/
  - Show: Current month-to-date charges
  - Highlight: Service breakdown

### 10. CI/CD (GitHub)
- **GitHub Actions**: https://github.com/jacobpeart-cyber/cloud-infrastructure-portfolio/actions
  - Show: Terraform workflow runs
  - Highlight: Successful deployments

---

## 📊 Key Metrics to Capture

### Infrastructure Statistics
- **Total AWS Services**: 40+
- **VPC CIDR**: 10.0.0.0/16
- **Subnets**: 4 (2 public, 2 private)
- **Availability Zones**: 2 (us-east-1a, us-east-1b)
- **EC2 Instances**: 2 (auto-scaled)
- **ECS Tasks**: 2 Fargate tasks
- **Target Groups**: 2 (EC2 + ECS)
- **Healthy Targets**: 4 total

### Performance Metrics
- **CloudFront Latency Reduction**: ~60% (vs direct S3)
- **Auto-Scaling Response Time**: <5 minutes
- **Health Check Interval**: 30 seconds
- **RDS Backup Retention**: 7 days
- **Log Retention**: 7 days

### Security Highlights
- **Security Groups**: 5 layers
- **Encryption**: At rest (RDS, S3, EBS) and in transit (SSL/TLS)
- **IAM Roles**: Least privilege access
- **Private Subnets**: Database and application tiers
- **NAT Gateways**: Outbound internet for private resources

---

## 📝 Screenshot Tips

1. **Before Taking Screenshots**:
   - Clear browser notifications
   - Zoom browser to 100%
   - Use full screen or maximize window
   - Enable dark mode for better contrast (optional)

2. **What to Highlight**:
   - Circle or annotate key configurations
   - Show resource names clearly
   - Include region (us-east-1) in view
   - Capture health status (green checkmarks)

3. **Screenshot Organization**:
   ```
   screenshots/
   ├── 01-vpc-dashboard.png
   ├── 02-subnets-multi-az.png
   ├── 03-route-tables.png
   ├── 04-nat-gateways.png
   ├── 05-security-groups.png
   ├── 06-ec2-instances.png
   ├── 07-auto-scaling-group.png
   ├── 08-load-balancer.png
   ├── 09-target-groups-healthy.png
   ├── 10-ecs-cluster.png
   ├── 11-ecs-service.png
   ├── 12-ecs-tasks-running.png
   ├── 13-ecr-repository.png
   ├── 14-rds-multi-az.png
   ├── 15-elasticache-redis.png
   ├── 16-s3-bucket.png
   ├── 17-cloudfront-distribution.png
   ├── 18-cloudwatch-dashboard.png
   ├── 19-cloudwatch-alarms.png
   ├── 20-xray-service-map.png
   ├── 21-xray-traces.png
   ├── 22-service-discovery.png
   ├── 23-iam-roles.png
   ├── 24-cost-explorer.png
   └── 25-github-actions.png
   ```

4. **Alternative: AWS CLI Screenshots**:
   ```powershell
   # Generate text-based infrastructure snapshot
   aws ec2 describe-instances --region us-east-1 > infrastructure-ec2.json
   aws ecs describe-clusters --region us-east-1 > infrastructure-ecs.json
   aws rds describe-db-instances --region us-east-1 > infrastructure-rds.json
   ```

---

## 🎯 Priority Screenshots (Top 10)

If time is limited, capture these first:

1. **Architecture Overview**: VPC dashboard showing all components
2. **Auto Scaling Group**: Showing desired/min/max and running instances
3. **Load Balancer**: With healthy target groups
4. **ECS Service**: Fargate tasks running with X-Ray
5. **RDS Multi-AZ**: Database with automated backups
6. **CloudWatch Dashboard**: Key metrics visualization
7. **X-Ray Service Map**: Distributed tracing visualization
8. **Security Groups**: Layered security configuration
9. **Cost Explorer**: Monthly cost breakdown
10. **GitHub Actions**: Successful CI/CD pipeline run

These screenshots tell the complete story of your production-ready infrastructure!
