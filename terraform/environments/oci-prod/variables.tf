# Variables for OCI Production Environment
#
# OCI authentication is handled by ~/.oci/config (standard OCI CLI format).
# Required in oci-prod.auto.tfvars: compartment_ocid, availability_domain, ssh_public_key

# =============================================================================
# OCI Configuration (from oci-prod.auto.tfvars)
# =============================================================================

variable "compartment_ocid" {
  description = "OCI compartment OCID (use tenancy OCID for root compartment)"
  type        = string
  # Find with: oci iam compartment list (or use tenancy OCID from ~/.oci/config)

  validation {
    condition     = can(regex("^ocid1\\.(compartment|tenancy)\\.oc", var.compartment_ocid))
    error_message = "compartment_ocid must be a valid OCI compartment or tenancy OCID"
  }
}

variable "tenancy_ocid" {
  description = "OCI tenancy OCID used for region discovery and root-scoped policies (optional for backwards compatibility; defaults to compartment_ocid)"
  type        = string
  default     = ""

  validation {
    condition     = var.tenancy_ocid == "" || can(regex("^ocid1\\.tenancy\\.oc", var.tenancy_ocid))
    error_message = "tenancy_ocid must be empty or a valid OCI tenancy OCID"
  }
}

variable "user_ocid" {
  description = "OCI user OCID (required when enable_object_storage = true, for S3-compatible credentials)"
  type        = string
  default     = ""
  # Find with: grep user ~/.oci/config

  validation {
    condition     = var.user_ocid == "" || can(regex("^ocid1\\.user\\.oc", var.user_ocid))
    error_message = "user_ocid must be empty or a valid OCI user OCID"
  }
}

variable "availability_domain" {
  description = "Availability domain name (e.g., 'QjOL:US-SANJOSE-1-AD-1')"
  type        = string

  validation {
    condition     = can(regex("^[^:]+:[A-Za-z0-9-]+-AD-[0-9]+$", var.availability_domain))
    error_message = "availability_domain must look like '<realm>:<REGION>-AD-<number>'"
  }
}

# =============================================================================
# Instance Configuration
# =============================================================================

variable "instance_name" {
  description = "Display name for the instance"
  type        = string
  default     = "oci-free-tier"
}

variable "ssh_public_key" {
  description = "SSH public key for instance access"
  type        = string
  # No default - must be provided via TF_VAR_ssh_public_key
}

# =============================================================================
# Network Configuration
# =============================================================================

variable "vcn_cidr" {
  description = "CIDR block for the VCN"
  type        = string
  default     = "10.0.0.0/16"

  validation {
    condition     = can(cidrhost(var.vcn_cidr, 0))
    error_message = "vcn_cidr must be a valid CIDR block"
  }
}

variable "subnet_cidr" {
  description = "CIDR block for the public subnet"
  type        = string
  default     = "10.0.0.0/24"

  validation {
    condition     = can(cidrhost(var.subnet_cidr, 0))
    error_message = "subnet_cidr must be a valid CIDR block"
  }
}

variable "private_subnet_cidr" {
  description = "CIDR block for the private subnet (MySQL)"
  type        = string
  default     = "10.0.1.0/24"

  validation {
    condition     = can(cidrhost(var.private_subnet_cidr, 0))
    error_message = "private_subnet_cidr must be a valid CIDR block"
  }
}

variable "ssh_source_cidr" {
  description = "CIDR allowed to SSH (port 22). Empty = SSH disabled. Use x.x.x.x/32 for a single IP."
  type        = string
  default     = ""

  validation {
    condition     = var.ssh_source_cidr == "" || (can(cidrhost(var.ssh_source_cidr, 0)) && can(regex("/32$", var.ssh_source_cidr)))
    error_message = "ssh_source_cidr must be empty or a valid single-IP /32 CIDR"
  }
}

variable "additional_tcp_ports" {
  description = "TCP ports to open in VCN security list and instance iptables (0.0.0.0/0)"
  type        = list(number)
  default     = [80, 443]

  validation {
    condition     = alltrue([for port in var.additional_tcp_ports : port >= 1 && port <= 65535]) && length(var.additional_tcp_ports) == length(distinct(var.additional_tcp_ports)) && !contains(var.additional_tcp_ports, 22)
    error_message = "TCP ports must be unique, between 1 and 65535, and must not include 22; use ssh_source_cidr for SSH"
  }
}

