variable "name" {
  description = "Custom name for the EFS. Defaults to {app}-{env}"
  type        = string
  default     = null
  nullable    = true

  validation {
    condition     = var.name == null || length(var.name) > 0
    error_message = "EFS name cannot be empty if provided."
  }

  validation {
    condition     = var.name == null || can(regex("^[a-zA-Z0-9-]+$", var.name))
    error_message = "EFS name must contain only letters, numbers, and hyphens."
  }
}


variable "app" {
  description = "Application name"
  type        = string

  validation {
    condition     = length(var.app) > 0
    error_message = "Application name cannot be empty."
  }

  validation {
    condition     = can(regex("^[a-z0-9-]+$", var.app))
    error_message = "Application name must contain only lowercase letters, numbers, and hyphens."
  }
}


variable "env" {
  description = "Target environment"
  type        = string

  validation {
    condition     = length(var.env) > 0
    error_message = "Environment cannot be empty."
  }

  validation {
    condition     = can(regex("^[a-z0-9-]+$", var.env))
    error_message = "Environment must contain only lowercase letters, numbers, and hyphens."
  }
}


variable "encryption" {
  description = "Encryption configuration"
  type = object({
    enabled    = optional(bool, true)
    kms_key_id = optional(string, null)
  })
  default = {}

  validation {
    condition = (
      var.encryption.kms_key_id == null ||
      can(regex("^arn:aws:kms:[a-z0-9-]+:[0-9]{12}:key/[a-f0-9-]+$", var.encryption.kms_key_id)) ||
      can(regex("^[a-f0-9]{8}-[a-f0-9]{4}-[a-f0-9]{4}-[a-f0-9]{4}-[a-f0-9]{12}$", var.encryption.kms_key_id))
    )
    error_message = "KMS key ID must be in a valid KMS key ARN or key ID format."
  }
}


variable "lifecycle_policy" {
  description = "Lifecycle policies to apply"
  type = object({
    transition_to_ia                    = optional(string, null)
    transition_to_archive               = optional(string, null)
    transition_to_primary_storage_class = optional(string, null)
  })
  default  = null
  nullable = true
}


variable "vpc_id" {
  description = "VPC where EFS will be located"
  type        = string

  validation {
    condition     = can(regex("^vpc-[a-f0-9]{8,}$", var.vpc_id))
    error_message = "VPC ID must be a valid format (vpc-xxxxxxxx)."
  }
}


variable "subnet_ids" {
  description = "Subnets where EFS mount targets will be created"
  type        = list(string)

  validation {
    condition     = length(var.subnet_ids) > 0
    error_message = "At least one subnet ID must be provided."
  }

  validation {
    condition     = alltrue([for id in var.subnet_ids : can(regex("^subnet-[a-f0-9]{8,}$", id))])
    error_message = "All subnet IDs must be in valid format (subnet-xxxxxxxx)."
  }
}


variable "ingress" {
  description = "Ingress rules for EFS security group"
  type = map(object({
    port                      = number
    protocol                  = optional(string, "tcp")
    description               = optional(string)
    allowed_security_group_id = optional(string)
    cidr_ipv4                 = optional(string)
    cidr_ipv6                 = optional(string)
    prefix_list_id            = optional(string)
  }))

  validation {
    condition = alltrue([
      for k, v in var.ingress : length(compact([v.allowed_security_group_id, v.cidr_ipv4, v.cidr_ipv6, v.prefix_list_id])) == 1
    ])
    error_message = "Each ingress rule must specify exactly one source: allowed_security_group_id, cidr_ipv4, cidr_ipv6, or prefix_list_id."
  }
}


variable "access_points" {
  description = "Split EFS into access points"
  type = list(object({
    root_path   = string
    user_id     = number
    group_id    = number
    permissions = string
  }))
  default = []

  validation {
    condition     = alltrue([for ap in var.access_points : can(regex("^/", ap.root_path))])
    error_message = "All root paths must start with /."
  }

  validation {
    condition     = alltrue([for ap in var.access_points : ap.user_id >= 0])
    error_message = "All user IDs must be non-negative."
  }

  validation {
    condition     = alltrue([for ap in var.access_points : ap.group_id >= 0])
    error_message = "All group IDs must be non-negative."
  }

  validation {
    condition     = alltrue([for ap in var.access_points : can(regex("^[0-7]{3,4}$", ap.permissions))])
    error_message = "All permissions must be valid octal format (e.g., 755, 644, 0755)."
  }
}


variable "iam_policy" {
  description = "IAM policy statements for the EFS file system policy. Resource is automatically set to the file system ARN. Use conditions with elasticfilesystem:AccessPointArn to restrict to specific access points."
  type = list(object({
    sid    = optional(string)
    effect = optional(string, "Allow")
    principals = object({
      type        = string
      identifiers = list(string)
    })
    actions = list(string)
    conditions = optional(list(object({
      test     = string
      variable = string
      values   = list(string)
    })), [])
  }))
  default = []
}


variable "enforce_ssl" {
  description = "Deny all non-TLS requests to the file system by attaching a policy with aws:SecureTransport condition"
  type        = bool
  default     = true
}


variable "backup_enabled" {
  description = "Enable automatic backups for EFS"
  type        = bool
  default     = true
}


variable "replicas" {
  description = "Replication destinations for EFS"
  type = list(object({
    region                 = optional(string)
    availability_zone_name = optional(string)
    file_system_id         = optional(string)
    kms_key_id             = optional(string)
  }))
  default = []
}


variable "use_name_prefix" {
  description = "Use name_prefix instead of a fixed name for the resources this module creates, so AWS appends a unique suffix"
  type        = bool
  default     = false
}


variable "include_default_tags" {
  description = "Whether or not to attach default tags specified in module"
  type        = bool
  default     = true
}


variable "tags" {
  description = "Tags to apply to EFS and the related resources"
  type        = map(string)
  default     = {}
}
