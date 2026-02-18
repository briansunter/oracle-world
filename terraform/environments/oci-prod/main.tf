# OCI Always Free Tier Infrastructure
#
# Default deployment (lean):
#   - Network: VCN, public subnet, internet gateway, security list
#   - Compute: VM.Standard.A1.Flex ARM instance (4 OCPUs, 24 GB RAM)
#   - Storage: 50 GB boot volume + 150 GB block volume
#   - NLB: Network Load Balancer with stable public IP (when enable_public_access = true)
#
# Optional modules (off by default):
#   - MySQL: Always Free HeatWave cluster (enable_mysql = true)
#   - Object Storage: S3-compatible bucket with auto-tiering (enable_object_storage = true)
#   - Monitoring: Idle-detection alarms (enable_idle_alerts = true)
#   - Budget: Free tier monitoring alerts (when alert_email is set)
#
# Prerequisites:
#   1. Set up ~/.oci/config with your OCI credentials
#   2. Copy oci-prod.auto.tfvars.example to oci-prod.auto.tfvars and fill in values
#
# Usage:
#   tofu init    # or: terraform init
#   tofu plan
#   tofu apply

terraform {
  required_version = ">= 1.7"

  required_providers {
    oci = {
      source  = "oracle/oci"
      version = ">= 5.0"
    }
  }

  # State encryption (OpenTofu 1.7+)
  # Encrypts state and plan files at rest so secrets aren't plaintext on disk.
  # Set via .env: TF_VAR_state_passphrase="..." (min 16 chars, loaded by `just`)
  encryption {
    key_provider "pbkdf2" "main" {
      passphrase = var.state_passphrase
    }

    method "aes_gcm" "main" {
      keys = key_provider.pbkdf2.main
    }

    state {
      method   = method.aes_gcm.main
      enforced = true
    }

    plan {
      method   = method.aes_gcm.main
      enforced = true
    }
  }

  # Remote backend: OCI Object Storage (S3-compatible)
  # Set AWS_ACCESS_KEY_ID and AWS_SECRET_ACCESS_KEY in .env
  backend "s3" {
    bucket                      = "terraform-state"
    key                         = "oci-prod/terraform.tfstate"
    region                      = "us-sanjose-1"
    endpoints                   = { s3 = "https://axeolpvc5niy.compat.objectstorage.us-sanjose-1.oraclecloud.com" }
    skip_region_validation      = true
    skip_credentials_validation = true
    skip_requesting_account_id  = true
    skip_metadata_api_check     = true
    use_path_style              = true
  }
}

# =============================================================================
# Providers
# =============================================================================

provider "oci" {
  config_file_profile = "DEFAULT"
}

# =============================================================================
# Derived Configuration
# =============================================================================

locals {
  # When public access is disabled, no inbound ports are opened anywhere:
  # VCN security list, instance iptables (cloud-init), and NLB.
  # Only SSH (via ssh_source_cidr) remains available.
  tcp_ports = var.enable_public_access ? var.additional_tcp_ports : []
  udp_ports = var.enable_public_access ? var.additional_udp_ports : []

  cloud_init = templatefile("${path.module}/cloud-init.yaml.tftpl", {
    tcp_ports           = local.tcp_ports
    udp_ports           = local.udp_ports
    enable_block_volume = var.enable_block_volume
  })
}

# =============================================================================
# Network Module (Independent - not destroyed when recreating compute)
# =============================================================================

module "network" {
  source = "../../modules/oci-network"

  compartment_id      = var.compartment_ocid
  vcn_name            = "${var.instance_name}-vcn"
  vcn_cidr            = var.vcn_cidr
  subnet_cidr         = var.subnet_cidr
  private_subnet_cidr = var.private_subnet_cidr
  dns_label           = var.dns_label

  # Private subnet is only needed for MySQL
  enable_private_subnet = var.enable_mysql

  # SSH access — restricted to a single IP (use `just my-ip` to find yours)
  # Empty string = SSH disabled. Set to "x.x.x.x/32" to allow from one IP.
  ssh_source_cidr = var.ssh_source_cidr

  # Inbound ports open to the internet (0.0.0.0/0)
  # Empty when enable_public_access = false.
  additional_tcp_ports = local.tcp_ports
  additional_udp_ports = local.udp_ports

