variable "tags" {
  default     = {}
  type        = map(string)
  description = "Tags to add to resouces created by this module"
}

variable "name" {
  type        = string
  description = "Name to use for resource names created by this module"
}

variable "description" {
  type        = string
  description = "Description to use for resource description created by this module"
  default     = "Redirect to new URL"
}

variable "timeout" {
  type        = number
  default     = 1
  description = "Timeout to use for Lambda, defaults to 1ms"
}

variable "memory_size" {
  type        = number
  default     = 128
  description = "Memory to use for Lambda, defaults to 128mb"
}

variable "redirect_to_https" {
  type        = bool
  default     = true
  description = "Should redirect URL use HTTPS?"
}

variable "redirect_url" {
  type        = string
  description = "What redirect url should we redirect to? example: 'example.com/123/456'"
}

variable "redirect_http_code" {
  type        = number
  default     = 302
  description = "What HTTP Redirect code should we use?"
}

variable "source_zone_name" {
  type        = string
  description = "What is the r53 zone name of the source url?"
}

variable "source_sub_domain" {
  type        = string
  description = "What is the subdomain name of the source url?"
  default     = ""
}

variable "cloudfront_ipv6" {
  type        = bool
  default     = true
  description = "Should we configure the cloudfront distribution for IPv6?"
}

variable "response_headers_policy_id" {
  type        = string
  default     = ""
  description = "Should we add a response headers policy to the CloudFront distrobution created by this module?"
}
