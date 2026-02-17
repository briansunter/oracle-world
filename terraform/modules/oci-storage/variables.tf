# Variables for oci-storage module

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
  description = "Availability domain name (must match instance AD)"
  type        = string
}

variable "instance_id" {
  description = "OCID of the instance to attach the volume to"
  type        = string

  validation {
    condition     = can(regex("^ocid1\\.instance\\.oc", var.instance_id))
    error_message = "instance_id must be a valid OCI instance OCID"
  }
}

variable "volume_name" {
  description = "Display name for the block volume"
  type        = string

  validation {
    condition     = can(regex("^[a-zA-Z][a-zA-Z0-9-]*$", var.volume_name))
    error_message = "volume_name must start with a letter and contain only alphanumeric characters and hyphens"
  }
}

# =============================================================================
# Size Configuration
# =============================================================================

variable "volume_size_gb" {
  description = "Volume size in GB (200 GB total included in Always Free)"
  type        = number
  default     = 150

  validation {
    condition     = var.volume_size_gb >= 50 && var.volume_size_gb <= 32768
    error_message = "volume_size_gb must be between 50 and 32768 GB"
  }
}

# =============================================================================
# Performance Configuration
# =============================================================================

variable "vpus_per_gb" {
  description = "VPUs per GB: 0 = Lower Cost, 10 = Balanced, 20 = Higher Performance"
  type        = number
  default     = 0

  validation {
    condition     = contains([0, 10, 20], var.vpus_per_gb)
    error_message = "vpus_per_gb must be 0, 10, or 20"
  }
}

variable "autotune_enabled" {
  description = "Enable performance auto-tuning"
  type        = bool
  default     = false
}

variable "max_vpus_per_gb" {
  description = "Maximum VPUs per GB for auto-tuning"
  type        = number
  default     = 20

  validation {
    condition     = contains([10, 20], var.max_vpus_per_gb)
    error_message = "max_vpus_per_gb must be 10 or 20"
  }
}

# =============================================================================
# Attachment Configuration
# =============================================================================

variable "device_path" {
  description = "Device path for attachment (e.g., /dev/oracleoci/oraclevdb). Leave empty for auto-assign."
  type        = string
  default     = ""
}

variable "is_read_only" {
  description = "Attach volume as read-only"
  type        = bool
  default     = false
}

variable "is_shareable" {
  description = "Allow volume to be attached to multiple instances (read-only mode)"
  type        = bool
  default     = false
}

# =============================================================================
# Optional Variables
# =============================================================================

variable "tags" {
  description = "Freeform tags to apply to all resources"
  type        = map(string)
  default     = {}
}
