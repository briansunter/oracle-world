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
    condition     = var.volume_size_gb >= 50 && var.volume_size_gb <= 200
    error_message = "volume_size_gb must be between 50 and 200 GB for the Always Free tier"
  }
}

# =============================================================================
# Performance Configuration
# =============================================================================

variable "vpus_per_gb" {
  description = "VPUs per GB; Always Free block volumes use the Lower Cost level"
  type        = number
  default     = 0

  validation {
    condition     = var.vpus_per_gb == 0
    error_message = "vpus_per_gb must be 0 (Lower Cost) for the Always Free tier"
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
