# Variables for oci-object-storage module

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

variable "bucket_name" {
  description = "Name of the Object Storage bucket (must be unique within namespace)"
  type        = string

  validation {
    condition     = can(regex("^[a-zA-Z][a-zA-Z0-9._-]{0,255}$", var.bucket_name))
    error_message = "bucket_name must start with a letter and contain only alphanumeric characters, dots, underscores, and hyphens (max 256 chars)"
  }
}

# =============================================================================
# Storage Configuration
# =============================================================================

variable "storage_tier" {
  description = "Storage tier: Standard (hot), InfrequentAccess (warm), or Archive (cold)"
  type        = string
  default     = "Standard"

  validation {
    condition     = contains(["Standard", "InfrequentAccess", "Archive"], var.storage_tier)
    error_message = "storage_tier must be Standard, InfrequentAccess, or Archive"
  }
}

variable "public_access" {
  description = "Allow public read access to objects (ObjectRead). Default: false (NoPublicAccess)"
  type        = bool
  default     = false
}

variable "enable_versioning" {
  description = "Enable object versioning for data protection"
  type        = bool
  default     = false
}

variable "enable_auto_tiering" {
  description = "Enable auto-tiering between Standard and InfrequentAccess (only for Standard tier)"
  type        = bool
  default     = false
}

variable "enable_object_events" {
  description = "Enable object events for notification integration"
  type        = bool
  default     = false
}

# =============================================================================
# Lifecycle Policy Configuration
# =============================================================================

variable "enable_lifecycle_policy" {
  description = "Enable lifecycle rules for automatic tier transitions and deletion"
  type        = bool
  default     = false
}

variable "lifecycle_prefix" {
  description = "Object name prefix for lifecycle rules (empty = all objects)"
  type        = string
  default     = ""
}

variable "infrequent_access_days" {
  description = "Move objects to InfrequentAccess tier after this many days (0 = disabled)"
  type        = number
  default     = 0

  validation {
    condition     = var.infrequent_access_days >= 0
    error_message = "infrequent_access_days must be 0 or greater"
  }
}

variable "archive_days" {
  description = "Move objects to Archive tier after this many days (0 = disabled). Minimum 90-day retention applies."
  type        = number
  default     = 0

  validation {
    condition     = var.archive_days == 0 || var.archive_days >= 90
    error_message = "archive_days must be 0 (disabled) or >= 90 (OCI Archive tier has a 90-day minimum retention)"
  }
}

variable "delete_after_days" {
  description = "Delete objects after this many days (0 = disabled)"
  type        = number
  default     = 0

  validation {
    condition     = var.delete_after_days >= 0
    error_message = "delete_after_days must be 0 or greater"
  }
}

# =============================================================================
# Pre-Authenticated Request (PAR) Configuration
# =============================================================================

variable "create_par" {
  description = "Create a pre-authenticated request for S3-compatible access"
  type        = bool
  default     = false
}

variable "par_access_type" {
  description = "PAR access type: ObjectRead, ObjectWrite, ObjectReadWrite, AnyObjectRead, AnyObjectWrite, AnyObjectReadWrite"
  type        = string
  default     = "AnyObjectReadWrite"

  validation {
    condition = contains([
      "ObjectRead", "ObjectWrite", "ObjectReadWrite",
      "AnyObjectRead", "AnyObjectWrite", "AnyObjectReadWrite"
    ], var.par_access_type)
    error_message = "par_access_type must be a valid PAR access type"
  }
}

variable "par_expiry" {
  description = "PAR expiration time in RFC3339 format (e.g., 2025-12-31T23:59:59Z)"
  type        = string
  default     = ""

  validation {
    condition     = var.par_expiry == "" || can(regex("^\\d{4}-\\d{2}-\\d{2}T\\d{2}:\\d{2}:\\d{2}Z$", var.par_expiry))
    error_message = "par_expiry must be in RFC3339 format (e.g., 2025-12-31T23:59:59Z)"
  }
}

# =============================================================================
# Optional Variables
# =============================================================================

variable "metadata" {
  description = "User-defined metadata for the bucket"
  type        = map(string)
  default     = {}
}

variable "tags" {
  description = "Freeform tags to apply to all resources"
  type        = map(string)
  default     = {}
}

variable "region" {
  description = "OCI region (e.g., us-sanjose-1). Used for S3-compatible endpoint URLs."
  type        = string
  default     = ""
}
