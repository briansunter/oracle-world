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
}

variable "user_ocid" {
  description = "OCI user OCID (required when enable_object_storage = true, for S3-compatible credentials)"
  type        = string
  default     = ""
  # Find with: grep user ~/.oci/config
}

variable "availability_domain" {
  description = "Availability domain name (e.g., 'QjOL:US-SANJOSE-1-AD-1')"
  type        = string
  # Find with: oci iam availability-domain list
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
}

variable "subnet_cidr" {
  description = "CIDR block for the public subnet"
  type        = string
  default     = "10.0.0.0/24"
}

variable "private_subnet_cidr" {
  description = "CIDR block for the private subnet (MySQL)"
  type        = string
  default     = "10.0.1.0/24"
}

variable "ssh_source_cidr" {
  description = "CIDR allowed to SSH (port 22). Empty = SSH disabled. Use x.x.x.x/32 for a single IP."
  type        = string
  default     = ""
}

variable "additional_tcp_ports" {
  description = "TCP ports to open in VCN security list and instance iptables (0.0.0.0/0)"
  type        = list(number)
  default     = [443]
}

variable "additional_udp_ports" {
  description = "UDP ports to open in VCN security list and instance iptables (0.0.0.0/0)"
  type        = list(number)
  default     = []
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
  description = "Number of OCPUs (max 4 for Always Free)"
  type        = number
  default     = 4
}

variable "memory_in_gbs" {
  description = "Memory in GB (max 24 for Always Free)"
  type        = number
  default     = 24
}

variable "operating_system" {
  description = "Operating system for image lookup"
  type        = string
  default     = "Canonical Ubuntu"
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
}

variable "mysql_admin_password" {
  description = "MySQL admin password (8-32 chars, uppercase, lowercase, number, special char). Required when enable_mysql = true."
  type        = string
  sensitive   = true
  default     = ""
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
# Object Storage Configuration (Always Free - Paid Account)
# Paid accounts get 10 GB per tier separately = 30 GB total free:
#   - 10 GB Standard (hot) - frequently accessed
#   - 10 GB InfrequentAccess (warm) - auto-tiered after 30+ days no access
#   - 10 GB Archive (cold) - lifecycle policy after configured days
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
  description = "Open inbound ports and create NLB. When false, only SSH is allowed (via ssh_source_cidr)."
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
}

variable "budget_amount" {
  description = "Monthly budget amount in USD (0 = alert on any charges)"
  type        = number
  default     = 0
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

