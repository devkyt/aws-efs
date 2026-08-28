# ---------------------------------------------
# File System Access Policy And Its Attachment
# ---------------------------------------------
data "aws_iam_policy_document" "main" {
  dynamic "statement" {
    for_each = var.iam_policy
    content {
      sid     = statement.value.sid
      effect  = statement.value.effect
      actions = statement.value.actions

      resources = [aws_efs_file_system.main.arn]

      principals {
        type        = statement.value.principals.type
        identifiers = statement.value.principals.identifiers
      }

      dynamic "condition" {
        for_each = statement.value.conditions
        content {
          test     = condition.value.test
          variable = condition.value.variable
          values   = condition.value.values
        }
      }
    }
  }

  dynamic "statement" {
    for_each = var.enforce_ssl ? ["enable"] : []

    content {
      sid    = "DenyInsecureTransport"
      effect = "Deny"

      principals {
        type        = "*"
        identifiers = ["*"]
      }

      actions = [
        "elasticfilesystem:ClientMount",
        "elasticfilesystem:ClientWrite",
        "elasticfilesystem:ClientRootAccess",
      ]

      resources = [aws_efs_file_system.main.arn]

      condition {
        test     = "Bool"
        variable = "aws:SecureTransport"
        values   = ["false"]
      }
    }
  }

  lifecycle {
    enabled = local.create_efs_policy
  }
}


resource "aws_efs_file_system_policy" "main" {
  file_system_id = aws_efs_file_system.main.id
  policy         = data.aws_iam_policy_document.main.json

  lifecycle {
    enabled = local.create_efs_policy
  }
}
