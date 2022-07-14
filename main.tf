data "aws_partition" "current" {}

resource "aws_cloudfront_origin_access_identity" "this" {
  comment = var.source_sub_domain != "" ? "Used for private access to s3 via cloudfront for redirect of ${var.source_sub_domain}.${var.source_zone_name} to ${var.source_zone_name}" : "Used for private access to s3 via cloudfront for redirect of ${var.source_zone_name} to ${var.source_zone_name}"
}

## ACM Cert
data "aws_route53_zone" "this" {
  name = var.source_zone_name
}

module "acm_this" {
  source  = "Lupus-Metallum/acm/aws"
  version = "1.0.1"

  domain_name               = var.source_sub_domain != "" ? "${var.source_sub_domain}.${data.aws_route53_zone.this.name}" : data.aws_route53_zone.this.name
  r53_zone_id               = data.aws_route53_zone.this.zone_id
  subject_alternative_names = []
}

## S3
data "aws_caller_identity" "current" {}

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
  statement {
    sid       = "DenyIncorrectEncryptionHeader"
    effect    = "Deny"
    actions   = ["s3:PutObject"]
    resources = ["${aws_s3_bucket.this.arn}/*"]
    principals {
      type = "AWS"
      identifiers = [
        "*",
      ]
    }
    condition {
      test     = "StringNotEquals"
      variable = "s3:x-amz-server-side-encryption"
      values   = ["AES256"]
    }
  }
  statement {
    sid       = "DenyUnEncryptedObjectUploads"
    effect    = "Deny"
    actions   = ["s3:PutObject"]
    resources = ["${aws_s3_bucket.this.arn}/*"]
    principals {
      type = "AWS"
      identifiers = [
        "*",
      ]
    }
    condition {
      test     = "Null"
      variable = "s3:x-amz-server-side-encryption"
      values   = ["true"]
    }
  }
}

resource "aws_s3_bucket" "this" {
  bucket        = var.name
  force_destroy = true

  lifecycle {
    replace_triggered_by = [
      aws_cloudfront_origin_access_identity.this
    ]
  }
}

resource "aws_s3_bucket_acl" "this" {
  bucket = aws_s3_bucket.this.id
  acl    = "private"
  depends_on = [
    aws_s3_bucket.this
  ]
}

resource "aws_s3_bucket_ownership_controls" "this" {
  bucket = aws_s3_bucket.this.id

  rule {
    object_ownership = "BucketOwnerEnforced"
  }
  depends_on = [
    aws_s3_bucket.this,
    aws_s3_bucket_acl.this
  ]
}

resource "aws_s3_bucket_server_side_encryption_configuration" "this" {
  bucket = aws_s3_bucket.this.bucket

  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
  }
  depends_on = [
    aws_s3_bucket.this,
    aws_s3_bucket_acl.this,
    aws_s3_bucket_ownership_controls.this
  ]
}

resource "aws_s3_bucket_website_configuration" "this" {
  bucket = aws_s3_bucket.this.bucket
  index_document {
    suffix = "index.html"
  }
  error_document {
    key = "error.html"
  }
  depends_on = [
    aws_s3_bucket.this,
    aws_s3_bucket_acl.this,
    aws_s3_bucket_ownership_controls.this,
    aws_s3_bucket_server_side_encryption_configuration.this
  ]

}

resource "aws_s3_bucket_policy" "this" {
  bucket = aws_s3_bucket.this.id
  policy = data.aws_iam_policy_document.s3_this.json

  depends_on = [
    aws_s3_bucket.this,
    aws_s3_bucket_acl.this,
    aws_s3_bucket_ownership_controls.this,
    aws_s3_bucket_server_side_encryption_configuration.this,
    aws_s3_bucket_website_configuration.this
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
    aws_s3_bucket_acl.this,
    aws_s3_bucket_ownership_controls.this,
    aws_s3_bucket_server_side_encryption_configuration.this,
    aws_s3_bucket_website_configuration.this,
    aws_s3_bucket_policy.this
  ]
}

## Cloudfront
resource "aws_cloudfront_function" "this" {
  name    = var.name
  runtime = "cloudfront-js-1.0"
  comment = var.description
  publish = true
  code = templatefile("${path.module}/src/index.js.tpl", {
    REDIRECT_URL       = var.redirect_url,
    REDIRECT_HTTP_CODE = var.redirect_http_code,
  })
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
  comment         = var.source_sub_domain != "" ? "Redirect ${var.source_sub_domain}.${var.source_zone_name} to ${var.redirect_url}" : "Redirect ${var.source_zone_name} to ${var.redirect_url}"

  aliases = var.source_sub_domain != "" ? ["${var.source_sub_domain}.${var.source_zone_name}"] : [var.source_zone_name]
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
    function_association {
      event_type   = "viewer-request"
      function_arn = aws_cloudfront_function.this.arn
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
    minimum_protocol_version       = "TLSv1.2_2021"
    ssl_support_method             = "sni-only"
    acm_certificate_arn            = module.acm_this.cert_arn
  }
}

## Route53
resource "aws_route53_record" "a_this" {
  zone_id = data.aws_route53_zone.this.zone_id
  name    = var.source_sub_domain != "" ? "${var.source_sub_domain}.${data.aws_route53_zone.this.name}" : data.aws_route53_zone.this.name
  type    = "A"

  alias {
    name                   = aws_cloudfront_distribution.this.domain_name
    zone_id                = "Z2FDTNDATAQYW2"
    evaluate_target_health = false
  }
}

resource "aws_route53_record" "aaaa_this" {
  count   = var.cloudfront_ipv6 == true ? 1 : 0
  zone_id = data.aws_route53_zone.this.zone_id
  name    = var.source_sub_domain != "" ? "${var.source_sub_domain}.${data.aws_route53_zone.this.name}" : data.aws_route53_zone.this.name
  type    = "AAAA"

  alias {
    name                   = aws_cloudfront_distribution.this.domain_name
    zone_id                = "Z2FDTNDATAQYW2"
    evaluate_target_health = false
  }
}