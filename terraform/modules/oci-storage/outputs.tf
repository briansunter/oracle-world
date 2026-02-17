# Outputs for oci-storage module

output "volume_id" {
  description = "OCID of the block volume"
  value       = oci_core_volume.main.id
}

output "volume_size_gb" {
  description = "Size of the volume in GB"
  value       = oci_core_volume.main.size_in_gbs
}

output "volume_state" {
  description = "Current state of the volume"
  value       = oci_core_volume.main.state
}

output "attachment_id" {
  description = "OCID of the volume attachment"
  value       = oci_core_volume_attachment.main.id
}

output "attachment_state" {
  description = "Current state of the volume attachment"
  value       = oci_core_volume_attachment.main.state
}

output "device_path" {
  description = "Device path where the volume is attached (e.g., /dev/oracleoci/oraclevdb)"
  value       = oci_core_volume_attachment.main.device
}

output "iqn" {
  description = "iSCSI Qualified Name (for iSCSI attachments)"
  value       = oci_core_volume_attachment.main.iqn
}

output "is_pv_encryption_in_transit_enabled" {
  description = "Whether in-transit encryption is enabled"
  value       = oci_core_volume_attachment.main.is_pv_encryption_in_transit_enabled
}
