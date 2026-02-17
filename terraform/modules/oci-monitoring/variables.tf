# Variables for OCI Monitoring Module

variable "compartment_id" {
  description = "OCI compartment OCID"
  type        = string
}

variable "instance_id" {
  description = "OCID of the compute instance to monitor"
  type        = string
}

variable "notification_topic_name" {
  description = "Display name for the notification topic"
  type        = string
  default     = "free-tier-monitoring"
}

variable "alert_email" {
  description = "Email address for monitoring alerts"
  type        = string

  validation {
    condition     = can(regex("^[^@]+@[^@]+\\.[^@]+$", var.alert_email))
    error_message = "Must be a valid email address."
  }
}

# -----------------------------------------------------------------------------
# Idle / Reclaim Alerts
# -----------------------------------------------------------------------------
# Oracle reclaims Always Free instances deemed "idle" when ALL of these hold
# over a 7-day window:
#   - CPU utilization 95th percentile < 20%
#   - Network utilization < 20%
#   - Memory utilization < 20% (A1 shapes only)
#
# These alarms fire well before Oracle's 7-day window so you have time to act.
# -----------------------------------------------------------------------------

variable "enable_idle_alerts" {
  description = "Create alarms that warn when utilization drops near Oracle's reclaim thresholds"
  type        = bool
  default     = false
}

variable "cpu_idle_threshold" {
  description = "CPU % below which the idle alarm fires (Oracle reclaims at < 20%)"
  type        = number
  default     = 20

  validation {
    condition     = var.cpu_idle_threshold > 0 && var.cpu_idle_threshold <= 100
    error_message = "Must be between 1 and 100."
  }
}

variable "memory_idle_threshold" {
  description = "Memory % below which the idle alarm fires (Oracle reclaims at < 20%, A1 only)"
  type        = number
  default     = 20

  validation {
    condition     = var.memory_idle_threshold > 0 && var.memory_idle_threshold <= 100
    error_message = "Must be between 1 and 100."
  }
}

# -----------------------------------------------------------------------------
# High Utilization Alerts (optional)
# -----------------------------------------------------------------------------

variable "enable_high_utilization_alerts" {
  description = "Create alarms for high CPU/memory usage"
  type        = bool
  default     = false
}

variable "cpu_high_threshold" {
  description = "CPU % above which the high-utilization alarm fires"
  type        = number
  default     = 90

  validation {
    condition     = var.cpu_high_threshold > 0 && var.cpu_high_threshold <= 100
    error_message = "Must be between 1 and 100."
  }
}

variable "memory_high_threshold" {
  description = "Memory % above which the high-utilization alarm fires"
  type        = number
  default     = 90

  validation {
    condition     = var.memory_high_threshold > 0 && var.memory_high_threshold <= 100
    error_message = "Must be between 1 and 100."
  }
}

variable "tags" {
  description = "Freeform tags for resources"
  type        = map(string)
  default     = {}
}
