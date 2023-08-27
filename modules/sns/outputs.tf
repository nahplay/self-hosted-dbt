output "sns_lambda_topic" {
  value = aws_sns_topic.ecs_topic.arn
}