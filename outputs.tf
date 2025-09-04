output "api_endpoint" {
  value = aws_apigatewayv2_api.http.api_endpoint
}
output "cloudfront_domain" {
  value = aws_cloudfront_distribution.cdn.domain_name
}
output "frontend_bucket" {
  value = aws_s3_bucket.frontend.bucket
}
