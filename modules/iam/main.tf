# IAM module: roles and policies for KMS, Secrets Manager, and RDS access

# -----------------------------
# Inputs
# -----------------------------
variable "project_name" {
  description = "Name of the project"
  type        = string
}

variable "environment" {
  description = "Environment name"
  type        = string
}

variable "kms_key_arn" {
  description = "KMS key ARN used to encrypt/decrypt secrets and data"
  type        = string
}

variable "secrets_arns" {
  description = "List of Secrets Manager secret ARNs the application should access"
  type        = list(string)
  default     = []
}

variable "rds_arn" {
  description = "ARN of the RDS instance (used for describe permissions)"
  type        = string
}

# -----------------------------
# Data
# -----------------------------
data "aws_caller_identity" "current" {}

# -----------------------------
# Application Role
# -----------------------------
resource "aws_iam_role" "app" {
  name = "${var.project_name}-${var.environment}-app-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Sid    = "EC2AssumeRole",
        Effect = "Allow",
        Action = "sts:AssumeRole",
        Principal = {
          Service = "ec2.amazonaws.com"
        }
      },
      {
        Sid    = "LambdaAssumeRole",
        Effect = "Allow",
        Action = "sts:AssumeRole",
        Principal = {
          Service = "lambda.amazonaws.com"
        }
      }
    ]
  })

  tags = {
    Name        = "${var.project_name}-${var.environment}-app-role"
    Project     = var.project_name
    Environment = var.environment
    ManagedBy   = "Terraform"
  }
}

# Inline policy: KMS + Secrets Manager + RDS describe (least privilege)
resource "aws_iam_role_policy" "app_access" {
  name = "${var.project_name}-${var.environment}-app-access"
  role = aws_iam_role.app.id

  policy = jsonencode({
    Version = "2012-10-17",
    Statement = concat(
      [
        # KMS data plane permissions for encryption-at-rest verification and secret usage
        {
          Sid    = "KMSDataPlane",
          Effect = "Allow",
          Action = [
            "kms:Decrypt",
            "kms:Encrypt",
            "kms:ReEncrypt*",
            "kms:GenerateDataKey*",
            "kms:DescribeKey"
          ],
          Resource = var.kms_key_arn
        },

        # Read specific secrets only (no wildcard)
        {
          Sid    = "SecretsReadSpecific",
          Effect = "Allow",
          Action = [
            "secretsmanager:GetSecretValue",
            "secretsmanager:DescribeSecret"
          ],
          Resource = var.secrets_arns
        },

        # Optional: allow listing secrets metadata (non-sensitive) to enable discovery workflows
        {
          Sid    = "SecretsList",
          Effect = "Allow",
          Action = [
            "secretsmanager:ListSecrets"
          ],
          Resource = "*"
        },

        # RDS read-only describe for topology awareness and validation
        {
          Sid    = "RDSDescribe",
          Effect = "Allow",
          Action = [
            "rds:DescribeDBInstances",
            "rds:ListTagsForResource"
          ],
          Resource = "*"
        },

        # CloudWatch Logs for Lambda/EC2 app diagnostics (scoped to account)
        {
          Sid    = "LogsWrite",
          Effect = "Allow",
          Action = [
            "logs:CreateLogGroup",
            "logs:CreateLogStream",
            "logs:PutLogEvents"
          ],
          Resource = "arn:aws:logs:*:${data.aws_caller_identity.current.account_id}:*"
        }
      ],
      []
    )
  })
}

# -----------------------------
# Readonly Role (auditing / break-glass read-only access)
# -----------------------------
resource "aws_iam_role" "readonly" {
  name = "${var.project_name}-${var.environment}-readonly-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Sid    = "EC2AssumeRole",
        Effect = "Allow",
        Action = "sts:AssumeRole",
        Principal = {
          Service = "ec2.amazonaws.com"
        }
      },
      {
        Sid    = "LambdaAssumeRole",
        Effect = "Allow",
        Action = "sts:AssumeRole",
        Principal = {
          Service = "lambda.amazonaws.com"
        }
      }
    ]
  })

  tags = {
    Name        = "${var.project_name}-${var.environment}-readonly-role"
    Project     = var.project_name
    Environment = var.environment
    ManagedBy   = "Terraform"
  }
}

# Inline policy: read-only across KMS/Secrets/RDS
resource "aws_iam_role_policy" "readonly_access" {
  name = "${var.project_name}-${var.environment}-readonly-access"
  role = aws_iam_role.readonly.id

  policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Sid    = "KMSReadOnly",
        Effect = "Allow",
        Action = [
          "kms:DescribeKey",
          "kms:ListKeys",
          "kms:ListAliases"
        ],
        Resource = "*"
      },
      {
        Sid    = "SecretsReadOnlySpecific",
        Effect = "Allow",
        Action = [
          "secretsmanager:DescribeSecret",
          "secretsmanager:GetSecretValue"
        ],
        Resource = var.secrets_arns
      },
      {
        Sid    = "SecretsList",
        Effect = "Allow",
        Action = [
          "secretsmanager:ListSecrets"
        ],
        Resource = "*"
      },
      {
        Sid    = "RDSReadOnly",
        Effect = "Allow",
        Action = [
          "rds:DescribeDBInstances",
          "rds:ListTagsForResource"
        ],
        Resource = "*"
      }
    ]
  })
}

# -----------------------------
# Outputs
# -----------------------------
output "app_role_arn" {
  description = "ARN of the IAM role for application access"
  value       = aws_iam_role.app.arn
}

output "app_role_name" {
  description = "Name of the IAM role for application access"
  value       = aws_iam_role.app.name
}

output "readonly_role_arn" {
  description = "ARN of the read-only IAM role"
  value       = aws_iam_role.readonly.arn
}
