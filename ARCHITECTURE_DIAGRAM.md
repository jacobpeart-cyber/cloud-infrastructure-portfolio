# Cloud Portfolio Architecture Diagram

## Complete AWS Infrastructure Overview

```
┌─────────────────────────────────────────────────────────────────────────────────────────┐
│                                    INTERNET                                              │
│                                       ↓                                                  │
└─────────────────────────────────────────────────────────────────────────────────────────┘
                                        ↓
┌─────────────────────────────────────────────────────────────────────────────────────────┐
│                              Route 53 DNS (Optional)                                     │
│                          cloud-portfolio.example.com                                     │
└─────────────────────────────────────────────────────────────────────────────────────────┘
                                        ↓
┌─────────────────────────────────────────────────────────────────────────────────────────┐
│                          CloudFront CDN (Global Edge)                                    │
│                    ┌────────────────────────────────────────┐                           │
│                    │  Cache: Static Content (S3)            │                           │
│                    │  SSL/TLS: AWS Certificate Manager      │                           │
│                    │  60% Latency Reduction                 │                           │
│                    └────────────────────────────────────────┘                           │
└─────────────────────────────────────────────────────────────────────────────────────────┘
                    ↓                                          ↓
          (Dynamic Content)                          (Static Content)
                    ↓                                          ↓
┌───────────────────────────────────────────────────────────────────────────────────────────┐
│                              AWS CLOUD (us-east-1)                                        │
│                                                                                           │
│  ┌─────────────────────────────────────────────────────────────────────────────────────┐ │
│  │                    VPC: cloud-portfolio-dev (10.0.0.0/16)                           │ │
│  │                                                                                     │ │
│  │  ┌──────────────────────────────────────────────────────────────────────────────┐  │ │
│  │  │                        INTERNET GATEWAY                                       │  │ │
│  │  └──────────────────────────────────────────────────────────────────────────────┘  │ │
│  │                                     ↓                                               │ │
│  │  ┌──────────────────────────────────────────────────────────────────────────────┐  │ │
│  │  │            Application Load Balancer (Internet-facing)                        │  │ │
│  │  │            Security Group: Allow 80, 443 from 0.0.0.0/0                      │  │ │
│  │  │            Routes: / → EC2, /ecs/* → ECS Fargate                             │  │ │
│  │  └──────────────────────────────────────────────────────────────────────────────┘  │ │
│  │                                     ↓                                               │ │
│  │  ┌─────────────────────────────────────────────────────────────────────────────┐   │ │
│  │  │                        PUBLIC SUBNET TIER                                    │   │ │
│  │  │                                                                              │   │ │
│  │  │  ┌──────────────────────┐              ┌──────────────────────┐            │   │ │
│  │  │  │  us-east-1a          │              │  us-east-1b          │            │   │ │
│  │  │  │  10.0.1.0/24         │              │  10.0.2.0/24         │            │   │ │
│  │  │  │                      │              │                      │            │   │ │
│  │  │  │  ┌────────────────┐  │              │  ┌────────────────┐  │            │   │ │
│  │  │  │  │ NAT Gateway 1  │  │              │  │ NAT Gateway 2  │  │            │   │ │
│  │  │  │  │ Elastic IP     │  │              │  │ Elastic IP     │  │            │   │ │
│  │  │  │  └────────────────┘  │              │  └────────────────┘  │            │   │ │
│  │  │  └──────────────────────┘              └──────────────────────┘            │   │ │
│  │  └─────────────────────────────────────────────────────────────────────────────┘   │ │
│  │                          ↓                              ↓                           │ │
│  │  ┌─────────────────────────────────────────────────────────────────────────────┐   │ │
│  │  │                       PRIVATE SUBNET TIER                                    │   │ │
│  │  │                                                                              │   │ │
│  │  │  ┌──────────────────────────────────┐  ┌──────────────────────────────────┐ │   │ │
│  │  │  │  us-east-1a (10.0.11.0/24)       │  │  us-east-1b (10.0.12.0/24)       │ │   │ │
│  │  │  │                                  │  │                                  │ │   │ │
│  │  │  │  ┌────────────────────────────┐  │  │  ┌────────────────────────────┐  │ │   │ │
│  │  │  │  │   EC2 INSTANCES            │  │  │  │   EC2 INSTANCES            │  │ │   │ │
│  │  │  │  │  ┌──────────────────────┐  │  │  │  │  ┌──────────────────────┐  │  │ │   │ │
│  │  │  │  │  │ EC2 Instance 1       │  │  │  │  │  │ EC2 Instance 2       │  │  │ │   │ │
│  │  │  │  │  │ t3.micro             │  │  │  │  │  │ t3.micro             │  │  │ │   │ │
│  │  │  │  │  │ Auto Scaling Group   │  │  │  │  │  │ Auto Scaling Group   │  │  │ │   │ │
│  │  │  │  │  │ User Data: Apache    │  │  │  │  │  │ User Data: Apache    │  │  │ │   │ │
│  │  │  │  │  └──────────────────────┘  │  │  │  │  └──────────────────────┘  │  │ │   │ │
│  │  │  │  │                            │  │  │  │                            │  │ │   │ │
│  │  │  │  │  ┌──────────────────────┐  │  │  │  │  ┌──────────────────────┐  │  │ │   │ │
│  │  │  │  │  │ ECS FARGATE TASKS    │  │  │  │  │  │ ECS FARGATE TASKS    │  │  │ │   │ │
│  │  │  │  │  │ ┌──────────────────┐ │  │  │  │  │  │ ┌──────────────────┐ │  │  │ │   │ │
│  │  │  │  │  │ │ Task 1           │ │  │  │  │  │  │ │ Task 2           │ │  │  │ │   │ │
│  │  │  │  │  │ │ Node.js App      │ │  │  │  │  │  │ │ Node.js App      │ │  │  │ │   │ │
│  │  │  │  │  │ │ + X-Ray Daemon   │ │  │  │  │  │  │ │ + X-Ray Daemon   │ │  │  │ │   │ │
│  │  │  │  │  │ │ 0.5 vCPU/1GB    │ │  │  │  │  │  │ │ 0.5 vCPU/1GB    │ │  │  │ │   │ │
│  │  │  │  │  │ └──────────────────┘ │  │  │  │  │  │ └──────────────────┘ │  │  │ │   │ │
│  │  │  │  │  └──────────────────────┘  │  │  │  │  └──────────────────────┘  │  │ │   │ │
│  │  │  │  └────────────────────────────┘  │  │  └────────────────────────────┘  │ │   │ │
│  │  │  │                                  │  │                                  │ │   │ │
│  │  │  │  ┌────────────────────────────┐  │  │  ┌────────────────────────────┐  │ │   │ │
│  │  │  │  │  ElastiCache Redis       │  │  │  │  RDS MySQL (Standby)       │  │ │   │ │
│  │  │  │  │  cache.t3.micro          │  │  │  │  db.t3.micro               │  │ │   │ │
│  │  │  │  │  Port: 6379              │  │  │  │  Multi-AZ Standby          │  │ │   │ │
│  │  │  │  └────────────────────────────┘  │  │  └────────────────────────────┘  │ │   │ │
│  │  │  │                                  │  │                                  │ │   │ │
│  │  │  │  ┌────────────────────────────┐  │  │                                  │ │   │ │
│  │  │  │  │  RDS MySQL (Primary)       │  │  │                                  │ │   │ │
│  │  │  │  │  db.t3.micro               │  │  │                                  │ │   │ │
│  │  │  │  │  20GB GP3 Storage          │  │  │                                  │ │   │ │
│  │  │  │  │  Auto Backups: 7 days      │  │  │                                  │ │   │ │
│  │  │  │  │  Port: 3306                │  │  │                                  │ │   │ │
│  │  │  │  └────────────────────────────┘  │  │                                  │ │   │ │
│  │  │  └──────────────────────────────────┘  └──────────────────────────────────┘ │   │ │
│  │  └─────────────────────────────────────────────────────────────────────────────┘   │ │
│  │                                                                                     │ │
│  │  ┌─────────────────────────────────────────────────────────────────────────────┐   │ │
│  │  │                   AWS Cloud Map (Service Discovery)                          │   │ │
│  │  │                   Namespace: cloud-portfolio.local                           │   │ │
│  │  │                   Service: app.cloud-portfolio.local                         │   │ │
│  │  └─────────────────────────────────────────────────────────────────────────────┘   │ │
│  └─────────────────────────────────────────────────────────────────────────────────────┘ │
│                                                                                           │
│  ┌─────────────────────────────────────────────────────────────────────────────────────┐ │
│  │                           SUPPORTING SERVICES                                        │ │
│  │                                                                                      │ │
│  │  ┌──────────────────┐  ┌──────────────────┐  ┌──────────────────┐                  │ │
│  │  │  S3 Bucket       │  │  ECR Repository  │  │  CloudWatch      │                  │ │
│  │  │  Static Content  │  │  Docker Images   │  │  Logs & Metrics  │                  │ │
│  │  │  ├─ Versioning   │  │  ├─ Lifecycle    │  │  ├─ Dashboards   │                  │ │
│  │  │  ├─ Encryption   │  │  ├─ Scan on Push │  │  ├─ Alarms       │                  │ │
│  │  │  └─ Lifecycle    │  │  └─ Keep 10 imgs │  │  └─ 7d Retention │                  │ │
│  │  └──────────────────┘  └──────────────────┘  └──────────────────┘                  │ │
│  │                                                                                      │ │
│  │  ┌──────────────────┐  ┌──────────────────┐  ┌──────────────────┐                  │ │
│  │  │  X-Ray           │  │  SNS Topic       │  │  IAM Roles       │                  │ │
│  │  │  Distributed     │  │  Alerts          │  │  ├─ EC2 Instance  │                  │ │
│  │  │  Tracing         │  │  └─ Email        │  │  ├─ ECS Task Exec │                  │ │
│  │  │  ├─ Service Map  │  │     Notifications│  │  └─ ECS Task Role│                  │ │
│  │  │  └─ Traces       │  │                  │  │                  │                  │ │
│  │  └──────────────────┘  └──────────────────┘  └──────────────────┘                  │ │
│  └─────────────────────────────────────────────────────────────────────────────────────┘ │
│                                                                                           │
└───────────────────────────────────────────────────────────────────────────────────────────┘

┌───────────────────────────────────────────────────────────────────────────────────────────┐
│                              CI/CD PIPELINE (GitHub Actions)                              │
│                                                                                           │
│  Developer Push → GitHub → Terraform Plan → Manual Approve → Terraform Apply             │
│                                                    ↓                                      │
│                            AWS Resources Updated via Terraform                            │
│                                                                                           │
└───────────────────────────────────────────────────────────────────────────────────────────┘
```

