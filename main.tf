terraform {
  required_version = ">= 1.0"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
    random = {
      source  = "hashicorp/random"
      version = "~> 3.5"
    }
  }
}

provider "aws" {
  region = var.aws_region

  default_tags {
    tags = var.common_tags
  }
}

module "kms" {
  source = "./modules/kms"

  project_name     = var.project_name
  environment      = var.environment
  rotation_enabled = var.enable_key_rotation
  deletion_window  = var.kms_deletion_window
  admin_role_arns  = var.kms_admin_role_arns
  user_role_arns   = var.kms_user_role_arns
}

module "secrets_manager" {
  source = "./modules/secrets-manager"

  project_name         = var.project_name
  environment          = var.environment
  kms_key_id           = module.kms.key_id
  rotation_enabled     = var.enable_secret_rotation
  rotation_days        = var.secret_rotation_days
  recovery_window_days = var.secret_recovery_window
  database_credentials = var.database_credentials
}

module "rds" {
  source = "./modules/rds"

  project_name            = var.project_name
  environment             = var.environment
  vpc_id                  = var.vpc_id
  subnet_ids              = var.subnet_ids
  kms_key_arn             = module.kms.key_arn
  db_master_secret_arn    = module.secrets_manager.db_master_secret_arn
  instance_class          = var.db_instance_class
  allocated_storage       = var.db_allocated_storage
  engine_version          = var.db_engine_version
  backup_retention_period = var.db_backup_retention
  enabled_cloudwatch_logs = var.db_enabled_cloudwatch_logs
}

module "iam" {
  source = "./modules/iam"

  project_name = var.project_name
  environment  = var.environment
  kms_key_arn  = module.kms.key_arn
  secrets_arns = module.secrets_manager.secret_arns
  rds_arn      = module.rds.db_instance_arn
}
