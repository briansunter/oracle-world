# OCI Always Free Tier Infrastructure
#
# Default deployment (lean):
#   - Network: VCN, public subnet, internet gateway, security list
#   - Compute: VM.Standard.A1.Flex ARM instance (2 OCPUs, 12 GB RAM)
#   - Storage: 50 GB boot volume + 150 GB block volume
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

  # Remote state: OCI Object Storage (S3-compatible).
  # AWS_ACCESS_KEY_ID and AWS_SECRET_ACCESS_KEY are loaded from .env by just.
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

data "oci_identity_region_subscriptions" "home" {
  tenancy_id = local.tenancy_id
}

locals {
  tenancy_id                 = var.tenancy_ocid != "" ? var.tenancy_ocid : var.compartment_ocid
  region                     = one([for subscription in data.oci_identity_region_subscriptions.home.region_subscriptions : subscription.region_name if subscription.is_home_region])
  availability_domain_region = can(regex("^[^:]+:[A-Za-z0-9-]+-AD-[0-9]+$", var.availability_domain)) ? lower(split("-AD-", split(":", var.availability_domain)[1])[0]) : ""

  # When public access is disabled, no inbound ports are opened anywhere:
  # VCN security list and instance iptables (cloud-init).
  # Only SSH (via ssh_source_cidr) remains available.
  tcp_ports = var.enable_public_access ? var.additional_tcp_ports : []
  udp_ports = var.enable_public_access ? var.additional_udp_ports : []

  cloud_init = templatefile("${path.module}/cloud-init.yaml.tftpl", {
    tcp_ports = local.tcp_ports
    udp_ports = local.udp_ports
    # Keep the host firewall ready for the targeted ssh-allow/ssh-revoke
    # recipes. The VCN security list remains the authoritative source-CIDR
    # gate, so an empty ssh_source_cidr still exposes no SSH ingress.
    enable_ssh          = true
    enable_block_volume = var.enable_block_volume
  })
}

# Keep the deployment contract explicit at the root seam. These checks cover
# combinations that individual module variable validation cannot see.
resource "terraform_data" "validate_configuration" {
  input = {
    compartment_ocid     = var.compartment_ocid
    tenancy_id           = local.tenancy_id
    boot_volume_size_gb  = var.boot_volume_size_gb
    block_volume_size_gb = var.enable_block_volume ? var.block_volume_size_gb : 0
  }

  lifecycle {
    precondition {
      condition     = var.boot_volume_size_gb + (var.enable_block_volume ? var.block_volume_size_gb : 0) <= 200
      error_message = "Boot plus block volume storage must remain within the 200 GB Always Free combined limit"
    }

    precondition {
      condition     = var.tenancy_ocid != "" || can(regex("^ocid1\\.tenancy\\.oc", var.compartment_ocid))
      error_message = "tenancy_ocid is required unless compartment_ocid is the tenancy OCID"
    }

    precondition {
      condition     = local.availability_domain_region != "" && local.availability_domain_region == lower(local.region)
      error_message = "availability_domain must be in the tenancy home region (${local.region}) to remain Always Free eligible"
    }

    precondition {
      condition     = !var.enable_object_storage || var.user_ocid != ""
      error_message = "user_ocid is required when enable_object_storage = true so S3-compatible credentials can be created"
    }

    precondition {
      condition     = !var.mysql_enable_lakehouse || (var.enable_mysql && var.mysql_enable_heatwave && var.enable_object_storage)
      error_message = "mysql_enable_lakehouse requires enable_mysql, mysql_enable_heatwave, and enable_object_storage to all be true"
    }

    precondition {
      condition     = length(var.additional_tcp_ports) == length(distinct(var.additional_tcp_ports)) && length(var.additional_udp_ports) == length(distinct(var.additional_udp_ports))
      error_message = "Additional TCP and UDP port lists must not contain duplicates"
    }
  }
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

  volume_size_gb = var.block_volume_size_gb
  vpus_per_gb    = 0 # Lower cost tier

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
      error_message = "mysql_admin_password is required when enable_mysql = true. Run ./generate-env.sh --add-mysql to append one to the existing .env."
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
# Object Storage (Always Free-only profile — off by default)
# Keep all Object Storage data, including the remote-state bucket, below 20 GB.
#
# Auto-tiering automatically moves objects between Standard and InfrequentAccess
# based on access patterns. Lifecycle policy moves to Archive after configured days.
# =============================================================================

module "object_storage" {
  source = "../../modules/oci-object-storage"
  count  = var.enable_object_storage ? 1 : 0

  compartment_id = var.compartment_ocid
  bucket_name    = var.object_storage_bucket_name
  region         = local.region
  user_id        = var.user_ocid
  instance_name  = var.instance_name

  # Start in Standard tier
  storage_tier = "Standard"

  # Auto-tiering: automatically moves objects between Standard <-> InfrequentAccess
  # based on access patterns. All tiers share the 20 GB Always Free-only quota.
  enable_auto_tiering = var.object_storage_auto_tiering

  # Versioning for data protection (optional)
  enable_versioning = var.object_storage_versioning

  # Lifecycle policy: move to Archive after configured days
  # Archive has 90-day minimum retention, ~1 hour restore time
  enable_lifecycle_policy = var.object_storage_archive_enabled || var.object_storage_delete_days > 0
  archive_days            = var.object_storage_archive_enabled ? var.object_storage_archive_days : 0
  delete_after_days       = var.object_storage_delete_days
  policy_compartment_id   = local.tenancy_id

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
