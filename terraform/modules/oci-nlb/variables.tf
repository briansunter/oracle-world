# Variables for OCI Network Load Balancer

variable "compartment_id" {
  description = "OCI compartment OCID"
  type        = string
}

variable "subnet_id" {
  description = "Subnet OCID for the NLB"
  type        = string
}

variable "nlb_name" {
  description = "Display name for the Network Load Balancer"
  type        = string
  default     = "instance-nlb"
}

variable "backend_ip" {
  description = "Private IP of the backend instance"
  type        = string
}

variable "tcp_ports" {
  description = "TCP ports to forward to the backend (e.g., [443] or [80, 443])"
  type        = list(number)
  default     = [443]

  validation {
    condition     = length(var.tcp_ports) > 0
    error_message = "At least one TCP port is required"
  }

  validation {
    condition     = alltrue([for p in var.tcp_ports : p >= 1 && p <= 65535])
    error_message = "All ports must be between 1 and 65535"
  }
}

variable "tags" {
  description = "Freeform tags for resources"
  type        = map(string)
  default     = {}
}
