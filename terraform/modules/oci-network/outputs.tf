# Outputs for oci-network module

output "vcn_id" {
  description = "OCID of the VCN"
  value       = oci_core_vcn.main.id
}

output "vcn_cidr" {
  description = "CIDR block of the VCN"
  value       = oci_core_vcn.main.cidr_blocks[0]
}

output "subnet_id" {
  description = "OCID of the public subnet"
  value       = oci_core_subnet.public.id
}

output "subnet_cidr" {
  description = "CIDR block of the public subnet"
  value       = oci_core_subnet.public.cidr_block
}

output "internet_gateway_id" {
  description = "OCID of the internet gateway"
  value       = oci_core_internet_gateway.main.id
}

output "security_list_id" {
  description = "OCID of the security list"
  value       = oci_core_security_list.main.id
}

output "route_table_id" {
  description = "OCID of the public route table"
  value       = oci_core_route_table.public.id
}

output "private_subnet_id" {
  description = "OCID of the private subnet"
  value       = var.enable_private_subnet ? oci_core_subnet.private[0].id : null
}

output "private_subnet_cidr" {
  description = "CIDR block of the private subnet"
  value       = var.enable_private_subnet ? oci_core_subnet.private[0].cidr_block : null
}