---

## Security Architecture

```
┌─────────────────────────────────────────────────────────────────────────────────┐
│                        SECURITY LAYERS (Defense in Depth)                        │
├─────────────────────────────────────────────────────────────────────────────────┤
│                                                                                 │
│  Layer 1: Network Isolation                                                     │
│  ├─ Public Subnets: Only ALB and NAT Gateways                                  │
│  ├─ Private Subnets: EC2, ECS, RDS, ElastiCache                               │
│  └─ Multi-AZ: Resources spread across 2 availability zones                     │
│                                                                                 │
│  Layer 2: Security Groups (Stateful Firewall)                                  │
│  ├─ ALB SG: Allow 80/443 from Internet → Forward to EC2/ECS on 8080           │
│  ├─ EC2 SG: Allow 8080 from ALB only                                          │
│  ├─ ECS SG: Allow 8080 from ALB only                                          │
│  ├─ RDS SG: Allow 3306 from EC2/ECS only                                      │
│  └─ ElastiCache SG: Allow 6379 from EC2/ECS only                              │
│                                                                                 │
│  Layer 3: IAM Roles (Least Privilege)                                          │
│  ├─ EC2 Instance Role: CloudWatch, SSM, S3 read-only                          │
│  ├─ ECS Task Execution Role: ECR pull, CloudWatch logs                        │
│  └─ ECS Task Role: S3, RDS, ElastiCache, X-Ray                               │
│                                                                                 │
│  Layer 4: Encryption                                                            │
│  ├─ In Transit: SSL/TLS (CloudFront, ALB)                                     │
│  ├─ At Rest: RDS (AES-256), S3 (SSE-S3), EBS (AES-256)                       │
│  └─ Secrets: AWS Secrets Manager (RDS credentials)                            │
│                                                                                 │
│  Layer 5: Monitoring & Alerts                                                   │
│  ├─ CloudWatch Alarms: CPU, unhealthy targets, failed health checks           │
│  ├─ CloudWatch Logs: All application and system logs                          │
│  ├─ X-Ray: Distributed tracing for security analysis                          │
│  └─ SNS Notifications: Real-time alerts                                        │
│                                                                                 │
└─────────────────────────────────────────────────────────────────────────────────┘
```

