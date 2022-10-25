# terraform-module-template
Used to redirect domain examplea.com to exampleb.com, or test.examplea.com to exampleb.com.

## Example
``` terraform
module "redirect" {
  source             = "Lupus-Metallum/cloudfront-lambda-redirect/aws"
  version            = "2.0.1"
  name               = "example-redirect"
  source_zone_name   = "examplea.com"
  source_sub_domain  = "test"
  redirect_url       = "https://exampleb.com"
  redirect_http_code = 302
  redirect_to_https  = true
  cloudfront_ipv6    = true
}
```
<!-- BEGIN_TF_DOCS -->


## Providers

| Name | Version |
|------|---------|
| <a name="provider_aws"></a> [aws](#provider\_aws) | n/a |

## Modules

| Name | Source | Version |
|------|--------|---------|
| <a name="module_acm_this"></a> [acm\_this](#module\_acm\_this) | Lupus-Metallum/acm/aws | 1.0.1 |

## Resources

| Name | Type |
|------|------|
| [aws_cloudfront_distribution.this](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/cloudfront_distribution) | resource |
| [aws_cloudfront_function.this](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/cloudfront_function) | resource |
| [aws_cloudfront_origin_access_identity.this](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/cloudfront_origin_access_identity) | resource |
| [aws_route53_record.a_this](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/route53_record) | resource |
| [aws_route53_record.aaaa_this](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/route53_record) | resource |
| [aws_s3_bucket.this](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/s3_bucket) | resource |
| [aws_s3_bucket_acl.this](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/s3_bucket_acl) | resource |
| [aws_s3_bucket_ownership_controls.this](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/s3_bucket_ownership_controls) | resource |
| [aws_s3_bucket_policy.this](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/s3_bucket_policy) | resource |
| [aws_s3_bucket_public_access_block.this](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/s3_bucket_public_access_block) | resource |
| [aws_s3_bucket_server_side_encryption_configuration.this](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/s3_bucket_server_side_encryption_configuration) | resource |
| [aws_s3_bucket_website_configuration.this](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/s3_bucket_website_configuration) | resource |
| [aws_caller_identity.current](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/caller_identity) | data source |
| [aws_iam_policy_document.s3_this](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/iam_policy_document) | data source |
| [aws_partition.current](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/partition) | data source |
| [aws_route53_zone.this](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/route53_zone) | data source |

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| <a name="input_name"></a> [name](#input\_name) | Name to use for resource names created by this module | `string` | n/a | yes |
| <a name="input_redirect_url"></a> [redirect\_url](#input\_redirect\_url) | What redirect url should we redirect to? example: 'example.com/123/456' | `string` | n/a | yes |
| <a name="input_source_zone_name"></a> [source\_zone\_name](#input\_source\_zone\_name) | What is the r53 zone name of the source url? | `string` | n/a | yes |
| <a name="input_cloudfront_ipv6"></a> [cloudfront\_ipv6](#input\_cloudfront\_ipv6) | Should we configure the cloudfront distribution for IPv6? | `bool` | `true` | no |
| <a name="input_description"></a> [description](#input\_description) | Description to use for resource description created by this module | `string` | `"Redirect to new URL"` | no |
| <a name="input_memory_size"></a> [memory\_size](#input\_memory\_size) | Memory to use for Lambda, defaults to 128mb | `number` | `128` | no |
| <a name="input_redirect_http_code"></a> [redirect\_http\_code](#input\_redirect\_http\_code) | What HTTP Redirect code should we use? | `number` | `302` | no |
| <a name="input_redirect_to_https"></a> [redirect\_to\_https](#input\_redirect\_to\_https) | Should redirect URL use HTTPS? | `bool` | `true` | no |
| <a name="input_source_sub_domain"></a> [source\_sub\_domain](#input\_source\_sub\_domain) | What is the subdomain name of the source url? | `string` | `""` | no |
| <a name="input_tags"></a> [tags](#input\_tags) | Tags to add to resouces created by this module | `map(string)` | `{}` | no |
| <a name="input_timeout"></a> [timeout](#input\_timeout) | Timeout to use for Lambda, defaults to 1ms | `number` | `1` | no |

## Outputs

| Name | Description |
|------|-------------|
| <a name="output_arn"></a> [arn](#output\_arn) | n/a |
<!-- END_TF_DOCS -->