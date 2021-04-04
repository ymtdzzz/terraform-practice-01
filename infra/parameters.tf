resource "aws_ssm_parameter" "sample_queue_url" {
  name        = "/${var.app_name}/${local.ws}/sample_queue_url"
  description = "[${var.app_name}] SAmple queue url"
  type        = "String"
  value       = aws_sqs_queue.sample_queue.id
}

resource "aws_ssm_parameter" "sample_queue_arn" {
  name        = "/${var.app_name}/${local.ws}/sample_queue_arn"
  description = "[${var.app_name}] Sample queue arn"
  type        = "String"
  value       = aws_sqs_queue.sample_queue.arn
}

resource "aws_ssm_parameter" "database_name" {
  name        = "/${var.app_name}/${local.ws}/database_name"
  description = "[${var.app_name}] Database name"
  type        = "SecureString"
  value       = local.database_name
}

resource "aws_ssm_parameter" "database_user" {
  name        = "/${var.app_name}/${local.ws}/database_username"
  description = "[${var.app_name}] Database username"
  type        = "SecureString"
  value       = var.master_username
}

resource "aws_ssm_parameter" "database_password" {
  name        = "/${var.app_name}/${local.ws}/database_password"
  description = "[${var.app_name}] Database password"
  type        = "SecureString"
  value       = random_password.password.result
}