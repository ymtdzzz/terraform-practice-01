resource "aws_ssm_parameter" "bucket_name" {
  name        = "/${var.app_name}/${local.ws}/bucket_name"
  description = "[${var.app_name}] Bucket name for static cdn resources"
  type        = "String"
  value       = local.bucket_name
}