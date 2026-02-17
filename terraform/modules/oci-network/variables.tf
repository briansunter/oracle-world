# Variables for oci-network module

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

variable "vcn_name" {
  description = "Display name for the VCN"
  type        = string

  validation {
    condition     = can(regex("^[a-zA-Z][a-zA-Z0-9-]*$", var.vcn_name))
    error_message = "vcn_name must start with a letter and contain only alphanumeric characters and hyphens"
  }
}

# =============================================================================
# Optional Variables
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

variable "dns_label" {
  description = "DNS label for the VCN (used for internal DNS resolution)"
  type        = string
  default     = "ocifreetier"

  validation {
    condition     = can(regex("^[a-z][a-z0-9]{0,14}$", var.dns_label))
    error_message = "dns_label must be lowercase, start with a letter, and be max 15 characters"
  }
}

variable "tags" {
  description = "Freeform tags to apply to all resources"
  type        = map(string)
  default     = {}
}

# =============================================================================
# SSH Configuration
# =============================================================================

variable "ssh_source_cidr" {
  description = "CIDR allowed to SSH (port 22). Empty string = SSH disabled. Use x.x.x.x/32 for a single IP."
  type        = string
  default     = ""

  validation {
    condition     = var.ssh_source_cidr == "" || can(cidrhost(var.ssh_source_cidr, 0))
    error_message = "ssh_source_cidr must be empty (disabled) or a valid CIDR block (e.g., 203.0.113.5/32)"
  }
}

# =============================================================================
# Ingress Port Configuration
# =============================================================================

variable "enable_private_subnet" {
  description = "Create private subnet (required for MySQL)"
  type        = bool
  default     = false
}

variable "additional_tcp_ports" {
  description = "TCP ports to allow inbound from 0.0.0.0/0 (e.g., [22, 443, 80])"
  type        = list(number)
  default     = []

  validation {
    condition     = alltrue([for port in var.additional_tcp_ports : port >= 1 && port <= 65535])
    error_message = "All ports must be between 1 and 65535"
  }
}

variable "additional_udp_ports" {
  description = "UDP ports to allow inbound from 0.0.0.0/0 (e.g., [51820] for WireGuard)"
  type        = list(number)
  default     = []

  validation {
    condition     = alltrue([for port in var.additional_udp_ports : port >= 1 && port <= 65535])
    error_message = "All ports must be between 1 and 65535"
  }
}