---

## Traffic Flow Diagrams

### User Request Flow (EC2 Path)

```
User Browser
    ↓
CloudFront CDN (if static content)
    ↓
Application Load Balancer (port 80/443)
    ↓
Target Group (EC2)
    ↓
EC2 Instance (port 8080)
    ↓
    ├─→ RDS MySQL (port 3306)
    ├─→ ElastiCache Redis (port 6379)
    └─→ S3 Bucket (static files)
```

### User Request Flow (ECS Fargate Path)

```
User Browser
    ↓
Application Load Balancer (path: /ecs/*)
    ↓
Target Group (ECS)
    ↓
ECS Fargate Task (port 8080)
    ├─→ X-Ray Daemon (traces)
    ├─→ CloudWatch Logs
    ├─→ RDS MySQL (DB_HOST env var)
    ├─→ ElastiCache Redis (REDIS_HOST env var)
    └─→ S3 Bucket (S3_BUCKET env var)
```

### Service Discovery Flow

```
ECS Service Registration
    ↓
AWS Cloud Map
    ↓
DNS: app.cloud-portfolio.local
    ↓
Route to healthy ECS tasks only
```

---

## Auto Scaling Flow

```
CloudWatch Metric: CPU > 70%
    ↓
CloudWatch Alarm Triggered
    ↓
Auto Scaling Policy Activated
    ↓
Launch New EC2 Instance (from Launch Template)
    ↓
Instance Passes Health Checks
    ↓
Added to Target Group
    ↓
Receives Traffic from ALB

(Scale Down when CPU < 30% for 5 minutes)
```

