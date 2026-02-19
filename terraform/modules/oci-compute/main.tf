# OCI Compute Module
# Creates an ARM-based Always Free tier instance
#
# This module provisions:
#   - VM.Standard.A1.Flex instance (Ampere ARM)
#   - Configurable OCPUs and memory
#   - Public IP assignment
#   - SSH key injection
#   - Boot volume with configurable size
#
# Usage:
#   module "instance" {
#     source = "../../modules/oci-compute"
#
#     compartment_id      = var.compartment_ocid
#     availability_domain = data.oci_identity_availability_domains.ads.availability_domains[0].name
#     subnet_id           = module.network.subnet_id
#     instance_name       = "my-oci-instance"
#     ssh_public_key      = var.ssh_public_key
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
# Data Sources
# =============================================================================

# Look up the latest ARM Ubuntu image
data "oci_core_images" "arm_ubuntu" {
  compartment_id           = var.compartment_id
  operating_system         = var.operating_system
  operating_system_version = var.os_version
  shape                    = var.shape
  sort_by                  = "TIMECREATED"
  sort_order               = "DESC"
}

# =============================================================================
# Instance
# =============================================================================

resource "oci_core_instance" "main" {
  compartment_id      = var.compartment_id
  availability_domain = var.availability_domain
  display_name        = var.instance_name
  shape               = var.shape

  shape_config {
    ocpus         = var.ocpus
    memory_in_gbs = var.memory_in_gbs
  }

  source_details {
    source_type             = "image"
    source_id               = data.oci_core_images.arm_ubuntu.images[0].id
    boot_volume_size_in_gbs = var.boot_volume_size_gb
  }

  create_vnic_details {
    subnet_id                 = var.subnet_id
    display_name              = "${var.instance_name}-vnic"
    assign_public_ip          = true
    assign_private_dns_record = true
    hostname_label            = var.hostname_label != "" ? var.hostname_label : replace(var.instance_name, "-", "")
  }

  metadata = {
    ssh_authorized_keys = var.ssh_public_key
    user_data           = var.user_data != "" ? base64encode(var.user_data) : null
  }

  agent_config {
    is_management_disabled = true
    is_monitoring_disabled = true
    plugins_config {
      desired_state = "DISABLED"
      name          = "Vulnerability Scanning"
    }
    plugins_config {
      desired_state = "DISABLED"
      name          = "Oracle Java Management Service"
    }
    plugins_config {
      desired_state = "DISABLED"
      name          = "OS Management Service Agent"
    }
    plugins_config {
      desired_state = "DISABLED"
      name          = "Management Agent"
    }
    plugins_config {
      desired_state = "ENABLED"
      name          = "Custom Logs Monitoring"
    }
    plugins_config {
      desired_state = "DISABLED"
      name          = "Compute RDMA GPU Monitoring"
    }
    plugins_config {
      desired_state = "ENABLED"
      name          = "Compute Instance Run Command"
    }
    plugins_config {
      desired_state = "ENABLED"
      name          = "Compute Instance Monitoring"
    }
    plugins_config {
      desired_state = "DISABLED"
      name          = "Compute HPC RDMA Auto-Configuration"
    }
    plugins_config {
      desired_state = "DISABLED"
      name          = "Compute HPC RDMA Authentication"
    }
    plugins_config {
      desired_state = "DISABLED"
      name          = "Block Volume Management"
    }
    plugins_config {
      desired_state = "DISABLED"
      name          = "Bastion"
    }
  }

  # Preserve boot volume on instance termination (useful for debugging)
  preserve_boot_volume = var.preserve_boot_volume

  freeform_tags = var.tags

  lifecycle {
    ignore_changes = [
      # Ignore changes to user_data after creation
      metadata["user_data"],
    ]
  }
}

# =============================================================================
# Boot Volume Backup Policy (Always Free — Bronze: weekly, 4 retained)
# =============================================================================

data "oci_core_volume_backup_policies" "oracle" {
  filter {
    name   = "display_name"
    values = [var.backup_policy_name]
  }
}

resource "oci_core_volume_backup_policy_assignment" "boot" {
  asset_id  = oci_core_instance.main.boot_volume_id
  policy_id = data.oci_core_volume_backup_policies.oracle.volume_backup_policies[0].id
}
