terraform {
  backend "s3" {
    bucket         = "self-hosted-dbt-maksym-state"
    key            = "ecs-cluster.tfstate"
    region         = "eu-west-1"
    encrypt        = true
  }
}