---

## Monitoring & Observability Flow

```
Application Logs
    ↓
CloudWatch Logs Agent
    ↓
CloudWatch Log Groups
    ├─→ /aws/ec2/cloud-portfolio-dev
    └─→ /aws/ecs/cloud-portfolio-dev

Application Metrics
    ↓
CloudWatch Metrics
    ├─→ CPU Utilization
    ├─→ Network In/Out
    ├─→ Request Count
    └─→ Target Response Time

Distributed Traces
    ↓
X-Ray Daemon
    ↓
X-Ray Service
    ├─→ Service Map
    ├─→ Trace Timeline
    └─→ Error Analysis

Alarms Triggered
    ↓
SNS Topic
    ↓
Email Notifications
```

---

## Cost Breakdown by Service

```
Monthly Infrastructure Costs (~$152/month)

┌─────────────────────────────────────────┐
│ NAT Gateways (2x)           $65  (43%) │ ███████████████████████
│ RDS MySQL (Multi-AZ)        $30  (20%) │ ████████████
│ ECS Fargate (2 tasks)       $25  (16%) │ ██████████
│ ALB                         $22  (14%) │ ████████
│ ElastiCache Redis           $15  (10%) │ ██████
│ CloudWatch + Logs           $8   (5%)  │ ███
│ EC2 (2x t3.micro)          $13  (9%)  │ █████
│ S3 + CloudFront             $5   (3%)  │ ██
│ Other (SNS, X-Ray, ECR)    $4   (3%)  │ ██
└─────────────────────────────────────────┘

Cost Optimization Applied:
✓ t3.micro instances (cheapest compute)
✓ GP3 storage (cheaper than GP2)
✓ S3 lifecycle policies
✓ CloudWatch log retention: 7 days
✓ ECR lifecycle: Keep only 10 images
✓ Single region deployment
✓ Fargate Spot (potential 70% savings)
```

