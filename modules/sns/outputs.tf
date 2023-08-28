output "sns_lambda_topic_arn" {
  value = aws_sns_topic.ecs_topic.arn
}