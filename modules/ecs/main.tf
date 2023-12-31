resource "aws_ecs_cluster" "fargate_cluster" {
  name = var.cluster_name
}

resource "aws_ecs_cluster_capacity_providers" "ecs_capacity_provider" {
  cluster_name = aws_ecs_cluster.fargate_cluster.name

  capacity_providers = ["FARGATE"]

  default_capacity_provider_strategy {
    base              = 1
    weight            = 100
    capacity_provider = "FARGATE"
  }
}

resource "aws_ecs_task_definition" "dbt_docs_task_def" {
  family                   = "dbt_docs_generate"
  requires_compatibilities = ["FARGATE"]
  network_mode             = "awsvpc"
  cpu                      = 256
  memory                   = 512
  execution_role_arn       = var.ecs_task_execution_role_arn
  task_role_arn            = var.ecs_task_execution_role_arn

  container_definitions = jsonencode([
    {
      name      = "dbt-images"
      image     = "${aws_ecr_repository.ecr_repo.repository_url}:latest"
      essential = true
      secrets = [
            {
              name       = "GITHUB_TOKEN",
              valueFrom = "arn:aws:ssm:eu-west-1:731247769824:parameter/GITHUB_TOKEN"
            },
      {
          name  = "DBT_DOCS_BUCKET"
          valueFrom = "arn:aws:ssm:eu-west-1:731247769824:parameter/DBT_DOCS_BUCKET"
        },
      {
          name  = "SNOWFLAKE_ACCOUNT"
          valueFrom = "arn:aws:ssm:eu-west-1:731247769824:parameter/SNOWFLAKE_ACCOUNT"
        },
        {
          name  = "SNOWFLAKE_PASSWORD"
          valueFrom = "arn:aws:ssm:eu-west-1:731247769824:parameter/SNOWFLAKE_PASSWORD"
        },
        {
          name  = "SNOWFLAKE_USERNAME"
          valueFrom = "arn:aws:ssm:eu-west-1:731247769824:parameter/SNOWFLAKE_USERNAME"
        }]
      environment = [
        {
          name  = "DBT_JOB_PATH"
          value = "jobs/dbt_docs.sh"
        },
        {
          name = "branch"
          value = "master"
        }]
      logConfiguration = {
        logDriver = "awslogs",
        options = {
          "awslogs-group"         = "/ecs/dbt_docs_generate",
          "awslogs-region"        = "eu-west-1",
          "awslogs-stream-prefix" = "ecs"
        }
      }
    }
  ])
}

resource "aws_ecs_task_definition" "dbt_daily_run_def" {
  family                   = "dbt_daily_run"
  requires_compatibilities = ["FARGATE"]
  network_mode             = "awsvpc"
  cpu                      = 256
  memory                   = 512
  execution_role_arn       = var.ecs_task_execution_role_arn
  task_role_arn            = var.ecs_task_execution_role_arn

  container_definitions = jsonencode([
    {
      name        = "dbt-images"
      image       = "${aws_ecr_repository.ecr_repo.repository_url}:latest"
      essential   = true
      secrets = [
        {
              name       = "GITHUB_TOKEN",
              valueFrom = "arn:aws:ssm:eu-west-1:731247769824:parameter/GITHUB_TOKEN"
            },
      {
          name  = "SNOWFLAKE_ACCOUNT"
          valueFrom = "arn:aws:ssm:eu-west-1:731247769824:parameter/SNOWFLAKE_ACCOUNT"
        },
        {
          name  = "SNOWFLAKE_PASSWORD"
          valueFrom = "arn:aws:ssm:eu-west-1:731247769824:parameter/SNOWFLAKE_PASSWORD"
        },
        {
          name  = "SNOWFLAKE_USERNAME"
          valueFrom = "arn:aws:ssm:eu-west-1:731247769824:parameter/SNOWFLAKE_USERNAME"
        }]
      environment = [
        {
          name  = "DBT_JOB_PATH"
          value = "jobs/dbt_daily_run.sh"
        },
        {
          name = "branch"
          value = "master"
        }]
      logConfiguration = {
        logDriver = "awslogs",
        options = {
          "awslogs-group"         = "/ecs/dbt_daily_run",
          "awslogs-region"        = "eu-west-1",
          "awslogs-stream-prefix" = "ecs"
        }
      }
      runtime_platform =  {
    operating_system_family = "LINUX"
    cpu_architecture        = "X86_64"
  }
    }
  ])
}

resource "aws_ecr_repository" "ecr_repo" {
  name = "dbt-images"
}

resource "aws_cloudwatch_event_rule" "dbt_daily_run" {
  name                = "dbtDailyRun"
  description         = "dbt Daily Refresh"
  schedule_expression = "cron(0 * * * ? *)"
}

resource "aws_cloudwatch_event_target" "ecs_scheduled_dbt_daily_run" {
  target_id = "run-scheduled-task-every-hour"
  arn       = aws_ecs_cluster.fargate_cluster.arn
  rule      = aws_cloudwatch_event_rule.dbt_daily_run.name
  role_arn  = var.ecs_task_execution_role_arn

  ecs_target {
    task_count          = 1
    task_definition_arn = aws_ecs_task_definition.dbt_daily_run_def.arn
    enable_execute_command = false
    enable_ecs_managed_tags = true
    launch_type = "FARGATE"
    network_configuration {
    subnets = [var.ecs_task_subnet]
      assign_public_ip = true
    }
  }
}

resource "aws_cloudwatch_event_rule" "dbt_docs" {
  name                = "dbtDocs"
  description         = "dbt docs"
  schedule_expression = "cron(0 * * * ? *)"
}

resource "aws_cloudwatch_event_target" "ecs_scheduled_task" {
  target_id = "run-scheduled-task-every-hour"
  arn       = aws_ecs_cluster.fargate_cluster.arn
  rule      = aws_cloudwatch_event_rule.dbt_docs.name
  role_arn  = var.ecs_task_execution_role_arn

  ecs_target {
    task_count          = 1
    task_definition_arn = aws_ecs_task_definition.dbt_docs_task_def.arn
    enable_execute_command = false
    enable_ecs_managed_tags = true
    launch_type = "FARGATE"
    network_configuration {
    subnets = [var.ecs_task_subnet]
      assign_public_ip = true
    }
  }
}

resource "aws_cloudwatch_log_group" "log_group_dbt_docs_task" {
  name = "/ecs/${aws_ecs_task_definition.dbt_docs_task_def.family}"
}

resource "aws_cloudwatch_log_group" "log_group_dbt_daily_run" {
  name = "/ecs/${aws_ecs_task_definition.dbt_daily_run_def.family}"
}