S3 Website
==========

Easily create a website on S3, with support for HTTPS and IPv6.

```
module "www_static_website" {
  source         = "JamesBelchamber/s3-website/aws"
  domain_name    = "www.yourzone.com"
  zone_id        = aws_route53_zone.yourzone_com.id
  logging_bucket = aws_s3_bucket.access-log-bucket.bucket_domain_name
  logging_prefix = "target.yourzone.com/"
}
```

You must run this module against the AWS provider in North Virginia (us-east-1) only; this module will fail in any other region.