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