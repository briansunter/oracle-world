# Variables for oci-compute module

# =============================================================================
# Required Variables
# =============================================================================

variable "compartment_id" {
  description = "OCI compartment OCID"
  type        = string

  validation {
    condition     = can(regex("^ocid1\\.(compartment|tenancy)\\.oc", var.compartment_id))
    error_message = "compartment_id must be a valid OCI compartment or tenancy OCID"
  }
}

variable "availability_domain" {
  description = "Availability domain name (e.g., 'Uocm:US-SANJOSE-1-AD-1')"
  type        = string
}

variable "subnet_id" {
  description = "OCID of the subnet to attach the instance to"
  type        = string

  validation {
    condition     = can(regex("^ocid1\\.subnet\\.oc", var.subnet_id))
    error_message = "subnet_id must be a valid OCI subnet OCID"
  }
}

variable "instance_name" {
  description = "Display name for the instance"
  type        = string

  validation {
    condition     = can(regex("^[a-zA-Z][a-zA-Z0-9-]*$", var.instance_name))
    error_message = "instance_name must start with a letter and contain only alphanumeric characters and hyphens"
  }
}

variable "ssh_public_key" {
  description = "SSH public key for instance access"
  type        = string

  validation {
    condition     = can(regex("^ssh-(rsa|ed25519|ecdsa)", var.ssh_public_key))
    error_message = "ssh_public_key must be a valid SSH public key"
  }
}

# =============================================================================
# Shape Configuration
# =============================================================================

variable "shape" {
  description = "Instance shape (VM.Standard.A1.Flex for Always Free ARM)"
  type        = string
  default     = "VM.Standard.A1.Flex"

  validation {
    condition     = contains(["VM.Standard.A1.Flex", "VM.Standard.E2.1.Micro"], var.shape)
    error_message = "shape must be a valid OCI Always Free tier shape"
  }
}

variable "ocpus" {
  description = "Number of OCPUs (max 4 for Always Free A1)"
  type        = number
  default     = 4

  validation {
    condition     = var.ocpus >= 1 && var.ocpus <= 4
    error_message = "ocpus must be between 1 and 4 for Always Free tier"
  }
}

variable "memory_in_gbs" {
  description = "Memory in GB (max 24 for Always Free A1)"
  type        = number
  default     = 24

  validation {
    condition     = var.memory_in_gbs >= 1 && var.memory_in_gbs <= 24
    error_message = "memory_in_gbs must be between 1 and 24 for Always Free tier"
  }
}

# =============================================================================
# OS Configuration
# =============================================================================

variable "operating_system" {
  description = "Operating system name for image lookup"
  type        = string
  default     = "Canonical Ubuntu"
}

variable "os_version" {
  description = "Operating system version for image lookup"
  type        = string
  default     = "24.04 Minimal aarch64"
}

# =============================================================================
# Storage Configuration
# =============================================================================

variable "boot_volume_size_gb" {
  description = "Boot volume size in GB (50 GB included in Always Free)"
  type        = number
  default     = 50

  validation {
    condition     = var.boot_volume_size_gb >= 47 && var.boot_volume_size_gb <= 200
    error_message = "boot_volume_size_gb must be between 47 and 200 GB"
  }
}

variable "preserve_boot_volume" {
  description = "Preserve boot volume when instance is terminated"
  type        = bool
  default     = false
}

# =============================================================================
# Optional Variables
# =============================================================================

variable "hostname_label" {
  description = "Hostname label for DNS (defaults to instance_name without hyphens)"
  type        = string
  default     = ""
}

variable "user_data" {
  description = "Cloud-init user data script"
  type        = string
  default     = ""
}

variable "backup_policy_name" {
  description = "OCI backup policy name (bronze = weekly, 4 retained)"
  type        = string
  default     = "bronze"
}

variable "tags" {
  description = "Freeform tags to apply to all resources"
  type        = map(string)
  default     = {}
}
