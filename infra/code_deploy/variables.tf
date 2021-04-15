variable "name" {
  type = string
}

variable "ecs_cluster_name" {
  type = string
}

variable "ecs_service_name" {
  type = string
}

variable "alb_listener_arn" {
  type = string
}

variable "alb_blue_target_group_name" {
  type = string
}

variable "alb_green_target_group_name" {
  type = string
}