variable "additional_udp_ports" {
  description = "UDP ports to open in VCN security list and instance iptables (0.0.0.0/0)"
  type        = list(number)
  default     = []

  validation {
    condition     = alltrue([for port in var.additional_udp_ports : port >= 1 && port <= 65535]) && length(var.additional_udp_ports) == length(distinct(var.additional_udp_ports))
    error_message = "UDP ports must be unique and between 1 and 65535"
  }
}

variable "dns_label" {
  description = "DNS label for the VCN"
  type        = string
  default     = "ocifreetier"
}

# =============================================================================
# Compute Configuration (Always Free Tier)
# =============================================================================

variable "ocpus" {
  description = "Number of OCPUs (max 2 for the current Always Free A1 entitlement)"
  type        = number
  default     = 2

  validation {
    condition     = var.ocpus >= 1 && var.ocpus <= 2
    error_message = "ocpus must be between 1 and 2 for the current Always Free A1 entitlement"
  }
}

variable "memory_in_gbs" {
  description = "Memory in GB (max 12 for the current Always Free A1 entitlement)"
  type        = number
  default     = 12

  validation {
    condition     = var.memory_in_gbs >= 1 && var.memory_in_gbs <= 12
    error_message = "memory_in_gbs must be between 1 and 12 GB for the current Always Free A1 entitlement"
  }
}

variable "operating_system" {
  description = "Operating system for image lookup"
  type        = string
  default     = "Canonical Ubuntu"

  validation {
    condition     = contains(["Canonical Ubuntu", "Oracle Linux"], var.operating_system)
    error_message = "operating_system must be Canonical Ubuntu or Oracle Linux to remain Always Free eligible"
  }
}

variable "os_version" {
  description = "OS version for image lookup"
  type        = string
  default     = "24.04 Minimal aarch64"
}

# =============================================================================
# Storage Configuration
# =============================================================================

variable "boot_volume_size_gb" {
  description = "Boot volume size in GB"
  type        = number
  default     = 50

  validation {
    condition     = var.boot_volume_size_gb >= 47 && var.boot_volume_size_gb <= 200
    error_message = "boot_volume_size_gb must be between 47 and 200 GB"
  }
}

variable "enable_block_volume" {
  description = "Create block volume for persistent data"
  type        = bool
  default     = true
}

variable "block_volume_size_gb" {
  description = "Block volume size in GB"
  type        = number
  default     = 150

  validation {
    condition     = var.block_volume_size_gb >= 50 && var.block_volume_size_gb <= 200
    error_message = "block_volume_size_gb must be between 50 and 200 GB"
  }
}

# =============================================================================
# MySQL Configuration (Always Free Tier)
# =============================================================================

variable "enable_mysql" {
  description = "Deploy MySQL HeatWave (creates private subnet and DB system)"
  type        = bool
  default     = false
}

variable "mysql_admin_username" {
  description = "MySQL admin username"
  type        = string
  default     = "admin"

  validation {
    condition     = can(regex("^[a-zA-Z][a-zA-Z0-9_]*$", var.mysql_admin_username))
    error_message = "mysql_admin_username must start with a letter and contain only alphanumeric characters and underscores"
  }
}

variable "mysql_admin_password" {
  description = "MySQL admin password (8-32 chars, uppercase, lowercase, number, special char). Required when enable_mysql = true."
  type        = string
  sensitive   = true
  default     = ""

  validation {
    condition = var.mysql_admin_password == "" || (
      length(var.mysql_admin_password) >= 8 &&
      length(var.mysql_admin_password) <= 32 &&
      can(regex("[A-Z]", var.mysql_admin_password)) &&
      can(regex("[a-z]", var.mysql_admin_password)) &&
      can(regex("[0-9]", var.mysql_admin_password)) &&
      can(regex("[^a-zA-Z0-9]", var.mysql_admin_password))
    )
    error_message = "mysql_admin_password must be empty when MySQL is disabled or 8-32 characters with uppercase, lowercase, number, and special character"
  }
}