  tags = {
    environment = "prod"
    managed_by  = "terraform"
  }
}

# =============================================================================
# Compute Module (Can be destroyed/recreated without affecting network or MySQL)
# =============================================================================

module "compute" {
  source = "../../modules/oci-compute"

  compartment_id      = var.compartment_ocid
  availability_domain = var.availability_domain
  subnet_id           = module.network.subnet_id
  instance_name       = var.instance_name
  ssh_public_key      = var.ssh_public_key

  # Shape configuration (Always Free maximums)
  shape         = "VM.Standard.A1.Flex"
  ocpus         = var.ocpus
  memory_in_gbs = var.memory_in_gbs

  # OS configuration
  operating_system = var.operating_system
  os_version       = var.os_version

  # Storage configuration
  boot_volume_size_gb  = var.boot_volume_size_gb
  preserve_boot_volume = false

  # Cloud-init: iptables, SSH hardening, unattended upgrades
  user_data = local.cloud_init

  tags = {
    environment = "prod"
    managed_by  = "terraform"
  }
}

# =============================================================================
# Storage Module (Block Volume - attached to compute)
# =============================================================================

module "storage" {
  source = "../../modules/oci-storage"
  count  = var.enable_block_volume ? 1 : 0

  compartment_id      = var.compartment_ocid
  availability_domain = var.availability_domain
  instance_id         = module.compute.instance_id
  volume_name         = "${var.instance_name}-data"

  volume_size_gb   = var.block_volume_size_gb
  vpus_per_gb      = 0 # Lower cost tier
  autotune_enabled = false

  tags = {
    environment = "prod"
    managed_by  = "terraform"
  }
}

# =============================================================================
# MySQL HeatWave (Always Free — off by default)
# =============================================================================

resource "terraform_data" "validate_mysql_password" {
  count = var.enable_mysql ? 1 : 0

  lifecycle {
    precondition {
      condition     = var.mysql_admin_password != ""
      error_message = "mysql_admin_password is required when enable_mysql = true. Run ./generate-env.sh --force --mysql to generate one."
    }
  }
}

module "mysql" {
  source = "../../modules/oci-mysql-heatwave"
  count  = var.enable_mysql ? 1 : 0

  compartment_id      = var.compartment_ocid
  availability_domain = var.availability_domain
  subnet_id           = module.network.private_subnet_id
  db_system_name      = "${var.instance_name}-mysql"

  admin_username = var.mysql_admin_username
  admin_password = var.mysql_admin_password

  enable_heatwave  = var.mysql_enable_heatwave
  enable_lakehouse = var.mysql_enable_lakehouse

  tags = {
    environment = "prod"
    managed_by  = "terraform"
  }
}

# =============================================================================
# S3-Compatible Credentials (Customer Secret Key — only when object storage enabled)
# =============================================================================

resource "oci_identity_customer_secret_key" "s3_access" {
  count = var.enable_object_storage ? 1 : 0

  display_name = "${var.instance_name}-s3-access"
  user_id      = var.user_ocid
}

# =============================================================================
# IAM Policy for Object Storage Lifecycle
# Required for auto-archive lifecycle policies to work
# =============================================================================

resource "oci_identity_policy" "object_storage_lifecycle" {
  count = var.enable_object_storage ? 1 : 0

  compartment_id = var.compartment_ocid
  name           = "object-storage-lifecycle-policy"
  description    = "Allow Object Storage service to manage objects for lifecycle policies"

  statements = [
    "Allow service objectstorage-${module.object_storage[0].region} to manage object-family in tenancy"
  ]

  freeform_tags = {
    environment = "prod"
    managed_by  = "terraform"
  }
}

# =============================================================================
# Object Storage (Always Free - Paid Account — off by default)
# Paid accounts get 10 GB each tier separately = 30 GB total free
#   - 10 GB Standard (hot)
#   - 10 GB InfrequentAccess (warm)
#   - 10 GB Archive (cold)
#
# Auto-tiering automatically moves objects between Standard and InfrequentAccess
# based on access patterns. Lifecycle policy moves to Archive after configured days.
# =============================================================================

