module "ecs" {
  source       = "./modules/ecs"
  cluster_name = "dbt-self-hosted-cluster"
}


module "cloudwatch" {
  source = "./modules/cloudwatch"
}


