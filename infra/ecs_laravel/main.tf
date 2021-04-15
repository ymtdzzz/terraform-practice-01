data "aws_region" "current" {}

data "aws_caller_identity" "current" {}

locals {
  ws                     = terraform.workspace
  name                   = "${var.name}-${local.ws}"
  region                 = data.aws_region.current.name
  apache_container_name  = "${local.name}-apache"
  laravel_container_name = "${local.name}-laravel"
}

# ECR

resource "aws_ecr_repository" "apache" {
  name                 = "${local.name}-apache"
  image_tag_mutability = "MUTABLE"

  image_scanning_configuration {
    scan_on_push = false
  }
}

resource "aws_ecr_repository" "laravel" {
  name                 = "${local.name}-laravel"
  image_tag_mutability = "MUTABLE"

  image_scanning_configuration {
    scan_on_push = false
  }
}

resource "aws_ecr_repository_policy" "apache" {
  repository = aws_ecr_repository.apache.name

  policy = <<EOF
{
  "Version": "2008-10-17",
  "Statement": [
    {
      "Sid": "new policy",
      "Effect": "Allow",
      "Principal": "*",
      "Action": [
        "ecr:GetDownloadUrlForLayer",
        "ecr:BatchGetImage",
        "ecr:BatchCheckLayerAvailability",
        "ecr:PutImage",
        "ecr:InitiateLayerUpload",
        "ecr:UploadLayerPart",
        "ecr:CompleteLayerUpload",
        "ecr:DescribeRepositories",
        "ecr:GetRepositoryPolicy",
        "ecr:ListImages",
        "ecr:DeleteRepository",
        "ecr:BatchDeleteImage",
        "ecr:SetRepositoryPolicy",
        "ecr:DeleteRepositoryPolicy"
      ]
    }
  ]
}
EOF
}

resource "aws_ecr_repository_policy" "laravel" {
  repository = aws_ecr_repository.laravel.name

  policy = <<EOF
{
  "Version": "2008-10-17",
  "Statement": [
    {
      "Sid": "new policy",
      "Effect": "Allow",
      "Principal": "*",
      "Action": [
        "ecr:GetDownloadUrlForLayer",
        "ecr:BatchGetImage",
        "ecr:BatchCheckLayerAvailability",
        "ecr:PutImage",
        "ecr:InitiateLayerUpload",
        "ecr:UploadLayerPart",
        "ecr:CompleteLayerUpload",
        "ecr:DescribeRepositories",
        "ecr:GetRepositoryPolicy",
        "ecr:ListImages",
        "ecr:DeleteRepository",
        "ecr:BatchDeleteImage",
        "ecr:SetRepositoryPolicy",
        "ecr:DeleteRepositoryPolicy"
      ]
    }
  ]
}
EOF
}

### ECR & CloudwatchLogs PrivateLink start ###

resource "aws_security_group" "vpc_endpoint" {
  name        = "${local.name}-vpc-endpoint"
  description = "${local.name}-vpc-endpoint"

  vpc_id = var.vpc_id

  ingress {
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "${local.name}-vpc-endpoint"
  }
}

resource "aws_vpc_endpoint" "vpc_endpoint_ecr_api" {
  service_name      = "com.amazonaws.us-east-1.ecr.api"
  vpc_endpoint_type = "Interface"
  vpc_id            = var.vpc_id
  subnet_ids        = var.subnet_ids

  security_group_ids = [aws_security_group.vpc_endpoint.id]

  private_dns_enabled = true
}

resource "aws_vpc_endpoint" "vpc_endpoint_ecr_dkr" {
  service_name      = "com.amazonaws.us-east-1.ecr.dkr"
  vpc_endpoint_type = "Interface"
  vpc_id            = var.vpc_id
  subnet_ids        = var.subnet_ids

  security_group_ids = [aws_security_group.vpc_endpoint.id]

  private_dns_enabled = true
}

resource "aws_vpc_endpoint" "vpc_endpoint_for_s3" {
  vpc_id       = var.vpc_id
  service_name = "com.amazonaws.us-east-1.s3"

  route_table_ids = [
    var.route_table_id
  ]
}

resource "aws_vpc_endpoint" "vpc_endpoint_for_cloudwatch" {
  service_name      = "com.amazonaws.us-east-1.logs"
  vpc_endpoint_type = "Interface"
  vpc_id            = var.vpc_id
  subnet_ids        = var.subnet_ids

  security_group_ids = [aws_security_group.vpc_endpoint.id]

  private_dns_enabled = true
}

resource "aws_vpc_endpoint" "vpc_endpoint_sqs" {
  service_name      = "com.amazonaws.us-east-1.sqs"
  vpc_endpoint_type = "Interface"
  vpc_id            = var.vpc_id
  subnet_ids        = var.subnet_ids

  security_group_ids = [aws_security_group.vpc_endpoint.id]

  private_dns_enabled = true
}

