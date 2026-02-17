# OCI Network Load Balancer (Always Free)
# Provides a stable public IP in front of a compute instance.
# The NLB IP survives instance recreation — no DNS updates needed.
#
# Usage:
#   module "nlb" {
#     source = "../../modules/oci-nlb"
#
#     compartment_id = var.compartment_ocid
#     subnet_id      = module.network.subnet_id
#     backend_ip     = module.compute.private_ip
#     tcp_ports      = [443]
#   }

terraform {
  required_providers {
    oci = {
      source  = "oracle/oci"
      version = ">= 5.0"
    }
  }
}

# =============================================================================
# Network Load Balancer (Always Free — 1 per tenancy)
# =============================================================================

resource "oci_network_load_balancer_network_load_balancer" "main" {
  compartment_id = var.compartment_id
  display_name   = var.nlb_name
  subnet_id      = var.subnet_id

  is_private                     = false
  is_preserve_source_destination = false

  freeform_tags = var.tags
}

# =============================================================================
# One backend set + listener + backend per TCP port
# =============================================================================

resource "oci_network_load_balancer_backend_set" "tcp" {
  for_each = toset([for p in var.tcp_ports : tostring(p)])

  name                     = "tcp-${each.value}"
  network_load_balancer_id = oci_network_load_balancer_network_load_balancer.main.id
  policy                   = "FIVE_TUPLE"

  health_checker {
    protocol           = "TCP"
    port               = tonumber(each.value)
    interval_in_millis = 10000
    timeout_in_millis  = 3000
    retries            = 3
  }
}

resource "oci_network_load_balancer_listener" "tcp" {
  for_each = toset([for p in var.tcp_ports : tostring(p)])

  name                     = "tcp-${each.value}"
  network_load_balancer_id = oci_network_load_balancer_network_load_balancer.main.id
  default_backend_set_name = oci_network_load_balancer_backend_set.tcp[each.value].name
  port                     = tonumber(each.value)
  protocol                 = "TCP"
}

resource "oci_network_load_balancer_backend" "tcp" {
  for_each = toset([for p in var.tcp_ports : tostring(p)])

  backend_set_name         = oci_network_load_balancer_backend_set.tcp[each.value].name
  network_load_balancer_id = oci_network_load_balancer_network_load_balancer.main.id
  port                     = tonumber(each.value)
  ip_address               = var.backend_ip
}
