output "dbt_docs_generate_bucket" {
  value = aws_s3_bucket.dbt_docs_generate_bucket.bucket
}

output "dbt_docs_generate_bucket_arn" {
  value = aws_s3_bucket.dbt_docs_generate_bucket.arn
}