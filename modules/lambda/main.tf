data "aws_iam_policy_document" "assume_role" {
  statement {
    effect = "Allow"

    principals {
      type        = "Service"
      identifiers = ["lambda.amazonaws.com"]
    }

    actions = ["sts:AssumeRole"]
  }
}

data "aws_iam_policy_document" "lambda_logging" {
  statement {
    effect = "Allow"

    actions = [
      "logs:CreateLogGroup",
      "logs:CreateLogStream",
      "logs:PutLogEvents",
    ]

    resources = ["arn:aws:logs:*:*:*"]
  }
}

data "aws_ssm_parameter" "dbt_slack_webhook_url" {
  name = "DBT_SLACK_WEBHOOK_URL"
}

resource "aws_iam_role" "iam_for_lambda" {
  name               = "iam_for_lambda"
  assume_role_policy = data.aws_iam_policy_document.assume_role.json
}

resource "aws_lambda_layer_version" "slack_function_layer" {
  filename            = "src/lambda_slack/layers/lambda_layer.zip"
  layer_name          = "slack-function-layer"
  compatible_runtimes = ["python3.9"]
}

data "archive_file" "lambda_slack_code" {
  type        = "zip"
  source_dir  = "src/lambda_slack/utils"
  output_path = "src/lambda/zips/SlackFunction.zip"
}

resource "aws_lambda_function" "slack_lambda" {
  function_name = "SlackFunction"
  filename         = data.archive_file.lambda_slack_code.output_path
  source_code_hash = data.archive_file.lambda_slack_code.output_base64sha256
  role          = aws_iam_role.iam_for_lambda.arn

  layers = [aws_lambda_layer_version.slack_function_layer.arn]
  handler = "SlackFunction.lambda_handler"

  runtime = "python3.9"

  environment {
    variables = {
      DBT_SLACK_WEBHOOK_URL = data.aws_ssm_parameter.dbt_slack_webhook_url.value
      AVAILABILITY_ZONE = "eu-west-1"
    }
  }
}

resource "aws_iam_policy" "lambda_logging" {
  name        = "lambda_logging"
  path        = "/"
  description = "IAM policy for logging from a lambda"
  policy      = data.aws_iam_policy_document.lambda_logging.json
}

resource "aws_iam_role_policy_attachment" "lambda_logs" {
  role       = aws_iam_role.iam_for_lambda.name
  policy_arn = aws_iam_policy.lambda_logging.arn
}

