# Lambda IAM Role
resource "aws_iam_role" "lambda" {
  name = "${var.project_name}-${var.environment}-lambda-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Action = "sts:AssumeRole"
      Effect = "Allow"
      Principal = {
        Service = "lambda.amazonaws.com"
      }
    }]
  })
}

resource "aws_iam_role_policy_attachment" "lambda_vpc_execution" {
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSLambdaVPCAccessExecutionRole"
  role       = aws_iam_role.lambda.name
}

resource "aws_iam_role_policy" "lambda_custom" {
  name = "${var.project_name}-${var.environment}-lambda-policy"
  role = aws_iam_role.lambda.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "logs:CreateLogGroup",
          "logs:CreateLogStream",
          "logs:PutLogEvents"
        ]
        Resource = "arn:aws:logs:*:*:*"
      },
      {
        Effect = "Allow"
        Action = [
          "sns:Publish"
        ]
        Resource = aws_sns_topic.security_alerts.arn
      },
      {
        Effect = "Allow"
        Action = [
          "sqs:SendMessage",
          "sqs:ReceiveMessage",
          "sqs:DeleteMessage",
          "sqs:GetQueueAttributes",
          "sqs:ChangeMessageVisibility"
        ]
        Resource = [
          aws_sqs_queue.parser_queue.arn,
          aws_sqs_queue.engine_queue.arn,
          aws_sqs_queue.notify_queue.arn,
          aws_sqs_queue.remediation_queue.arn
        ]
      },
      {
        Effect = "Allow"
        Action = [
          "dynamodb:PutItem",
          "dynamodb:GetItem",
          "dynamodb:UpdateItem",
          "dynamodb:Query",
          "dynamodb:Scan"
        ]
        Resource = [
          aws_dynamodb_table.events.arn,
          aws_dynamodb_table.blocked_ips.arn
        ]
      }
    ]
  })
}

# Archive Lambda source code
data "archive_file" "parser" {
  type        = "zip"
  source_dir  = "${path.module}/../lambda/parser"
  output_path = "${path.module}/../lambda/parser.zip"
  excludes    = ["*.zip", "__pycache__", "*.pyc"]
}

data "archive_file" "engine" {
  type        = "zip"
  source_dir  = "${path.module}/../lambda/engine"
  output_path = "${path.module}/../lambda/engine.zip"
  excludes    = ["*.zip", "__pycache__", "*.pyc"]
}

data "archive_file" "notify" {
  type        = "zip"
  source_dir  = "${path.module}/../lambda/notify"
  output_path = "${path.module}/../lambda/notify.zip"
  excludes    = ["*.zip", "__pycache__", "*.pyc"]
}

data "archive_file" "remediate" {
  type        = "zip"
  source_dir  = "${path.module}/../lambda/remediate"
  output_path = "${path.module}/../lambda/remediate.zip"
  excludes    = ["*.zip", "__pycache__", "*.pyc"]
}

# Parser Lambda Function
resource "aws_lambda_function" "parser" {
  filename         = data.archive_file.parser.output_path
  source_code_hash = data.archive_file.parser.output_base64sha256
  function_name    = "${var.project_name}-${var.environment}-parser"
  role             = aws_iam_role.lambda.arn
  handler          = "parser.lambda_handler"
  runtime          = "python3.11"
  timeout          = 30
  memory_size      = 512

  vpc_config {
    subnet_ids         = [aws_subnet.lambda_private.id]  # Lambda private subnet AZ A only
    security_group_ids = [aws_security_group.lambda.id]
  }

  environment {
    variables = {
      ENVIRONMENT        = var.environment
      ENGINE_QUEUE_URL   = aws_sqs_queue.engine_queue.url
      DYNAMODB_TABLE     = aws_dynamodb_table.events.name
      LOG_LEVEL          = "INFO"
    }
  }

  depends_on = [aws_iam_role_policy_attachment.lambda_vpc_execution]
}

