# AWS EFS

OpenTofu module for Elastic File System provisioning. You can find how to use it in [example](./example/) folder
and in the [Examples](#examples) section below.

## Table of Contents

- [Requirements](#requirements)
- [Inputs](#inputs)
- [Outputs](#outputs)
- [Examples](#examples)
  - [Basic File System](#basic-file-system)
  - [Access Points](#access-points)
  - [IAM Policy](#iam-policy)
  - [Restricting to Access Points](#restricting-to-access-points)
  - [Lifecycle and Replication](#lifecycle-and-replication)

## Requirements

| Name | Version |
|------|---------|
| OpenTofu | >= 1.11 |
| AWS provider | ~> 6.0  |

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|----------|
| `name` | Custom name for the EFS. Defaults to {app}-{env} | `string` | `null` | no |
| `app` | Application name | `string` | - | yes |
| `env` | Target environment | `string` | - | yes |
| `encryption` | Encryption configuration | `object` | `{ enabled = true }` | no |
| `lifecycle_policy` | Lifecycle policies to apply | `object` | `null` | no |
| `vpc_id` | VPC where EFS will be located | `string` | - | yes |
| `subnet_ids` | Subnets where EFS mount targets will be created | `list(string)` | - | yes |
| `ingress` | Ingress rules for EFS security group | `map(object)` | - | yes |
| `access_points` | EFS access points with root path, POSIX user, and permissions | `list(object)` | `[]` | no |
| `iam_policy` | IAM policy statements for the EFS file system policy. Resource is automatically set to the file system ARN | `list(object)` | `[]` | no |
| `enforce_ssl` | Deny all non-TLS requests to the file system | `bool` | `true` | no |
| `backup_enabled` | Enable automatic backups for EFS | `bool` | `true` | no |
| `replicas` | Replication destinations for EFS | `list(object)` | `[]` | no |
| `use_name_prefix` | Use name_prefix instead of a fixed name for created resources, so AWS appends a unique suffix | `bool` | `false` | no |
| `include_default_tags` | Whether or not to attach default tags specified in module | `bool` | `true` | no |
| `tags` | Tags to apply to EFS and the related resources | `map(string)` | `{}` | no |

## Outputs

| Name | Description |
|------|-------------|
| `arn` | ARN of the created EFS |
| `id` | ID of the created EFS |
| `name` | Name of the created EFS |
| `dns_name` | DNS name of the created EFS |
| `access_point_arns` | ARNs of the created access points |
| `security_group_id` | ID of the security group created for EFS |

## Examples

### Basic File System

A minimal EFS with a security group allowing NFS access from an ECS service.

```hcl
module "efs" {
  source = "git@github.com:devkyt/aws-efs.git?ref=main&depth=1"

  app = "whatever"
  env = "experiment"

  vpc_id     = "vpc-0123456789abcdef0"
  subnet_ids = ["subnet-0123456789abcdef0", "subnet-0123456789abcdef1"]

  ingress = {
    "ecs" = {
      port                      = 2049
      allowed_security_group_id = "sg-0123456789abcdef0"
    }
  }
}
```

### Access Points

Creating access points to isolate different application paths with POSIX user enforcement.

```hcl
module "efs" {
  source = "git@github.com:devkyt/aws-efs.git?ref=main&depth=1"

  app = "whatever"
  env = "experiment"

  vpc_id     = "vpc-0123456789abcdef0"
  subnet_ids = ["subnet-0123456789abcdef0", "subnet-0123456789abcdef1"]

  ingress = {
    "ecs" = {
      port                      = 2049
      allowed_security_group_id = "sg-0123456789abcdef0"
    }
  }

  access_points = [
    {
      root_path   = "/data"
      user_id     = 1000
      group_id    = 1000
      permissions = "755"
    },
    {
      root_path   = "/logs"
      user_id     = 1001
      group_id    = 1001
      permissions = "755"
    }
  ]
}
```

### IAM Policy

Granting mount and write access to a specific IAM role.

```hcl
module "efs" {
  source = "git@github.com:devkyt/aws-efs.git?ref=main&depth=1"

  app = "whatever"
  env = "experiment"

  vpc_id     = "vpc-0123456789abcdef0"
  subnet_ids = ["subnet-0123456789abcdef0", "subnet-0123456789abcdef1"]

  ingress = {
    "ecs" = {
      port                      = 2049
      allowed_security_group_id = "sg-0123456789abcdef0"
    }
  }

  iam_policy = [
    {
      sid = "AllowMountFromApp"
      principals = {
        type        = "AWS"
        identifiers = ["arn:aws:iam::123456789012:role/app-role"]
      }
      actions = [
        "elasticfilesystem:ClientMount",
        "elasticfilesystem:ClientWrite",
      ]
    }
  ]
}
```

### Restricting to Access Points

Using conditions to restrict IAM policy to a specific access point.

```hcl
module "efs" {
  source = "git@github.com:devkyt/aws-efs.git?ref=main&depth=1"

  app = "whatever"
  env = "experiment"

  vpc_id     = "vpc-0123456789abcdef0"
  subnet_ids = ["subnet-0123456789abcdef0", "subnet-0123456789abcdef1"]

  ingress = {
    "ecs" = {
      port                      = 2049
      allowed_security_group_id = "sg-0123456789abcdef0"
    }
  }

  access_points = [
    {
      root_path   = "/data"
      user_id     = 1000
      group_id    = 1000
      permissions = "755"
    }
  ]

  iam_policy = [
    {
      sid = "AllowMountViaAccessPoint"
      principals = {
        type        = "AWS"
        identifiers = ["arn:aws:iam::123456789012:role/app-role"]
      }
      actions = [
        "elasticfilesystem:ClientMount",
        "elasticfilesystem:ClientWrite",
      ]
      conditions = [
        {
          test     = "StringEquals"
          variable = "elasticfilesystem:AccessPointArn"
          values   = ["arn:aws:elasticfilesystem:eu-central-1:123456789012:access-point/fsap-0123456789abcdef0"]
        }
      ]
    }
  ]
}
```

### Lifecycle and Replication

Enabling lifecycle transitions and cross-region replication.

```hcl
module "efs" {
  source = "git@github.com:devkyt/aws-efs.git?ref=main&depth=1"

  app = "whatever"
  env = "experiment"

  vpc_id     = "vpc-0123456789abcdef0"
  subnet_ids = ["subnet-0123456789abcdef0", "subnet-0123456789abcdef1"]

  ingress = {
    "ecs" = {
      port                      = 2049
      allowed_security_group_id = "sg-0123456789abcdef0"
    }
  }

  lifecycle_policy = {
    transition_to_ia                    = "AFTER_30_DAYS"
    transition_to_primary_storage_class = "AFTER_1_ACCESS"
  }

  replicas = [
    {
      region = "eu-west-1"
    }
  ]
}
```

## License

Licensed under the Apache License, Version 2.0.

Copyright 2026 Kyrylo Tykhanskyi.
