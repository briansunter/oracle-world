# Variables for OCI Budget Alerts Module

variable "compartment_id" {
  description = "OCI compartment OCID (use tenancy OCID for root compartment)"
  type        = string
}

variable "budget_name" {
  description = "Display name for the budget"
  type        = string
  default     = "free-tier-budget"
}

variable "budget_amount" {
  description = "Monthly budget amount in USD (0 = alert on any charges)"
  type        = number
  default     = 0

  validation {
    condition     = var.budget_amount >= 0
    error_message = "Budget amount must be non-negative"
  }
}

variable "alert_email" {
  description = "Email address(es) to receive budget alerts (comma-separated for multiple)"
  type        = string

  validation {
    condition     = can(regex("^[^@]+@[^@]+\\.[^@]+", var.alert_email))
    error_message = "alert_email must be a valid email address"
  }
}

variable "tags" {
  description = "Freeform tags for resources"
  type        = map(string)
  default     = {}
}
