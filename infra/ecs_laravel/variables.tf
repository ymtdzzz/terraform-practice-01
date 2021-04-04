variable "name" {
  type = string
}

variable "vpc_id" {
  type = string
}

variable "ecr_laravel_repo" {
  type = string
}

variable "ecr_apache_repo" {
  type = string
}

variable "https_listener_arn" {
  type = string
}

variable "subnet_ids" {
  type = list(any)
}

variable "route_table_id" {
  type = string
}