variable "mysql_enable_heatwave" {
  description = "Enable HeatWave cluster (HeatWave.Free shape)"
  type        = bool
  default     = true
}

variable "mysql_enable_lakehouse" {
  description = "Enable HeatWave Lakehouse for object storage queries"
  type        = bool
  default     = false
}

# =============================================================================
# Object Storage Configuration (Always Free-only profile)
# Keep all Object Storage data, including the remote-state bucket, below the
# 20 GB combined Always Free-only account limit.
# =============================================================================

variable "enable_object_storage" {
  description = "Deploy S3-compatible Object Storage bucket with auto-tiering"
  type        = bool
  default     = false
}

variable "object_storage_bucket_name" {
  description = "Name of the Object Storage bucket"
  type        = string
  default     = "oci-free-tier-storage"
}

variable "object_storage_versioning" {
  description = "Enable object versioning"
  type        = bool
  default     = false
}

variable "object_storage_auto_tiering" {
  description = "Enable auto-tiering between Standard and InfrequentAccess based on access patterns"
  type        = bool
  default     = true
}

variable "object_storage_archive_enabled" {
  description = "Enable lifecycle policy to move objects to Archive tier"
  type        = bool
  default     = false
}

variable "object_storage_archive_days" {
  description = "Move objects to Archive tier after this many days (minimum 90-day retention applies)"
  type        = number
  default     = 180
}

variable "object_storage_delete_days" {
  description = "Delete objects after this many days (0 = never delete)"
  type        = number
  default     = 0
}

# =============================================================================
# Public Access
# =============================================================================

variable "enable_public_access" {
  description = "Open inbound ports. When false, only SSH is allowed (via ssh_source_cidr)."
  type        = bool
  default     = true
}

# =============================================================================
# Monitoring Alerts — Idle Detection (Reclaim Prevention)
# Oracle reclaims Always Free instances deemed "idle" over a 7-day window:
#   CPU (95th pctl) < 20%, Network < 20%, Memory < 20% (A1 only)
# =============================================================================

variable "enable_idle_alerts" {
  description = "Create alarms that warn when utilization drops near Oracle's reclaim thresholds"
  type        = bool
  default     = false
}

variable "cpu_idle_threshold" {
  description = "CPU % below which the idle alarm fires (Oracle reclaims at < 20%)"
  type        = number
  default     = 20
}

variable "memory_idle_threshold" {
  description = "Memory % below which the idle alarm fires (Oracle reclaims at < 20%, A1 only)"
  type        = number
  default     = 20
}

# =============================================================================
# Monitoring Alerts — High Utilization (Optional)
# =============================================================================

variable "enable_high_utilization_alerts" {
  description = "Create alarms for high CPU/memory usage"
  type        = bool
  default     = false
}

variable "cpu_high_threshold" {
  description = "CPU % above which the high-utilization alarm fires"
  type        = number
  default     = 90
}

variable "memory_high_threshold" {
  description = "Memory % above which the high-utilization alarm fires"
  type        = number
  default     = 90
}

# =============================================================================
# Budget Alert Configuration
# =============================================================================

variable "alert_email" {
  description = "Email address for budget and monitoring alerts (required when alerts are enabled)"
  type        = string
  default     = ""

  validation {
    condition     = var.alert_email == "" || can(regex("^[^@,[:space:]]+@[^@,[:space:]]+\\.[^@,[:space:]]+$", var.alert_email))
    error_message = "alert_email must be empty or a single valid email address"
  }
}

variable "budget_amount" {
  description = "Monthly budget amount in USD (0 = alert on any charges)"
  type        = number
  default     = 0

  validation {
    condition     = var.budget_amount >= 0
    error_message = "budget_amount must be non-negative"
  }
}

# =============================================================================
# State Encryption
# =============================================================================

variable "state_passphrase" {
  description = "Passphrase for encrypting state files at rest (set via TF_VAR_state_passphrase env var, min 16 chars)"
  type        = string
  sensitive   = true

  validation {
    condition     = length(var.state_passphrase) >= 16
    error_message = "state_passphrase must be at least 16 characters. Run ./generate-env.sh to generate one."
  }
}
