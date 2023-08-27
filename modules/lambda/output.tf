output "lambda_arn" {
  value = aws_lambda_function.slack_lambda.arn
}

output "lambda_name" {
  value = aws_lambda_function.slack_lambda.function_name
}