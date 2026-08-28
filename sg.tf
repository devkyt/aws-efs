# ---------------------------------------------
# Security Group For The EFS Mount Targets
# ---------------------------------------------
resource "aws_security_group" "main" {
  name        = var.use_name_prefix ? null : "${local.name}-efs"
  name_prefix = var.use_name_prefix ? "${local.name}-efs-" : null
  description = "Security group for ${local.name}-efs"
  vpc_id      = var.vpc_id

  tags = merge(local.tags,
    {
      Name = "${local.name}-efs"
      Type = "Security Group"
    }
  )

  lifecycle {
    create_before_destroy = true
  }
}


# ---------------------------------------------
# Ingress Rules — One Per Configured Source
# ---------------------------------------------
resource "aws_vpc_security_group_ingress_rule" "main" {
  for_each = var.ingress

  security_group_id = aws_security_group.main.id

  description                  = coalesce(each.value.description, "Allow ingress to EFS on port ${each.value.port}")
  referenced_security_group_id = each.value.allowed_security_group_id
  cidr_ipv4                    = each.value.cidr_ipv4
  cidr_ipv6                    = each.value.cidr_ipv6
  prefix_list_id               = each.value.prefix_list_id
  ip_protocol                  = each.value.protocol
  from_port                    = each.value.port
  to_port                      = each.value.port

  tags = merge(local.tags,
    {
      Name = "${local.name}-ingress-${each.key}"
      Type = "Ingress Rule For Security Group"
      Port = each.value.port
    }
  )
}
