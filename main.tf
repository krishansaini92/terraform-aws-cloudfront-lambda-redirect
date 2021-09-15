## Lambda
data "aws_partition" "current" {}


resource "aws_iam_role" "execution_role" {
  name               = "${var.name}-execution-role"
  assume_role_policy = <<-EOF
  {
    "Version": "2012-10-17",
    "Statement": [
      {
        "Action": "sts:AssumeRole",
        "Principal": {
          "Service": [
            "lambda.amazonaws.com",
            "edgelambda.amazonaws.com"
          ]
        },
        "Effect": "Allow",
        "Sid": ""
      }
    ]
  }
  EOF
  tags               = var.tags
}

data "aws_iam_policy_document" "execution_role" {
  statement {
    sid = "AllowCloudWatchLogs"
    actions = [
      "logs:CreateLogGroup",
      "logs:CreateLogStream",
      "logs:PutLogEvents"
    ]
    effect = "Allow"
    resources = [
      format(
        "arn:%s:logs:*::log-group:/aws/lambda/*:*:*",
        data.aws_partition.current.partition
      )
    ]
  }
}

resource "aws_iam_policy" "execution_role" {
  name   = "${var.name}-policy"
  path   = "/"
  policy = data.aws_iam_policy_document.execution_role.json
}

resource "aws_iam_role_policy_attachment" "execution_role" {
  role       = aws_iam_role.execution_role.name
  policy_arn = aws_iam_policy.execution_role.arn
}

data "template_file" "this" {
  template = "${file("${path.module}/src/index.js.tpl")}"
  vars = {
    REDIRECT_HTTP_CODE = var.redirect_http_code,
    REDIRECT_PROTO     = var.redirect_to_https == true ? "https" : "http",
    REDIRECT_URL       = var.redirect_url,
  }
}

data "archive_file" "this" {
  type        = "zip"
  source_file = data.template_file.this.rendered
  output_path = "${path.module}/deploy.zip"
}

resource "aws_lambda_function" "this" {
  function_name    = var.name
  description      = var.description
  filename         = data.archive_file.this.output_path
  source_code_hash = data.archive_file.this.output_base64sha256
  handler          = "index.handler"
  runtime          = "nodejs12.x"
  role             = aws_iam_role.execution_role.arn
  timeout          = var.timeout
  memory_size      = var.memory_size
  publish          = true
  tags = var.tags
  depends_on = [
    data.archive_file.this
  ]
}

## ACM Cert
data "aws_route53_zone" "this" {
  name = var.source_zone_name
}

module "acm_this" {
  source  = "Lupus-Metallum/acm/aws"
  version = "1.0.1"

  domain_name               = data.aws_route53_zone.this.name
  r53_zone_id               = data.aws_route53_zone.this.zone_id
  subject_alternative_names = []
}

## S3
data "aws_caller_identity" "current" {}

resource "aws_s3_bucket" "this" {
  bucket        = "${var.source_zone_name}-redirect"
  force_destroy = false
  acl           = "private"

  website {
    error_document = "error.html"
    index_document = "index.html"
  }
}

data "aws_iam_policy_document" "s3_this" {
  statement {
    sid       = "CloudFrontOriginAccessIdentity"
    actions   = ["s3:GetObject"]
    resources = ["${aws_s3_bucket.this.arn}/*"]
    principals {
      type        = "AWS"
      identifiers = [aws_cloudfront_origin_access_identity.this.iam_arn]
    }
  }
  statement {
    sid       = "AdminAccess"
    actions   = ["s3:*"]
    effect    = "Allow"
    resources = ["${aws_s3_bucket.this.arn}/*", aws_s3_bucket.this.arn]
    principals {
      type = "AWS"
      identifiers = [
        "arn:aws:iam::${data.aws_caller_identity.current.account_id}:root",
      ]
    }
  }
}

resource "aws_s3_bucket_policy" "this" {
  bucket = aws_s3_bucket.this.id
  policy = data.aws_iam_policy_document.s3_this.json
  depends_on = [
    aws_s3_bucket.this
  ]
}

resource "aws_s3_bucket_public_access_block" "this" {
  bucket                  = aws_s3_bucket.this.id
  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
  depends_on = [
    aws_s3_bucket.this,
    aws_s3_bucket_policy.this
  ]
}


## Cloudfront
resource "aws_cloudfront_origin_access_identity" "this" {
  comment = "Used for private access to s3 via cloudfront for redirect of ${var.source_zone_name}"
}

resource "aws_cloudfront_distribution" "this" {
  origin {
    domain_name = aws_s3_bucket.this.bucket_domain_name
    origin_id   = aws_s3_bucket.this.id
    s3_origin_config {
      origin_access_identity = aws_cloudfront_origin_access_identity.this.cloudfront_access_identity_path
    }
  }

  enabled         = true
  is_ipv6_enabled = var.cloudfront_ipv6
  comment         = "Redirect ${var.source_zone_name} to ${var.redirect_url}"

  aliases = [var.source_zone_name]
  default_cache_behavior {
    allowed_methods  = ["GET", "HEAD"]
    cached_methods   = ["GET", "HEAD"]
    target_origin_id = aws_s3_bucket.this.id

    viewer_protocol_policy = "redirect-to-https"
    cache_policy_id        = "658327ea-f89d-4fab-a63d-7e88639e58f6"
    min_ttl                = 0
    default_ttl            = 0
    max_ttl                = 0
    compress               = true
    lambda_function_association {
      event_type   = "viewer-response"
      include_body = false
      lambda_arn   = aws_lambda_function.this.qualified_arn
    }
  }
  price_class = "PriceClass_100"
  restrictions {
    geo_restriction {
      restriction_type = "whitelist"
      locations        = ["US", "CA"]
    }
  }
  viewer_certificate {
    cloudfront_default_certificate = false
    minimum_protocol_version       = "TLSv1.2_2019"
    ssl_support_method             = "sni-only"
    acm_certificate_arn            = module.acm_this.cert_arn
  }
  depends_on = [
    aws_cloudfront_origin_access_identity.this,
  ]
}

## Route53
resource "aws_route53_record" "a_this" {
  zone_id = data.aws_route53_zone.this.zone_id
  name    = data.aws_route53_zone.this.name
  type    = "A"

  alias {
    name                   = aws_cloudfront_distribution.this.domain_name
    zone_id                = "Z2FDTNDATAQYW2"
    evaluate_target_health = false
  }
}

resource "aws_route53_record" "aaaa_this" {
  count = var.cloudfront_ipv6 == true ? 1 : 0
  zone_id = data.aws_route53_zone.this.zone_id
  name    = data.aws_route53_zone.this.name
  type    = "AAAA"

  alias {
    name                   = aws_cloudfront_distribution.this.domain_name
    zone_id                = "Z2FDTNDATAQYW2"
    evaluate_target_health = false
  }
}