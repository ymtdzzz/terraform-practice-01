output "ecs_cluster_name" {
  value = aws_ecs_cluster.this.name
}

output "ecs_service_name" {
  value = aws_ecs_service.this.name
}

output "ecs_alb_blue_target_group_name" {
  value = aws_lb_target_group.this.name
}

output "ecs_alb_green_target_group_name" {
  value = aws_lb_target_group.this_green.name
}