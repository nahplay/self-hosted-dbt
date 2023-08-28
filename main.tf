module "ecs" {
  source       = "./modules/ecs"
  cluster_name = "dbt-self-hosted-cluster"
  ecs_task_execution_role_arn = module.iam.ecs_task_execution_role_arn
}

module "lambda" {
  source = "./modules/lambda"
}

module "sns" {
  source = "./modules/sns"
  lambda_arn = module.lambda.lambda_arn
  lambda_name = module.lambda.lambda_name
}


module "cloudwatch" {
  source = "./modules/cloudwatch"
  sns_lambda_topic_arn = module.sns.sns_lambda_topic_arn
}

module "s3" {
  source = "./modules/s3"
}

module "iam" {
  source = "./modules/iam"
}