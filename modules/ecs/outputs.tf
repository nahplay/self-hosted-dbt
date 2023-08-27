output "cluster_id" {
  value = aws_ecs_cluster.fargate_cluster.id
}

output "cluster_arn" {
  value = aws_ecs_cluster.fargate_cluster.arn
}