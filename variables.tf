variable "region" {
  type    = string
  default = "us-east-1"
}
variable "project" {
  type    = string
  default = "cloud-sec-platform"
}
variable "frontend_bucket" {
  type    = string
  default = "your-unique-frontend-bucket-name"
}
variable "scan_table_name" {
  type    = string
  default = "cloud-sec-scans"
}
variable "lambda_zip" {
  type    = string
  default = "../api/dist/lambda.zip"
}
