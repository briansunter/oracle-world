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

  validation {
    condition     = can(regex("^[^:]+:[A-Za-z0-9-]+-AD-[0-9]+$", var.availability_domain))
    error_message = "availability_domain must look like '<realm>:<REGION>-AD-<number>'"
  }
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
    condition     = var.shape == "VM.Standard.A1.Flex"
    error_message = "shape must be VM.Standard.A1.Flex; the environment supports the ARM Always Free profile only"
  }
}

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
    error_message = "memory_in_gbs must be between 1 and 12 for the current Always Free A1 entitlement"
  }
}

# =============================================================================
# OS Configuration
# =============================================================================

variable "operating_system" {
  description = "Operating system name for image lookup"
  type        = string
  default     = "Canonical Ubuntu"

  validation {
    condition     = contains(["Canonical Ubuntu", "Oracle Linux"], var.operating_system)
    error_message = "operating_system must be Canonical Ubuntu or Oracle Linux to remain Always Free eligible"
  }
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
  description = "Preserve boot volume when instance is terminated (disabled to avoid consuming extra Always Free storage)"
  type        = bool
  default     = false

  validation {
    condition     = var.preserve_boot_volume == false
    error_message = "preserve_boot_volume must be false in the Always Free profile"
  }
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

  validation {
    condition     = var.backup_policy_name == "bronze"
    error_message = "backup_policy_name must be bronze to remain within the five Always Free backup limit"
  }
}

variable "tags" {
  description = "Freeform tags to apply to all resources"
  type        = map(string)
  default     = {}
}
