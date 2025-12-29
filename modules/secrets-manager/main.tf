data "aws_caller_identity" "current" {}

resource "random_password" "db_master_password" {
  length  = 32
  special = true
  # Exclude disallowed characters for RDS master password: '/', '@', '"', and space
  override_special = "!#$%&'()*+,-.:;<=>?[]^_{|}~"
  # Ensure complexity requirements
  min_upper   = 1
  min_lower   = 1
  min_numeric = 1
  min_special = 1
}

resource "aws_secretsmanager_secret" "db_master" {
  name                    = "${var.project_name}-${var.environment}-db-master"
  description             = "Database master credentials"
  kms_key_id              = var.kms_key_id
  recovery_window_in_days = var.recovery_window_days

  tags = {
    Name        = "${var.project_name}-${var.environment}-db-master"
    Environment = var.environment
    Type        = "database-credentials"
  }
}

resource "aws_secretsmanager_secret_version" "db_master" {
  secret_id = aws_secretsmanager_secret.db_master.id
  secret_string = jsonencode({
    username = var.database_credentials.username
    password = random_password.db_master_password.result
    database = var.database_credentials.database
  })
}

resource "aws_secretsmanager_secret_rotation" "db_master" {
  count = var.rotation_enabled ? 1 : 0

  secret_id           = aws_secretsmanager_secret.db_master.id
  rotation_lambda_arn = aws_lambda_function.rotation[0].arn

  rotation_rules {
    automatically_after_days = var.rotation_days
  }
}

resource "aws_secretsmanager_secret" "app_api_key" {
  name                    = "${var.project_name}-${var.environment}-app-api-key"
  description             = "Application API key"
  kms_key_id              = var.kms_key_id
  recovery_window_in_days = var.recovery_window_days

  tags = {
    Name        = "${var.project_name}-${var.environment}-app-api-key"
    Environment = var.environment
    Type        = "api-key"
  }
}

resource "random_password" "api_key" {
  length  = 64
  special = false
}

resource "aws_secretsmanager_secret_version" "app_api_key" {
  secret_id = aws_secretsmanager_secret.app_api_key.id
  secret_string = jsonencode({
    api_key = random_password.api_key.result
  })
}

resource "aws_secretsmanager_secret" "app_config" {
  name                    = "${var.project_name}-${var.environment}-app-config"
  description             = "Application configuration secrets"
  kms_key_id              = var.kms_key_id
  recovery_window_in_days = var.recovery_window_days

  tags = {
    Name        = "${var.project_name}-${var.environment}-app-config"
    Environment = var.environment
    Type        = "app-config"
  }
}

resource "aws_secretsmanager_secret_version" "app_config" {
  secret_id = aws_secretsmanager_secret.app_config.id
  secret_string = jsonencode({
    encryption_key = random_password.encryption_key.result
    jwt_secret     = random_password.jwt_secret.result
  })
}

resource "random_password" "encryption_key" {
  length  = 32
  special = true
}

resource "random_password" "jwt_secret" {
  length  = 64
  special = false
}

# Lambda function for secret rotation
resource "aws_lambda_function" "rotation" {
  count = var.rotation_enabled ? 1 : 0

  filename      = "${path.module}/lambda/rotation.zip"
  function_name = "${var.project_name}-${var.environment}-secret-rotation"
  role          = aws_iam_role.rotation_lambda[0].arn
  handler       = "index.handler"
  runtime       = "python3.11"
  timeout       = 30

  environment {
    variables = {
      SECRETS_MANAGER_ENDPOINT = "https://secretsmanager.${data.aws_region.current.name}.amazonaws.com"
    }
  }

  tags = {
    Name        = "${var.project_name}-${var.environment}-rotation"
    Environment = var.environment
  }
}

resource "aws_iam_role" "rotation_lambda" {
  count = var.rotation_enabled ? 1 : 0

  name = "${var.project_name}-${var.environment}-rotation-lambda"

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

resource "aws_iam_role_policy" "rotation_lambda" {
  count = var.rotation_enabled ? 1 : 0

  name = "${var.project_name}-${var.environment}-rotation-policy"
  role = aws_iam_role.rotation_lambda[0].id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "secretsmanager:DescribeSecret",
          "secretsmanager:GetSecretValue",
          "secretsmanager:PutSecretValue",
          "secretsmanager:UpdateSecretVersionStage"
        ]
        Resource = aws_secretsmanager_secret.db_master.arn
      },
      {
        Effect = "Allow"
        Action = [
          "kms:Decrypt",
          "kms:Encrypt",
          "kms:GenerateDataKey"
        ]
        Resource = "arn:aws:kms:${data.aws_region.current.name}:${data.aws_caller_identity.current.account_id}:key/${var.kms_key_id}"
      },
      {
        Effect = "Allow"
        Action = [
          "logs:CreateLogGroup",
          "logs:CreateLogStream",
          "logs:PutLogEvents"
        ]
        Resource = "arn:aws:logs:*:*:*"
      }
    ]
  })
}

resource "aws_lambda_permission" "rotation" {
  count = var.rotation_enabled ? 1 : 0

  statement_id  = "AllowSecretsManagerInvoke"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.rotation[0].function_name
  principal     = "secretsmanager.amazonaws.com"
}

data "aws_region" "current" {}
