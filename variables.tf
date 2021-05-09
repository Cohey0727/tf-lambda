variable "aws_region" {
  default = "ap-northeast-1"
}

variable "aws_profile" {
  default = "default"
}


variable "app_name" {
  default = "tflambda"
}

variable "bucket_name" {
  type    = string
  default = ""
}

variable "lambda_name" {
  type    = string
  default = ""
}

variable "lambda_options" {
  type = object({
    handler = string
    runtime = string
    timeout = number
  })
  default = {
    handler = "main.handler"
    runtime = "python3.8"
    timeout = 120
  }
}
