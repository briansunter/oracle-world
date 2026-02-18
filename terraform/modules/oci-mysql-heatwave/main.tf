# OCI MySQL HeatWave Module
# Creates MySQL Database Service with optional HeatWave cluster (Always Free tier)
#
# This module provisions:
#   - MySQL.Free DB system (50 GB storage)
#   - Optional HeatWave.Free cluster (single node, in-memory query acceleration)
#   - Automatic backups (1-day retention, Oracle-managed)
#
# Usage:
#   module "mysql" {
#     source = "../../modules/oci-mysql-heatwave"
#
#     compartment_id      = var.compartment_ocid
#     availability_domain = var.availability_domain
#     subnet_id           = module.network.subnet_id
#     db_system_name      = "my-mysql"
#     admin_password      = var.mysql_admin_password
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
# MySQL Database System (Always Free)
# =============================================================================

resource "oci_mysql_mysql_db_system" "main" {
  compartment_id      = var.compartment_id
  availability_domain = var.availability_domain
  subnet_id           = var.subnet_id
  display_name        = var.db_system_name

  # Always Free tier shape
  shape_name              = "MySQL.Free"
  data_storage_size_in_gb = 50 # Fixed for free tier

  # Admin credentials
  admin_username = var.admin_username
  admin_password = var.admin_password

  # Network
  hostname_label = var.hostname_label
  port           = 3306
  port_x         = 33060 # MySQL X Protocol

  # Always Free: backups are auto-enabled with 1-day retention (not configurable)
  # No backup_policy block needed - Oracle manages it for free tier

  # Configuration
  is_highly_available = false # Not available for free tier

  freeform_tags = var.tags

  # Prevent accidental deletion - uncomment to protect from destroy
  # lifecycle {
  #   prevent_destroy = true
  # }
}

# =============================================================================
# HeatWave Cluster (Always Free)
# =============================================================================

resource "oci_mysql_heat_wave_cluster" "main" {
  count        = var.enable_heatwave ? 1 : 0
  db_system_id = oci_mysql_mysql_db_system.main.id
  cluster_size = 1 # Free tier: single node
  shape_name   = "HeatWave.Free"

  is_lakehouse_enabled = var.enable_lakehouse
}
