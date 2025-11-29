# Get latest Amazon Linux 2 AMI
data "aws_ami" "amazon_linux_2" {
  most_recent = true
  owners      = ["amazon"]

  filter {
    name   = "name"
    values = ["amzn2-ami-hvm-*-x86_64-gp2"]
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }
}

# Launch Template for EC2 instances
resource "aws_launch_template" "web" {
  name_prefix   = "${var.project_name}-${var.environment}-web-"
  image_id      = data.aws_ami.amazon_linux_2.id
  instance_type = "t2.micro" # Free tier eligible

  # Security
  vpc_security_group_ids = [module.security_groups.application_security_group_id]
  iam_instance_profile {
    name = aws_iam_instance_profile.ec2_profile.name
  }

  # User data script to install web server
  user_data = base64encode(<<-EOF
    #!/bin/bash
    yum update -y
    yum install -y httpd mysql

    # Configure Apache to listen on port 8080
    sed -i 's/Listen 80/Listen 8080/' /etc/httpd/conf/httpd.conf

    systemctl start httpd
    systemctl enable httpd

    # Get instance metadata
    INSTANCE_ID=$(curl -s http://169.254.169.254/latest/meta-data/instance-id)
    AVAILABILITY_ZONE=$(curl -s http://169.254.169.254/latest/meta-data/placement/availability-zone)

    # Database endpoint (will be populated after RDS is created)
    DB_ENDPOINT="${aws_db_instance.main.endpoint}"
    S3_BUCKET="${aws_s3_bucket.static_content.id}"

    # Create a webpage with full stack info
    cat > /var/www/html/index.html <<HTML
    <!DOCTYPE html>
    <html>
    <head>
        <title>Cloud Portfolio - Full Stack</title>
        <style>
            body {
                font-family: Arial, sans-serif;
                background: linear-gradient(135deg, #667eea 0%, #764ba2 100%);
                color: white;
                display: flex;
                justify-content: center;
                align-items: center;
                min-height: 100vh;
                margin: 0;
                padding: 20px;
            }
            .container {
                text-align: center;
                padding: 50px;
                background: rgba(255, 255, 255, 0.1);
                border-radius: 20px;
                backdrop-filter: blur(10px);
                max-width: 800px;
            }
            h1 { font-size: 3em; margin-bottom: 10px; }
            h2 { font-size: 1.5em; margin-bottom: 30px; opacity: 0.9; }
            .info {
                background: rgba(0, 0, 0, 0.2);
                padding: 20px;
                border-radius: 10px;
                margin-top: 20px;
                text-align: left;
            }
            .info p { margin: 10px 0; font-size: 1.1em; }
            .section { margin: 15px 0; }
            .section-title { font-weight: bold; color: #FFD700; }
            hr { border: 1px solid rgba(255, 255, 255, 0.2); margin: 20px 0; }
        </style>
    </head>
    <body>
        <div class="container">
            <h1>🚀 Cloud Portfolio Project</h1>
            <h2>Full Stack AWS Infrastructure</h2>

            <div class="info">
                <div class="section">
                    <p class="section-title">📡 Instance Details:</p>
                    <p>Instance ID: $INSTANCE_ID</p>
                    <p>Availability Zone: $AVAILABILITY_ZONE</p>
                    <p>Status: ✅ Healthy</p>
                </div>

                <hr>

                <div class="section">
                    <p class="section-title">✅ Connected Components:</p>
                    <p>📊 Database: $DB_ENDPOINT</p>
                    <p>📦 S3 Bucket: $S3_BUCKET</p>
                    <p>🌐 Load Balancer: Active</p>
                    <p>🔐 NAT Gateway: Online</p>
                </div>

                <hr>

                <div class="section">
                    <p class="section-title">🏗️ Architecture:</p>
                    <p>✓ Multi-AZ High Availability</p>
                    <p>✓ Auto Scaling (2-4 instances)</p>
                    <p>✓ Private Subnets</p>
                    <p>✓ Managed Database (RDS)</p>
                </div>
            </div>
        </div>
    </body>
    </html>
HTML

    # Create a health check endpoint
    echo "OK" > /var/www/html/health
  EOF
  )

  tag_specifications {
    resource_type = "instance"
    tags = {
      Name = "${var.project_name}-${var.environment}-web-server"
      Type = "web"
    }
  }

  lifecycle {
    create_before_destroy = true
  }
}

# Auto Scaling Group
resource "aws_autoscaling_group" "web" {
  name                      = "${var.project_name}-${var.environment}-web-asg"
  vpc_zone_identifier       = module.vpc.private_subnet_ids
  target_group_arns         = [aws_lb_target_group.web.arn]
  health_check_type         = "ELB"
  health_check_grace_period = 300

  min_size         = 2
  max_size         = 4
  desired_capacity = 2

  launch_template {
    id      = aws_launch_template.web.id
    version = "$Latest"
  }

  tag {
    key                 = "Name"
    value               = "${var.project_name}-${var.environment}-asg-instance"
    propagate_at_launch = true
  }

  tag {
    key                 = "Project"
    value               = var.project_name
    propagate_at_launch = true
  }
}

# Auto Scaling Policy - Target Tracking
resource "aws_autoscaling_policy" "cpu_target" {
  name                   = "${var.project_name}-${var.environment}-cpu-target"
  autoscaling_group_name = aws_autoscaling_group.web.name
  policy_type            = "TargetTrackingScaling"

  target_tracking_configuration {
    predefined_metric_specification {
      predefined_metric_type = "ASGAverageCPUUtilization"
    }
    target_value = 70.0
  }
}
