# OCI Storage Module
# Creates block volumes and attachments for persistent data
#
# This module provisions:
#   - Block volume with configurable size
#   - Paravirtualized attachment to instance
#   - VPUs (performance) configuration
#
# Usage:
#   module "storage" {
#     source = "../../modules/oci-storage"
#
#     compartment_id      = var.compartment_ocid
#     availability_domain = data.oci_identity_availability_domains.ads.availability_domains[0].name
#     instance_id         = module.instance.instance_id
#     volume_name         = "my-oci-instance-data"
#     volume_size_gb      = 150
#   }
#
# Note: Formatting and mounting is performed by the environment cloud-init
# adapter after the attachment is available.

terraform {
  required_providers {
    oci = {
      source  = "oracle/oci"
      version = ">= 5.0"
    }
  }
}

# =============================================================================
# Block Volume
# =============================================================================

resource "oci_core_volume" "main" {
  compartment_id      = var.compartment_id
  availability_domain = var.availability_domain
  display_name        = var.volume_name
  size_in_gbs         = var.volume_size_gb

  # VPUs per GB: 0 = Lower Cost, 10 = Balanced, 20 = Higher Performance
  # Always Free tier: 200 GB total block storage, 0 VPUs (Lower Cost)
  vpus_per_gb = var.vpus_per_gb

  freeform_tags = var.tags
}

# =============================================================================
# Volume Attachment
# =============================================================================

resource "oci_core_volume_attachment" "main" {
  attachment_type = "paravirtualized"
  instance_id     = var.instance_id
  volume_id       = oci_core_volume.main.id
  display_name    = "${var.volume_name}-attachment"

  # Device path (e.g., /dev/oracleoci/oraclevdb)
  # If not specified, OCI will auto-assign
  device = var.device_path != "" ? var.device_path : null

  # Read-only attachment (useful for backups)
  is_read_only = var.is_read_only

  # Shareable across instances (for read-only use cases)
  is_shareable = var.is_shareable
}
