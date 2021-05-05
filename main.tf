resource "random_uuid" "bucket_uuid" {}
resource "random_uuid" "lambda_uuid" {}

locals {
  bucket_name = var.bucket_name == "" ? "${var.bucket_prefix}-${random_uuid.bucket_uuid.result}" : ""
  lambda_name = var.lambda_name == "" ? "${var.lambda_prefix}-${random_uuid.lambda_uuid.result}" : ""
}


provider "aws" {
  region  = var.aws_region
  profile = var.aws_profile
}

resource "aws_s3_bucket" "s3_bucket" {
  bucket = locals.bucket_name
  acl    = "private"
  tags   = { Name = locals.bucket_name }
  versioning { enabled = false }
}


resource "aws_iam_role" "lambda" {
  name               = "iam_for_lambda"
  assume_role_policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Action": "sts:AssumeRole",
      "Principal": {
        "Service": "lambda.amazonaws.com"
      },
      "Effect": "Allow",
      "Sid": ""
    }
  ]
}
EOF
}

data "archive_file" "initial_lambda_package" {
  type        = "zip"
  output_path = "${path.module}/.temp_files/empty.zip"
  source {
    content  = "# empty"
    filename = "main.py"
  }
}

resource "aws_s3_bucket_object" "lambda_source" {
  bucket = aws_s3_bucket.s3_bucket.id
  key    = "empty.zip"
  source = "${path.module}/.temp_files/empty.zip"
}

resource "aws_lambda_function" "lambda_function" {
  function_name = locals.lambda_name
  role          = aws_iam_role.lambda.arn
  handler       = "main.handler"
  runtime       = "python3.8"
  timeout       = 120
  publish       = true
  s3_bucket     = aws_s3_bucket.s3_bucket.id
  s3_key        = aws_s3_bucket_object.lambda_source.id
}
