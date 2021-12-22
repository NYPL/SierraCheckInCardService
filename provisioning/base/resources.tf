provider "aws" {
  region = "us-east-1"
}

variable "environment" {
  type = string
  default = "qa"
  description = "The name of the environment (qa, production). This controls the name of the lambda and the env vars loaded."

  validation {
    condition = contains(["qa, "production"], var.environment)
    error_message = "The environment must be 'qa' or 'production'."
  }
}

variable "vpc_config" {
  type = map
  description = "The name of the environnment (qa, production)"
}

# Package the app as a zip:
data "archive_file" "lambda_zip" {
  type        = "zip"
  output_path = "${path.module}/dist.zip"
  source_dir  = "../../"
  excludes    = [".git", ".terraform", "provisioning"]
}

# Upload the zipped app to S3:
resource "aws_s3_bucket_object" "uploaded_zip" {
  bucket = "nypl-travis-builds-${var.environment}"
  key    = "sierra-check-in-card-service-${var.environment}-dist.zip"
  acl    = "private"
  source = data.archive_file.lambda_zip.output_path
  etag   = filemd5(data.archive_file.lambda_zip.output_path)
}


# Create the lambda:
resource "aws_lambda_function" "lambda_instance" {
  description   = "API service for returning check-in cards/boxes for associated holdings"
  function_name = "SierraCheckInCardService-${var.environment}"
  handler       = "app.handle_event"
  memory_size   = 512
  role          = "arn:aws:iam::946183545209:role/lambda-full-access"
  runtime       = "ruby2.7"
  timeout       = 300
  layers = ["arn:aws:lambda:us-east-1:946183545209:layer:ruby-pg-sqlite-lambda:2"]

  # Location of the zipped code in S3:
  s3_bucket     = aws_s3_bucket_object.uploaded_zip.bucket
  s3_key        = aws_s3_bucket_object.uploaded_zip.key

  # Trigger pulling code from S3 when the zip has changed:
  source_code_hash = data.archive_file.lambda_zip.output_base64sha256

  vpc_config {
    subnet_ids         = var.vpc_config.subnet_ids
    security_group_ids = var.vpc_config.security_group_ids
  }

  # Load ENV vars from ./config/{environment}.env
  environment {
    variables = { for tuple in regexall("(.*?)=(.*)", file("../../config/${var.environment}.env")) : tuple[0] => tuple[1] }
  }
}
