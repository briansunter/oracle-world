# OCI Network Module
# Creates VCN, public + private subnets, internet gateway, route tables, and security lists
#
# This module provides the networking foundation for OCI instances:
#   - VCN with configurable CIDR
#   - Public subnet with internet gateway (for compute)
#   - Private subnet with no internet route (for MySQL)
#   - Security lists for both subnets
#   - Configurable SSH and TCP/UDP ingress rules
#
# Usage:
#   module "network" {
#     source = "../../modules/oci-network"
#
#     compartment_id = var.compartment_ocid
#     vcn_name       = "my-oci-vcn"
#   }

terraform {
  required_providers {
    oci = {
      source  = "oracle/oci"
      version = ">= 5.0"
    }
  }
}

# =============================================================================
# VCN (Virtual Cloud Network)
# =============================================================================

resource "oci_core_vcn" "main" {
  compartment_id = var.compartment_id
  display_name   = var.vcn_name
  cidr_blocks    = [var.vcn_cidr]
  dns_label      = var.dns_label

  freeform_tags = var.tags
}

# =============================================================================
# Internet Gateway
# =============================================================================

resource "oci_core_internet_gateway" "main" {
  compartment_id = var.compartment_id
  vcn_id         = oci_core_vcn.main.id
  display_name   = "${var.vcn_name}-igw"
  enabled        = true

  freeform_tags = var.tags
}

# =============================================================================
# Route Table
# =============================================================================

resource "oci_core_route_table" "public" {
  compartment_id = var.compartment_id
  vcn_id         = oci_core_vcn.main.id
  display_name   = "${var.vcn_name}-public-rt"

  route_rules {
    destination       = "0.0.0.0/0"
    destination_type  = "CIDR_BLOCK"
    network_entity_id = oci_core_internet_gateway.main.id
  }

  freeform_tags = var.tags
}

# =============================================================================
# Security List
# =============================================================================

resource "oci_core_security_list" "main" {
  compartment_id = var.compartment_id
  vcn_id         = oci_core_vcn.main.id
  display_name   = "${var.vcn_name}-security-list"

  # Egress: Allow all outbound traffic
  egress_security_rules {
    destination = "0.0.0.0/0"
    protocol    = "all"
    stateless   = false
  }

  # Ingress: ICMP Type 3 Code 4 (Path MTU Discovery)
  ingress_security_rules {
    source    = "0.0.0.0/0"
    protocol  = "1" # ICMP
    stateless = false

    icmp_options {
      type = 3
      code = 4
    }
  }

  # Ingress: ICMP Type 8 (Echo Request/Ping)
  ingress_security_rules {
    source    = "0.0.0.0/0"
    protocol  = "1" # ICMP
    stateless = false

    icmp_options {
      type = 8
    }
  }

  # Ingress: SSH (port 22) — restricted to ssh_source_cidr
  dynamic "ingress_security_rules" {
    for_each = var.ssh_source_cidr != "" ? [var.ssh_source_cidr] : []
    content {
      source    = ingress_security_rules.value
      protocol  = "6" # TCP
      stateless = false

      tcp_options {
        min = 22
        max = 22
      }
    }
  }

  # Ingress: Additional TCP ports
  dynamic "ingress_security_rules" {
    for_each = var.additional_tcp_ports
    content {
      source    = "0.0.0.0/0"
      protocol  = "6" # TCP
      stateless = false

      tcp_options {
        min = ingress_security_rules.value
        max = ingress_security_rules.value
      }
    }
  }

  # Ingress: Additional UDP ports
  dynamic "ingress_security_rules" {
    for_each = var.additional_udp_ports
    content {
      source    = "0.0.0.0/0"
      protocol  = "17" # UDP
      stateless = false

      udp_options {
        min = ingress_security_rules.value
        max = ingress_security_rules.value
      }
    }
  }

  freeform_tags = var.tags
}

# =============================================================================
# Public Subnet
# =============================================================================

resource "oci_core_subnet" "public" {
  compartment_id             = var.compartment_id
  vcn_id                     = oci_core_vcn.main.id
  display_name               = "${var.vcn_name}-public-subnet"
  cidr_block                 = var.subnet_cidr
  dns_label                  = "public"
  route_table_id             = oci_core_route_table.public.id
  security_list_ids          = [oci_core_security_list.main.id]
  prohibit_public_ip_on_vnic = false

  freeform_tags = var.tags
}

# =============================================================================
# Private Subnet (for MySQL — no internet access)
# =============================================================================

resource "oci_core_route_table" "private" {
  compartment_id = var.compartment_id
  vcn_id         = oci_core_vcn.main.id
  display_name   = "${var.vcn_name}-private-rt"

  # No route rules — VCN-local routing is automatic, no internet access
  freeform_tags = var.tags
}

resource "oci_core_security_list" "private" {
  compartment_id = var.compartment_id
  vcn_id         = oci_core_vcn.main.id
  display_name   = "${var.vcn_name}-private-security-list"

  # Egress: Allow all (route table enforces no internet)
  egress_security_rules {
    destination = "0.0.0.0/0"
    protocol    = "all"
    stateless   = false
  }

  # Ingress: MySQL from public subnet only
  ingress_security_rules {
    source    = var.subnet_cidr
    protocol  = "6" # TCP
    stateless = false

    tcp_options {
      min = 3306
      max = 3306
    }
  }

  # Ingress: MySQL X Protocol from public subnet only
  ingress_security_rules {
    source    = var.subnet_cidr
    protocol  = "6" # TCP
    stateless = false

    tcp_options {
      min = 33060
      max = 33060
    }
  }

  # Ingress: ICMP Type 3 Code 4 (Path MTU Discovery) from VCN
  ingress_security_rules {
    source    = var.vcn_cidr
    protocol  = "1" # ICMP
    stateless = false

    icmp_options {
      type = 3
      code = 4
    }
  }

  freeform_tags = var.tags
}

resource "oci_core_subnet" "private" {
  compartment_id             = var.compartment_id
  vcn_id                     = oci_core_vcn.main.id
  display_name               = "${var.vcn_name}-private-subnet"
  cidr_block                 = var.private_subnet_cidr
  dns_label                  = "db"
  route_table_id             = oci_core_route_table.private.id
  security_list_ids          = [oci_core_security_list.private.id]
  prohibit_public_ip_on_vnic = true

  freeform_tags = var.tags
}
