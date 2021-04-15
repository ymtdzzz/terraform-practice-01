data "aws_region" "current" {}

data "aws_caller_identity" "current" {}

locals {
  ws                     = terraform.workspace
  name                   = "${var.name}-${local.ws}"
  region                 = data.aws_region.current.name
  apache_container_name  = "${local.name}-apache"
  laravel_container_name = "${local.name}-laravel"
}

# S3 Bucket for CodeDeploy
resource "aws_s3_bucket" "this" {
  bucket = "${local.name}-codedeploy"
  acl = "private"
  force_destroy = true
}

# IAM Role
data "aws_iam_policy_document" "codedeploy" {
  statement {
    actions = ["sts:AssumeRole"]
    principals {
      type = "Service"
      identifiers = ["codedeploy.amazonaws.com"]
    }
  }
}

resource "aws_iam_role" "this" {
  name = local.name
  assume_role_policy = data.aws_iam_policy_document.codedeploy.json
}

resource "aws_iam_policy_attachment" "codedeploy" {
  name = local.name

  roles = [aws_iam_role.this.id]
  policy_arn = "arn:aws:iam::aws:policy/AWSCodeDeployRoleForECS"
}

resource "aws_codedeploy_app" "laravel" {
  compute_platform = "ECS"
  name = "${local.name}-laravel"
}

resource "aws_codedeploy_deployment_group" "laravel" {
  deployment_group_name = "${local.name}-laravel"
  app_name = aws_codedeploy_app.laravel.name
  deployment_config_name = "CodeDeployDefault.ECSAllAtOnce"
  service_role_arn = aws_iam_role.this.arn

  blue_green_deployment_config {
    deployment_ready_option {
      action_on_timeout = "CONTINUE_DEPLOYMENT"
    }
    terminate_blue_instances_on_deployment_success {
      action                           = "TERMINATE"
      termination_wait_time_in_minutes = 1
    }
  }

  deployment_style {
    deployment_option = "WITH_TRAFFIC_CONTROL"
    deployment_type   = "BLUE_GREEN"
  }

  auto_rollback_configuration {
    enabled = true
    events = [
      "DEPLOYMENT_FAILURE"
    ]
  }

  ecs_service {
    cluster_name = var.ecs_cluster_name
    service_name = var.ecs_service_name
  }

  load_balancer_info {
    target_group_pair_info {
      prod_traffic_route {
        listener_arns = [
          var.alb_listener_arn
        ]
      }
      target_group {
        name = var.alb_blue_target_group_name
      }
      target_group {
        name = var.alb_green_target_group_name
      }
    }
  }
}
