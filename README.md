# terraform-module-template
Used to redirect domain examplea.com to exampleb.com, subdomains are not available yet.

## Example
``` terraform
module "redirect" {
  source             = "Lupus-Metallum/cloudfront-lambda-redirect/aws"
  version            = 1.0.0
  name               = "example-redirect"
  source_zone_name   = "examplea.com"
  redirect_url       = "exampleb.com"
  redirect_http_code = 302
  redirect_to_https  = true
  cloudfront_ipv6    = true
}
```