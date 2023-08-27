module "sns" {
  source = "../sns"
}

resource "aws_cloudwatch_event_rule" "ecs_rule" {
  name        = "capture-dbt-jobs-rule"

  event_pattern = jsonencode({
    "source": ["aws.ecs"],
    "detail-type": ["ECS Task State Change"],
    "detail": {
      "lastStatus": ["STOPPED"],
      "stoppedReason": ["Essential container in task exited"]
    }
  })
}

resource "aws_cloudwatch_event_target" "sns" {
  rule      = aws_cloudwatch_event_rule.ecs_rule.name
  arn       = module.sns.sns_lambda_topic
}