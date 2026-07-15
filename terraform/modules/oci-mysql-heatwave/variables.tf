# Variables for oci-mysql-heatwave module

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
  description = "Availability domain name"
  type        = string
}

variable "subnet_id" {
  description = "OCID of the subnet for the MySQL DB system"
  type        = string

  validation {
    condition     = can(regex("^ocid1\\.subnet\\.oc", var.subnet_id))
    error_message = "subnet_id must be a valid OCI subnet OCID"
  }
}

variable "db_system_name" {
  description = "Display name for the MySQL DB system"
  type        = string

  validation {
    condition     = can(regex("^[a-zA-Z][a-zA-Z0-9-]*$", var.db_system_name))
    error_message = "db_system_name must start with a letter and contain only alphanumeric characters and hyphens"
  }
}

variable "admin_password" {
  description = "Admin password (8-32 chars, uppercase, lowercase, number, special char)"
  type        = string
  sensitive   = true

  validation {
    condition = (
      length(var.admin_password) >= 8 &&
      length(var.admin_password) <= 32 &&
      can(regex("[A-Z]", var.admin_password)) &&
      can(regex("[a-z]", var.admin_password)) &&
      can(regex("[0-9]", var.admin_password)) &&
      can(regex("[^a-zA-Z0-9]", var.admin_password))
    )
    error_message = "admin_password must be 8-32 characters with uppercase, lowercase, number, and special character"
  }
}

# =============================================================================
# Optional Variables
# =============================================================================

variable "admin_username" {
  description = "Admin username for the MySQL DB system"
  type        = string
  default     = "admin"

  validation {
    condition     = can(regex("^[a-zA-Z][a-zA-Z0-9_]*$", var.admin_username))
    error_message = "admin_username must start with a letter and contain only alphanumeric characters and underscores"
  }
}

variable "hostname_label" {
  description = "Hostname label for the DB system (used in DNS)"
  type        = string
  default     = "mysql"

  validation {
    condition     = can(regex("^[a-z][a-z0-9-]*$", var.hostname_label)) && length(var.hostname_label) <= 63
    error_message = "hostname_label must start with a lowercase letter, contain only lowercase alphanumeric characters and hyphens, and be max 63 characters"
  }
}

# =============================================================================
# HeatWave Configuration
# =============================================================================

variable "enable_heatwave" {
  description = "Enable HeatWave cluster (HeatWave.Free shape)"
  type        = bool
  default     = true
}

variable "enable_lakehouse" {
  description = "Enable HeatWave Lakehouse for object storage queries"
  type        = bool
  default     = false
}

# =============================================================================
# Tags
# =============================================================================

variable "tags" {
  description = "Freeform tags to apply to all resources"
  type        = map(string)
  default     = {}
}