module "object_storage" {
  source = "../../modules/oci-object-storage"
  count  = var.enable_object_storage ? 1 : 0

  compartment_id = var.compartment_ocid
  bucket_name    = var.object_storage_bucket_name

  # Start in Standard tier
  storage_tier = "Standard"

  # Auto-tiering: automatically moves objects between Standard <-> InfrequentAccess
  # based on access patterns (30+ days no access -> InfrequentAccess)
  enable_auto_tiering = var.object_storage_auto_tiering

  # Versioning for data protection (optional)
  enable_versioning = var.object_storage_versioning

  # Lifecycle policy: move to Archive after configured days
  # Archive has 90-day minimum retention, ~1 hour restore time
  enable_lifecycle_policy = var.object_storage_archive_enabled
  archive_days            = var.object_storage_archive_days
  delete_after_days       = var.object_storage_delete_days

  tags = {
    environment = "prod"
    managed_by  = "terraform"
  }
}

# =============================================================================
# Network Load Balancer (Always Free — 1 per tenancy)
# Stable public IP in front of the compute instance.
# The NLB IP survives instance recreation — no DNS updates needed.
# MySQL stays private (VCN-only) — connect via SSH tunnel from the instance.
# =============================================================================

module "nlb" {
  source = "../../modules/oci-nlb"
  count  = var.enable_public_access ? 1 : 0

  compartment_id = var.compartment_ocid
  subnet_id      = module.network.subnet_id
  nlb_name       = "${var.instance_name}-nlb"
  backend_ip     = module.compute.private_ip
  tcp_ports      = local.tcp_ports

  tags = {
    environment = "prod"
    managed_by  = "terraform"
  }
}

# =============================================================================
# Monitoring Alarms (Idle Detection + Optional High Utilization)
# Oracle reclaims Always Free instances deemed "idle" over a 7-day window:
#   CPU (95th pctl) < 20%, Network < 20%, Memory < 20% (A1 only)
# These alarms fire early so you can generate load before reclamation.
# =============================================================================

resource "terraform_data" "validate_alert_email" {
  count = (var.enable_idle_alerts || var.enable_high_utilization_alerts) ? 1 : 0

  lifecycle {
    precondition {
      condition     = var.alert_email != ""
      error_message = "alert_email is required when enable_idle_alerts or enable_high_utilization_alerts is true."
    }
  }
}

module "monitoring" {
  source = "../../modules/oci-monitoring"
  count  = (var.enable_idle_alerts || var.enable_high_utilization_alerts) ? 1 : 0

  compartment_id          = var.compartment_ocid
  instance_id             = module.compute.instance_id
  notification_topic_name = "${var.instance_name}-monitoring"
  alert_email             = var.alert_email

  # Idle detection (reclaim prevention) — off by default
  enable_idle_alerts    = var.enable_idle_alerts
  cpu_idle_threshold    = var.cpu_idle_threshold
  memory_idle_threshold = var.memory_idle_threshold

  # High utilization — off by default
  enable_high_utilization_alerts = var.enable_high_utilization_alerts
  cpu_high_threshold             = var.cpu_high_threshold
  memory_high_threshold          = var.memory_high_threshold

  tags = {
    environment = "prod"
    managed_by  = "terraform"
  }
}

# =============================================================================
# Boot Volume Backup (Always Free — Bronze policy: weekly, 4 retained)
# =============================================================================

data "oci_core_volume_backup_policies" "oracle" {
  filter {
    name   = "display_name"
    values = ["bronze"]
  }
}

resource "oci_core_volume_backup_policy_assignment" "boot" {
  asset_id  = module.compute.boot_volume_id
  policy_id = data.oci_core_volume_backup_policies.oracle.volume_backup_policies[0].id
}

# =============================================================================
# Budget Alerts (Free Tier Monitoring)
# =============================================================================

module "budget_alerts" {
  source = "../../modules/oci-budget-alerts"
  count  = var.alert_email != "" ? 1 : 0

  compartment_id = var.compartment_ocid
  budget_name    = "${var.instance_name}-budget"
  budget_amount  = var.budget_amount
  alert_email    = var.alert_email

  tags = {
    environment = "prod"
    managed_by  = "terraform"
  }
}