# Engine Lambda Function
resource "aws_lambda_function" "engine" {
  filename         = data.archive_file.engine.output_path
  source_code_hash = data.archive_file.engine.output_base64sha256
  function_name    = "${var.project_name}-${var.environment}-engine"
  role             = aws_iam_role.lambda.arn
  handler          = "engine.lambda_handler"
  runtime          = "python3.11"
  timeout          = 60
  memory_size      = 1024

  vpc_config {
    subnet_ids         = [aws_subnet.lambda_private.id]  # Lambda private subnet AZ A only
    security_group_ids = [aws_security_group.lambda.id]
  }

  environment {
    variables = {
      ENVIRONMENT            = var.environment
      REMEDIATION_QUEUE_URL  = aws_sqs_queue.remediation_queue.url
      NOTIFY_QUEUE_URL       = aws_sqs_queue.notify_queue.url
      DYNAMODB_TABLE         = aws_dynamodb_table.events.name
      BLOCKED_IPS_TABLE      = aws_dynamodb_table.blocked_ips.name
      LOG_LEVEL              = "INFO"
    }
  }

  depends_on = [aws_iam_role_policy_attachment.lambda_vpc_execution]
}

# Notify Lambda Function
resource "aws_lambda_function" "notify" {
  filename         = data.archive_file.notify.output_path
  source_code_hash = data.archive_file.notify.output_base64sha256
  function_name    = "${var.project_name}-${var.environment}-notify"
  role             = aws_iam_role.lambda.arn
  handler          = "notify.lambda_handler"
  runtime          = "python3.11"
  timeout          = 30
  memory_size      = 256

  vpc_config {
    subnet_ids         = [aws_subnet.lambda_private.id]  # Lambda private subnet AZ A only
    security_group_ids = [aws_security_group.lambda.id]
  }

  environment {
    variables = {
      ENVIRONMENT    = var.environment
      SNS_TOPIC_ARN  = aws_sns_topic.security_alerts.arn
      LOG_LEVEL      = "INFO"
    }
  }

  depends_on = [aws_iam_role_policy_attachment.lambda_vpc_execution]
}

# Remediate Lambda Function
resource "aws_lambda_function" "remediate" {
  filename         = data.archive_file.remediate.output_path
  source_code_hash = data.archive_file.remediate.output_base64sha256
  function_name    = "${var.project_name}-${var.environment}-remediate"
  role             = aws_iam_role.lambda.arn
  handler          = "remediate.lambda_handler"
  runtime          = "python3.11"
  timeout          = 300
  memory_size      = 512

  vpc_config {
    subnet_ids         = [aws_subnet.lambda_private.id]  # Lambda private subnet AZ A only
    security_group_ids = [aws_security_group.lambda.id]
  }

  environment {
    variables = {
      ENVIRONMENT     = var.environment
      DYNAMODB_TABLE  = aws_dynamodb_table.events.name
      LOG_LEVEL       = "INFO"
    }
  }

  depends_on = [aws_iam_role_policy_attachment.lambda_vpc_execution]
}

# CloudWatch Log Groups
resource "aws_cloudwatch_log_group" "parser" {
  name              = "/aws/lambda/${aws_lambda_function.parser.function_name}"
  retention_in_days = 7
}

resource "aws_cloudwatch_log_group" "engine" {
  name              = "/aws/lambda/${aws_lambda_function.engine.function_name}"
  retention_in_days = 7
}

resource "aws_cloudwatch_log_group" "notify" {
  name              = "/aws/lambda/${aws_lambda_function.notify.function_name}"
  retention_in_days = 7
}

resource "aws_cloudwatch_log_group" "remediate" {
  name              = "/aws/lambda/${aws_lambda_function.remediate.function_name}"
  retention_in_days = 7
}

# SQS Event Source Mappings
resource "aws_lambda_event_source_mapping" "parser_sqs" {
  event_source_arn = aws_sqs_queue.parser_queue.arn
  function_name    = aws_lambda_function.parser.arn
  batch_size       = 10
}

resource "aws_lambda_event_source_mapping" "engine_sqs" {
  event_source_arn = aws_sqs_queue.engine_queue.arn
  function_name    = aws_lambda_function.engine.arn
  batch_size       = 5
}

resource "aws_lambda_event_source_mapping" "notify_sqs" {
  event_source_arn = aws_sqs_queue.notify_queue.arn
  function_name    = aws_lambda_function.notify.arn
  batch_size       = 10
}

resource "aws_lambda_event_source_mapping" "remediate_sqs" {
  event_source_arn = aws_sqs_queue.remediation_queue.arn
  function_name    = aws_lambda_function.remediate.arn
  batch_size       = 1
}
