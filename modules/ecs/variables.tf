variable "cluster_name" {
  description = "Name of the ECS cluster"
  type = string
}

variable "ecs_task_execution_role_arn" {
  description = "IAM role arn for execution role"
  type = string
}

variable "ecs_task_subnet" {
  description = "A subnet given to task definition"
  type = string
}