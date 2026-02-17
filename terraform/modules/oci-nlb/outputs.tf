# Outputs for OCI Network Load Balancer

output "nlb_id" {
  description = "OCID of the Network Load Balancer"
  value       = oci_network_load_balancer_network_load_balancer.main.id
}

output "public_ip" {
  description = "Public IP address of the NLB"
  value       = oci_network_load_balancer_network_load_balancer.main.ip_addresses[0].ip_address
}