---

## High Availability Design

```
┌─────────────────────────────────────────────────────────────────┐
│              AVAILABILITY ZONE FAILURE SCENARIO                  │
├─────────────────────────────────────────────────────────────────┤
│                                                                 │
│  If AZ-A Fails:                                                │
│  ├─ ALB automatically routes to AZ-B targets                   │
│  ├─ Auto Scaling launches new instance in AZ-B                 │
│  ├─ RDS fails over to standby in AZ-B (< 2 min)              │
│  ├─ NAT Gateway in AZ-B continues serving private subnet      │
│  └─ ECS tasks rescheduled in AZ-B                             │
│                                                                 │
│  Result: Zero downtime for users                               │
│          RTO: < 5 minutes                                      │
│          RPO: 0 (synchronous Multi-AZ replication)             │
│                                                                 │
└─────────────────────────────────────────────────────────────────┘
```

---

## Key Architecture Decisions

| Component | Decision | Rationale |
|-----------|----------|-----------|
| **Compute** | EC2 + ECS Fargate | Hybrid approach: traditional + serverless |
| **Database** | RDS Multi-AZ | Automatic failover, managed backups |
| **Caching** | ElastiCache Redis | Sub-millisecond latency, session storage |
| **Load Balancing** | ALB | Layer 7, path-based routing, health checks |
| **Networking** | Multi-AZ NAT | High availability for private subnet egress |
| **CDN** | CloudFront | Global edge locations, SSL offload |
| **Container Registry** | ECR | Private, integrated with ECS |
| **Monitoring** | CloudWatch + X-Ray | Full observability stack |
| **IaC** | Terraform | Reproducible, version-controlled infrastructure |
| **CI/CD** | GitHub Actions | Automated deployments, manual approval gate |

---

## Production-Ready Features

✅ **High Availability**: Multi-AZ deployment across 2 availability zones
✅ **Auto Scaling**: Dynamic scaling based on CPU utilization
✅ **Load Balancing**: ALB with health checks and SSL termination
✅ **Database**: Multi-AZ RDS with automated backups
✅ **Caching**: ElastiCache Redis for performance
✅ **CDN**: CloudFront for global content delivery
✅ **Monitoring**: CloudWatch dashboards, alarms, and logs
✅ **Tracing**: X-Ray distributed tracing
✅ **Security**: Defense in depth with 5 security layers
✅ **Encryption**: At rest and in transit
✅ **Service Discovery**: AWS Cloud Map for ECS
✅ **Containerization**: Docker + ECS Fargate serverless
✅ **IaC**: Complete Terraform automation
✅ **CI/CD**: GitHub Actions pipeline
✅ **Cost Optimized**: ~$152/month with optimization strategies

---

## Technology Stack

**Cloud Provider**: AWS
**Infrastructure as Code**: Terraform
**Compute**: EC2 (t3.micro), ECS Fargate
**Containers**: Docker, Amazon ECR
**Networking**: VPC, ALB, Route 53, CloudFront
**Database**: RDS MySQL (Multi-AZ)
**Caching**: ElastiCache Redis
**Storage**: S3 with versioning and encryption
**Monitoring**: CloudWatch, X-Ray, SNS
**Security**: Security Groups, IAM, Secrets Manager
**Service Discovery**: AWS Cloud Map
**CI/CD**: GitHub Actions
**Operating System**: Amazon Linux 2, Alpine Linux (containers)
**Web Server**: Apache HTTP Server, Node.js

---

This architecture demonstrates enterprise-grade AWS skills with production-ready patterns!
