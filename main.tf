resource "random_string" "uniq_string" {
  length  = 16
  upper   = false
  special = false
}

locals {
  bucket_name = var.bucket_name == "" ? "${var.app_name}-${random_string.uniq_string.result}" : var.bucket_name
  lambda_name = var.lambda_name == "" ? "${var.app_name}-${random_string.uniq_string.result}" : var.lambda_name
}


provider "aws" {
  region  = var.aws_region
  profile = var.aws_profile
}

resource "aws_s3_bucket" "s3_bucket" {
  bucket = local.bucket_name
  acl    = "private"
  tags   = { Name = local.bucket_name }
  versioning { enabled = false }
}


resource "aws_iam_role" "lambda_role" {
  name               = "${var.app_name}-role"
  assume_role_policy = "{\"Version\": \"2012-10-17\", \"Statement\": [{\"Sid\": \"\", \"Effect\": \"Allow\", \"Principal\": {\"Service\": \"lambda.amazonaws.com\"}, \"Action\": \"sts:AssumeRole\"}]}"
}


resource "aws_iam_role_policy" "role_policy" {
  name   = "${var.app_name}-rolePolicy"
  policy = "{\"Version\": \"2012-10-17\", \"Statement\": [{\"Effect\": \"Allow\", \"Action\": [\"logs:CreateLogGroup\", \"logs:CreateLogStream\", \"logs:PutLogEvents\"], \"Resource\": \"arn:*:logs:*:*:*\"}]}"
  role   = aws_iam_role.lambda_role.id
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
  function_name = local.lambda_name
  runtime       = "python3.8"
  handler       = "main.handler"
  memory_size   = 128
  timeout       = 60
  role          = aws_iam_role.lambda_role.arn
  publish       = true
  s3_key        = aws_s3_bucket_object.lambda_source.id
  tags = {
    app_name = var.app_name
  }
}
