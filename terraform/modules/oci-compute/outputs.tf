# Outputs for oci-compute module

output "instance_id" {
  description = "OCID of the instance"
  value       = oci_core_instance.main.id
}

output "instance_state" {
  description = "Current state of the instance"
  value       = oci_core_instance.main.state
}

output "public_ip" {
  description = "Public IP address of the instance"
  value       = oci_core_instance.main.public_ip
}

output "private_ip" {
  description = "Private IP address of the instance"
  value       = oci_core_instance.main.private_ip
}

output "boot_volume_id" {
  description = "OCID of the boot volume"
  value       = oci_core_instance.main.boot_volume_id
}

output "image_id" {
  description = "OCID of the image used"
  value       = data.oci_core_images.arm_ubuntu.images[0].id
}

output "image_name" {
  description = "Display name of the image used"
  value       = data.oci_core_images.arm_ubuntu.images[0].display_name
}

output "ssh_connection" {
  description = "SSH connection string"
  value       = "ssh ubuntu@${oci_core_instance.main.public_ip}"
}

output "availability_domain" {
  description = "Availability domain of the instance"
  value       = oci_core_instance.main.availability_domain
}

output "boot_backup_policy" {
  description = "Boot volume backup policy name"
  value       = data.oci_core_volume_backup_policies.oracle.volume_backup_policies[0].display_name
}