### ECR PrivateLink end ###

resource "aws_lb_target_group" "this" {
  name = "${local.name}-blue"

  vpc_id = var.vpc_id

  port        = 80
  target_type = "ip"
  protocol    = "HTTP"

  health_check {
    port = 80
    path = "/"
  }
}

resource "aws_lb_target_group" "this_green" {
  name = "${local.name}-green"

  vpc_id = var.vpc_id

  port        = 80
  target_type = "ip"
  protocol    = "HTTP"

  health_check {
    port = 80
    path = "/"
  }
}

data "template_file" "container_definitions" {
  template = file("./ecs_laravel/container_definitions.json")

  vars = {
    // TODO: change it to specific version
    tag = "latest"

    region                 = local.region
    name                   = var.name
    stage                  = local.ws
    ecr_laravel_repo       = aws_ecr_repository.laravel.repository_url
    ecr_apache_repo        = aws_ecr_repository.apache.repository_url
    apache_container_name  = local.apache_container_name
    laravel_container_name = local.laravel_container_name
  }
}

resource "aws_ecs_task_definition" "this" {
  family = local.name

  container_definitions = data.template_file.container_definitions.rendered

  cpu                      = "256"
  memory                   = "512"
  network_mode             = "awsvpc"
  requires_compatibilities = ["FARGATE"]

  task_role_arn      = aws_iam_role.task_execution.arn
  execution_role_arn = aws_iam_role.task_execution.arn
}

resource "aws_cloudwatch_log_group" "this" {
  name              = "/${var.name}/${local.ws}/ecs"
  retention_in_days = "7"
}

resource "aws_iam_role" "task_execution" {
  name = "${local.name}-TaskExecution"

  assume_role_policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Action": "sts:AssumeRole",
      "Principal": {
        "Service": "ecs-tasks.amazonaws.com"
      },
      "Effect": "Allow",
      "Sid": ""
    }
  ]
}
EOF
}

resource "aws_iam_role_policy" "task_execution" {
  role = aws_iam_role.task_execution.id

  policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Action": [
        "logs:CreateLogGroup",
        "logs:CreateLogStream",
        "logs:PutLogEvents",
        "logs:DescribeLogGroups",
        "logs:DescribeLogStreams",
        "ssmmessages:CreateControlChannel",
        "ssmmessages:CreateDataChannel",
        "ssmmessages:OpenControlChannel",
        "ssmmessages:OpenDataChannel"        
      ],
      "Effect": "Allow",
      "Resource": "*"
    }
  ]
}
EOF
}

resource "aws_iam_role_policy_attachment" "task_execution" {
  role       = aws_iam_role.task_execution.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonECSTaskExecutionRolePolicy"
}

resource "aws_lb_listener_rule" "this" {
  listener_arn = var.https_listener_arn

  action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.this.arn
  }

  condition {
    path_pattern {
      values = ["*"]
    }
  }
}

resource "aws_security_group" "this" {
  name        = local.name
  description = local.name

  vpc_id = var.vpc_id

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "all"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = local.name
  }
}

resource "aws_security_group_rule" "this_http" {
  security_group_id = aws_security_group.this.id

  type = "ingress"

  from_port   = 80
  to_port     = 80
  protocol    = "tcp"
  cidr_blocks = ["0.0.0.0/0"]
}

resource "aws_security_group_rule" "this_https" {
  security_group_id = aws_security_group.this.id

  type = "ingress"

  from_port   = 443
  to_port     = 443
  protocol    = "tcp"
  cidr_blocks = ["0.0.0.0/0"]
}

resource "aws_security_group_rule" "this_memcached" {
  security_group_id = aws_security_group.this.id

  type = "ingress"

  from_port   = 11211
  to_port     = 11211
  protocol    = "tcp"
  cidr_blocks = ["0.0.0.0/0"]
}

resource "aws_ecs_cluster" "this" {
  name = local.name
}

resource "aws_ecs_service" "this" {
  depends_on = [aws_lb_listener_rule.this]

  name = local.name

  launch_type = "FARGATE"

  desired_count = 1

  cluster = aws_ecs_cluster.this.name

  task_definition = aws_ecs_task_definition.this.arn

  enable_execute_command = true

  deployment_controller {
    type = "CODE_DEPLOY"
  }

  network_configuration {
    subnets          = var.subnet_ids
    security_groups  = [aws_security_group.this.id]
    assign_public_ip = false
  }

  load_balancer {
    target_group_arn = aws_lb_target_group.this.arn
    container_name   = local.apache_container_name
    container_port   = "80"
  }
}
