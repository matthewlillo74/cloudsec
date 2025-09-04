terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
  required_version = ">= 1.5.0"
}

provider "aws" {
  region = var.region
}

# ---------- DynamoDB ----------
resource "aws_dynamodb_table" "scans" {
  name         = var.scan_table_name
  billing_mode = "PAY_PER_REQUEST"
  hash_key     = "pk"

  attribute {
    name = "pk"
    type = "S"
  }
}

# ---------- S3 (frontend bucket) ----------
resource "random_id" "bucket_id" {
  byte_length = 4
}

resource "aws_s3_bucket" "frontend" {
  bucket = "cloud-sec-frontend-${random_id.bucket_id.hex}"

}

resource "aws_s3_bucket_website_configuration" "frontend" {
  bucket = aws_s3_bucket.frontend.id

  index_document {
    suffix = "index.html"
  }

  error_document {
    key = "index.html"
  }
}

# frontend files
resource "aws_s3_object" "index_html" {
  bucket       = aws_s3_bucket.frontend.id
  key          = "index.html"
  source       = "./frontend/index.html"
  content_type = "text/html"
}

resource "aws_s3_object" "main_js" {
  bucket       = aws_s3_bucket.frontend.id
  key          = "main.js"
  source       = "./frontend/main.js"
  content_type = "application/javascript"
}

resource "aws_s3_object" "styles_css" {
  bucket       = aws_s3_bucket.frontend.id
  key          = "styles.css"
  source       = "./frontend/styles.css"
  content_type = "text/css"
}




resource "aws_s3_bucket_ownership_controls" "frontend" {
  bucket = aws_s3_bucket.frontend.id
  rule {
    object_ownership = "BucketOwnerEnforced"
  }
}

resource "aws_s3_bucket_public_access_block" "frontend" {
  bucket = aws_s3_bucket.frontend.id

  block_public_acls       = true
  block_public_policy     = false # allow OAC policy
  ignore_public_acls      = true
  restrict_public_buckets = true
}

resource "aws_s3_bucket_versioning" "frontend" {
  bucket = aws_s3_bucket.frontend.id
  versioning_configuration {
    status = "Enabled"
  }
}

resource "aws_s3_bucket_policy" "frontend" {
  bucket = aws_s3_bucket.frontend.id
  policy = data.aws_iam_policy_document.frontend_oac.json
}

# ---------- CloudFront + OAC ----------
resource "aws_cloudfront_origin_access_control" "oac" {
  name                              = "${var.project}-oac"
  description                       = "OAC for S3 frontend"
  origin_access_control_origin_type = "s3"
  signing_behavior                  = "always"
  signing_protocol                  = "sigv4"
}

resource "aws_cloudfront_distribution" "cdn" {
  enabled             = true
  default_root_object = "index.html"

  origin {
    domain_name              = aws_s3_bucket.frontend.bucket_regional_domain_name
    origin_id                = "s3-frontend"
    origin_access_control_id = aws_cloudfront_origin_access_control.oac.id
  }

  default_cache_behavior {
    target_origin_id       = "s3-frontend"
    viewer_protocol_policy = "redirect-to-https"
    allowed_methods        = ["GET", "HEAD"]
    cached_methods         = ["GET", "HEAD"]

    forwarded_values {
      query_string = false
      cookies {
        forward = "none"
      }
    }
  }

  restrictions {
    geo_restriction {
      restriction_type = "none"
    }
  }

  viewer_certificate {
    cloudfront_default_certificate = true
  }
}

data "aws_iam_policy_document" "frontend_oac" {
  statement {
    actions   = ["s3:GetObject"]
    resources = ["${aws_s3_bucket.frontend.arn}/*"]

    principals {
      type        = "Service"
      identifiers = ["cloudfront.amazonaws.com"]
    }

    condition {
      test     = "StringEquals"
      variable = "AWS:SourceArn"
      values   = [aws_cloudfront_distribution.cdn.arn]
    }
  }
}

# ---------- IAM role for Lambda ----------
data "aws_iam_policy_document" "lambda_assume" {
  statement {
    actions = ["sts:AssumeRole"]
    principals {
      type        = "Service"
      identifiers = ["lambda.amazonaws.com"]
    }
  }
}

