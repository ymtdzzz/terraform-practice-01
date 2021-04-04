terraform {
  required_version = "= 0.14.9"
  backend "s3" {
    bucket = "dev.zeroclock.terraformpractice.tfstate"
    key    = "terraform.tfstate"
    region = "us-east-1"
  }
}

provider "aws" {
  region = "us-east-1"
}

module "static_cdn" {
  source = "./static_cdn"

  app_name      = var.app_name
  asset_domain  = "${terraform.workspace}-assets.${var.hosted_domain}"
  hosted_domain = var.hosted_domain
}

module "ecs_laravel" {
  source = "./ecs_laravel"

  name               = var.app_name
  vpc_id             = aws_vpc.main.id
  https_listener_arn = aws_lb_listener.https.arn
  subnet_ids = [
    aws_subnet.private_1a.id,
    aws_subnet.private_1c.id,
    aws_subnet.private_1d.id
  ]
  route_table_id = aws_route_table.private.id

  ecr_laravel_repo = var.ecr_laravel_repo
  ecr_apache_repo  = var.ecr_apache_repo
}