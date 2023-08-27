data "aws_ssm_parameter" "dbt_docs_generate_bucket" {
  name = "docs_host_bucket_name"
}

resource "aws_s3_bucket" "dbt_docs_generate_bucket" {
  bucket = data.aws_ssm_parameter.dbt_docs_generate_bucket.value
}

resource "aws_s3_bucket_public_access_block" "public_access" {
  bucket = aws_s3_bucket.dbt_docs_generate_bucket.id

  block_public_acls       = false
  block_public_policy     = false
  ignore_public_acls      = false
  restrict_public_buckets = false
}

data "aws_iam_policy_document" "allow_access_from_another_account" {
  version = "2012-10-17"

  statement {
    actions = ["s3:GetObject", "s3:ListBucket"]
    resources = [
      aws_s3_bucket.dbt_docs_generate_bucket.arn,
      "${aws_s3_bucket.dbt_docs_generate_bucket.arn}/*",
    ]

    principals {
      type = "AWS"
      identifiers = ["*"]
    }
  }
}

resource "aws_s3_bucket_website_configuration" "example" {
  bucket = aws_s3_bucket.dbt_docs_generate_bucket.id

  index_document {
    suffix = "index.html"
  }
}

resource "aws_s3_bucket_policy" "allow_access_from_another_account" {
  bucket = aws_s3_bucket.dbt_docs_generate_bucket.id
  policy = data.aws_iam_policy_document.allow_access_from_another_account.json

  depends_on = [aws_s3_bucket_public_access_block.public_access]
}