resource "aws_iam_role" "lambda_role" {
  name               = "${var.project}-lambda-role"
  assume_role_policy = data.aws_iam_policy_document.lambda_assume.json
}

# Least-privilege inline policy
data "aws_iam_policy_document" "lambda_policy" {
  statement {
    sid = "Logs"
    actions = [
      "logs:CreateLogGroup",
      "logs:CreateLogStream",
      "logs:PutLogEvents"
    ]
    resources = ["arn:aws:logs:*:*:*"]
  }

  statement {
    sid = "ScanCore"
    actions = [
      "ec2:DescribeSecurityGroups",
      "s3:ListAllMyBuckets",
      "s3:GetBucketAcl",
      "s3:PutBucketAcl",
      "iam:ListUsers",
      "iam:ListMFADevices",
      "iam:GetLoginProfile",
      "cloudtrail:DescribeTrails",
      "cloudtrail:StartLogging",
      "cloudtrail:CreateTrail",
      "rds:DescribeDBInstances",
      "rds:ModifyDBInstance",
      "dynamodb:PutItem"
    ]
    resources = ["*"]
  }
}

resource "aws_iam_policy" "lambda_inline" {
  name   = "${var.project}-lambda-policy"
  policy = data.aws_iam_policy_document.lambda_policy.json
}

resource "aws_iam_role_policy_attachment" "lambda_attach" {
  role       = aws_iam_role.lambda_role.name
  policy_arn = aws_iam_policy.lambda_inline.arn
}

# ---------- Lambda function ----------
resource "aws_lambda_function" "api" {
  function_name = "${var.project}-api"
  role          = aws_iam_role.lambda_role.arn
  handler       = "api.handler"
  runtime       = "python3.12"
  filename      = var.lambda_zip
  timeout       = 30

  environment {
    variables = {
      SCAN_TABLE = aws_dynamodb_table.scans.name
    }
  }
}

# ---------- API Gateway ----------
resource "aws_apigatewayv2_api" "http" {
  name          = "${var.project}-http"
  protocol_type = "HTTP"
 cors_configuration {
    allow_origins = ["*"]               # lock down later to your CloudFront domain
    allow_methods = ["GET","POST","OPTIONS"]
    allow_headers = ["content-type"]
  }
}


resource "aws_apigatewayv2_integration" "lambda" {
  api_id                 = aws_apigatewayv2_api.http.id
  integration_type       = "AWS_PROXY"
  integration_uri        = aws_lambda_function.api.arn
  payload_format_version = "2.0"
}

resource "aws_apigatewayv2_route" "scan" {
  api_id    = aws_apigatewayv2_api.http.id
  route_key = "GET /scan"
  target    = "integrations/${aws_apigatewayv2_integration.lambda.id}"
}

resource "aws_apigatewayv2_route" "remediate_s3" {
  api_id    = aws_apigatewayv2_api.http.id
  route_key = "POST /remediate/s3/{bucket_name}"
  target    = "integrations/${aws_apigatewayv2_integration.lambda.id}"
}

resource "aws_apigatewayv2_route" "remediate_sg" {
  api_id    = aws_apigatewayv2_api.http.id
  route_key = "POST /remediate/sg/{sg_id}"
  target    = "integrations/${aws_apigatewayv2_integration.lambda.id}"
}

resource "aws_apigatewayv2_route" "remediate_rds" {
  api_id    = aws_apigatewayv2_api.http.id
  route_key = "POST /remediate/rds/{db_identifier}"
  target    = "integrations/${aws_apigatewayv2_integration.lambda.id}"
}

resource "aws_lambda_permission" "apigw_invoke" {
  statement_id  = "AllowInvokeFromAPIGW"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.api.function_name
  principal     = "apigateway.amazonaws.com"
  source_arn    = "${aws_apigatewayv2_api.http.execution_arn}/*/*"
}

resource "aws_apigatewayv2_stage" "prod" {
  api_id      = aws_apigatewayv2_api.http.id
  name        = "$default"
  auto_deploy = true
}
