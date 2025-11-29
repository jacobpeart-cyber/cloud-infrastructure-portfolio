# Route 53 and ACM Configuration (Optional - commented out by default)
# Uncomment and configure if you have a domain

/*
# Get existing Route 53 hosted zone
data "aws_route53_zone" "main" {
  name         = "yourdomain.com"  # Replace with your domain
  private_zone = false
}

# ACM Certificate for CloudFront (must be in us-east-1)
resource "aws_acm_certificate" "cloudfront" {
  provider          = aws.us-east-1
  domain_name       = "www.yourdomain.com"  # Replace with your domain
  validation_method = "DNS"

  subject_alternative_names = [
    "yourdomain.com",
    "*.yourdomain.com"
  ]

  lifecycle {
    create_before_destroy = true
  }

  tags = {
    Name = "${var.project_name}-${var.environment}-cloudfront-cert"
  }
}

# Route 53 records for ACM validation
resource "aws_route53_record" "cert_validation" {
  for_each = {
    for dvo in aws_acm_certificate.cloudfront.domain_validation_options : dvo.domain_name => {
      name   = dvo.resource_record_name
      record = dvo.resource_record_value
      type   = dvo.resource_record_type
    }
  }

  allow_overwrite = true
  name            = each.value.name
  records         = [each.value.record]
  ttl             = 60
  type            = each.value.type
  zone_id         = data.aws_route53_zone.main.zone_id
}

# ACM Certificate validation
resource "aws_acm_certificate_validation" "cloudfront" {
  provider                = aws.us-east-1
  certificate_arn         = aws_acm_certificate.cloudfront.arn
  validation_record_fqdns = [for record in aws_route53_record.cert_validation : record.fqdn]
}

# Route 53 A record for CloudFront (www)
resource "aws_route53_record" "www" {
  zone_id = data.aws_route53_zone.main.zone_id
  name    = "www.yourdomain.com"  # Replace with your domain
  type    = "A"

  alias {
    name                   = aws_cloudfront_distribution.main.domain_name
    zone_id                = aws_cloudfront_distribution.main.hosted_zone_id
    evaluate_target_health = false
  }
}

# Route 53 AAAA record for CloudFront IPv6 (www)
resource "aws_route53_record" "www_ipv6" {
  zone_id = data.aws_route53_zone.main.zone_id
  name    = "www.yourdomain.com"  # Replace with your domain
  type    = "AAAA"

  alias {
    name                   = aws_cloudfront_distribution.main.domain_name
    zone_id                = aws_cloudfront_distribution.main.hosted_zone_id
    evaluate_target_health = false
  }
}

# Route 53 A record for API Gateway
resource "aws_route53_record" "api" {
  zone_id = data.aws_route53_zone.main.zone_id
  name    = "api.yourdomain.com"  # Replace with your domain
  type    = "A"

  alias {
    name                   = aws_api_gateway_stage.main.invoke_url
    zone_id                = aws_api_gateway_rest_api.main.regional_zone_id
    evaluate_target_health = true
  }
}

# Update CloudFront to use custom certificate
# Uncomment the viewer_certificate block in cdn.tf and update to:
# viewer_certificate {
#   acm_certificate_arn      = aws_acm_certificate.cloudfront.arn
#   ssl_support_method       = "sni-only"
#   minimum_protocol_version = "TLSv1.2_2021"
# }
*/
