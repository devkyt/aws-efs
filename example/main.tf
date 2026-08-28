locals {
  app    = "whatever"
  env    = "experiment"
  region = "eu-central-1"

  tags = {
    Name        = local.app
    Environment = local.env
    Region      = local.region
  }
}

terraform {
  backend "s3" {
    bucket = "terraform-experiments-state"
    region = "eu-central-1"
    key    = "whatever/terraform.tfstate"
  }
}


provider "aws" {
  region = local.region
}


module "efs" {
  source = "git@github.com:devkyt/aws-efs.git?ref=main&depth=1"

  app = local.app
  env = local.env

  # Optional: override EFS name (defaults to app-env)
  # name = "my-custom-efs"

  vpc_id     = "vpc-0123456789abcdef0"
  subnet_ids = ["subnet-0123456789abcdef0", "subnet-0123456789abcdef1"]

  # Ingress rules for security group
  ingress = {
    "ecs" = {
      port                      = 2049
      allowed_security_group_id = "sg-0123456789abcdef0"
    }
    # "office-vpn" = {
    #   port      = 2049
    #   cidr_ipv4 = "10.0.0.0/16"
    # }
  }

  # Optional: encryption (enabled by default with AWS-managed key)
  # encryption = {
  #   enabled    = true
  #   kms_key_id = "arn:aws:kms:eu-central-1:123456789012:key/12345678-1234-1234-1234-123456789012"
  # }

  # Optional: lifecycle policies
  # lifecycle_policy = {
  #   transition_to_ia                    = "AFTER_30_DAYS"
  #   transition_to_primary_storage_class = "AFTER_1_ACCESS"
  # }

  # Optional: access points
  access_points = [
    {
      root_path   = "/data"
      user_id     = 1000
      group_id    = 1000
      permissions = "755"
    }
  ]

  # SSL enforcement is enabled by default
  # enforce_ssl = true

  # Optional: structured file system policy
  # iam_policy = [
  #   {
  #     sid = "AllowMountFromRole"
  #     principals = {
  #       type        = "AWS"
  #       identifiers = ["arn:aws:iam::123456789012:role/app-role"]
  #     }
  #     actions = [
  #       "elasticfilesystem:ClientMount",
  #       "elasticfilesystem:ClientWrite",
  #     ]
  #     # Optional: restrict to specific access points
  #     # conditions = [
  #     #   {
  #     #     test     = "StringEquals"
  #     #     variable = "elasticfilesystem:AccessPointArn"
  #     #     values   = ["arn:aws:elasticfilesystem:eu-central-1:123456789012:access-point/fsap-0123456789abcdef0"]
  #     #   }
  #     # ]
  #   }
  # ]

  tags = local.tags
}
