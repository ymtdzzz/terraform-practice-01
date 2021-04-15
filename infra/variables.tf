variable "app_name" {
  type    = string
  default = "terraform-practice"
}

variable "hosted_domain" {
  type    = string
  default = "terraformpractice.zeroclock.dev"
}

variable "vpc_cidr" {
  type = string
  default = "10.0.0.0/16"
}

variable "master_username" {
  type    = string
  default = "masteruser"
}

variable "ecr_laravel_repo" {
  type    = string
  default = "terraformpractice-laravel"
}

variable "ecr_apache_repo" {
  type    = string
  default = "terraformpractice-apache"
}