resource "aws_iam_role" "ecs_task_execution_role" {
  name = "ecs-task-execution-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Action = "sts:AssumeRole",
        Effect = "Allow",
        Principal = {
          Service = ["ecs-tasks.amazonaws.com", "events.amazonaws.com", "scheduler.amazonaws.com"]
        }
      }
    ]
  })
}

data "aws_iam_policy_document" "allow_put_files_s3" {
  version = "2012-10-17"

  statement {
    actions = ["s3:PutObject"]
    resources = [
      var.dbt_docs_s3_bucket_arn,
      "${var.dbt_docs_s3_bucket_arn}/*",
    ]

  }
}


#resource "aws_iam_policy_attachment" "ecs_task_execution_role_attachment_s3" {
#  name       = "ecs-task-execution-role-attachment-s3"
#  roles      = [aws_iam_role.ecs_task_execution_role.name]
#  policy_arn = "arn:aws:iam::aws:policy/AmazonS3FullAccess"
#}

resource "aws_iam_policy_attachment" "ecs_task_execution_role_attachment_ecs_execution_role" {
  name       = "ecs-task-execution-role-attachment-ecs-execution-role"
  roles      = [aws_iam_role.ecs_task_execution_role.name]
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonECSTaskExecutionRolePolicy"
}

data "aws_iam_policy_document" "ecs_run_task_policy" {
  version = "2012-10-17"

  statement {
    effect    = "Allow"
    actions   = ["ecs:RunTask"]
    resources = ["*"]
  }

  statement {
    effect    = "Allow"
    actions   = ["iam:PassRole"]
    resources = ["*"]

    condition {
      test     = "StringLike"
      variable = "iam:PassedToService"
      values   = ["ecs-tasks.amazonaws.com"]
    }
  }

  statement {
    effect    = "Allow"
    actions   = ["ecs:TagResource"]
    resources = ["*"]

    condition {
      test     = "StringEquals"
      variable = "ecs:CreateAction"
      values   = ["RunTask"]
    }
  }

    statement {
      effect    = "Allow"
      actions   = ["ssm:GetParameters"]
      resources = ["arn:aws:ssm:eu-west-1:731247769824:parameter/*"]
    }
  }

resource "aws_iam_policy" "ecs_run_task" {
  name        = "ecs-run-task-policy"
  description = "IAM policy for ECS RunTask and related actions"
  policy      = data.aws_iam_policy_document.ecs_run_task_policy.json
}

resource "aws_iam_role_policy_attachment" "ecs_run_task_attachment" {
  policy_arn = aws_iam_policy.ecs_run_task.arn
  role       = aws_iam_role.ecs_task_execution_role.name
}

resource "aws_iam_policy" "ecs_store_dbt_docs_s3" {
  name        = "ecs-store_dbt_docs_s3"
  description = "IAM policy for ECS RunTask to store docs"
  policy      = data.aws_iam_policy_document.allow_put_files_s3.json
}

resource "aws_iam_role_policy_attachment" "ecs_store_dbt_docs_s3_attachment" {
  policy_arn = aws_iam_policy.ecs_store_dbt_docs_s3.arn
  role       = aws_iam_role.ecs_task_execution_role.name
}