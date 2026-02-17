# Outputs for OCI Production Environment

# =============================================================================
# Compute Outputs
# =============================================================================

output "instance_id" {
  description = "OCID of the instance"
  value       = module.compute.instance_id
}

output "public_ip" {
  description = "Public IP address (NLB if enabled, otherwise direct instance IP)"
  value       = var.enable_public_access ? module.nlb[0].public_ip : module.compute.public_ip
}

output "instance_ip" {
  description = "Direct public IP of the instance (use NLB IP for services)"
  value       = module.compute.public_ip
}

output "private_ip" {
  description = "Private IP address of the instance"
  value       = module.compute.private_ip
}

output "ssh_connection" {
  description = "SSH connection string"
  value       = module.compute.ssh_connection
}

output "availability_domain" {
  description = "Availability domain of the instance"
  value       = module.compute.availability_domain
}

output "image_name" {
  description = "Image used for the instance"
  value       = module.compute.image_name
}

output "boot_volume_id" {
  description = "OCID of the boot volume"
  value       = module.compute.boot_volume_id
}

# =============================================================================
# Network Outputs
# =============================================================================

output "vcn_id" {
  description = "OCID of the VCN"
  value       = module.network.vcn_id
}

output "subnet_id" {
  description = "OCID of the subnet"
  value       = module.network.subnet_id
}

output "security_list_id" {
  description = "OCID of the security list"
  value       = module.network.security_list_id
}

output "private_subnet_id" {
  description = "OCID of the private subnet (MySQL)"
  value       = module.network.private_subnet_id
}

# =============================================================================
# Storage Outputs
# =============================================================================

output "block_volume_id" {
  description = "OCID of the block volume"
  value       = var.enable_block_volume ? module.storage[0].volume_id : null
}

output "block_volume_device_path" {
  description = "Device path for the block volume"
  value       = var.enable_block_volume ? module.storage[0].device_path : null
}

# =============================================================================
# Instance Summary
# =============================================================================

output "summary" {
  description = "Human-readable summary of the instance"
  value       = <<-EOT
    OCI ARM Instance: ${var.instance_name}
    ─────────────────────────────────────
    ${var.enable_public_access ? "NLB IP:       ${module.nlb[0].public_ip} (stable — use for DNS/services)\n    " : ""}Instance IP:  ${module.compute.public_ip}${var.enable_public_access ? " (direct — changes on recreate)" : ""}
    Private IP:   ${module.compute.private_ip}
    SSH Command:  ssh ubuntu@${module.compute.public_ip}

    Shape:        VM.Standard.A1.Flex
    OCPUs:        ${var.ocpus}
    Memory:       ${var.memory_in_gbs} GB
    Boot Volume:  ${var.boot_volume_size_gb} GB
    Block Volume: ${var.enable_block_volume ? "${var.block_volume_size_gb} GB" : "disabled"}
    Public:       ${var.enable_public_access ? "enabled (NLB + ports ${join(", ", var.additional_tcp_ports)})" : "disabled (SSH only)"}

    Image:        ${module.compute.image_name}
    AD:           ${module.compute.availability_domain}
  EOT
}

# =============================================================================
# MySQL HeatWave Outputs
# =============================================================================

output "mysql_db_system_id" {
  description = "OCID of the MySQL DB system"
  value       = module.mysql.db_system_id
}

output "mysql_ip_address" {
  description = "IP address of the MySQL DB system"
  value       = module.mysql.ip_address
}

output "mysql_port" {
  description = "MySQL port"
  value       = module.mysql.port
}

output "mysql_connection_string" {
  description = "MySQL connection string"
  value       = module.mysql.connection_string
}

output "mysql_connection_command" {
  description = "MySQL CLI connection command"
  value       = module.mysql.connection_command
}

output "mysql_heatwave_enabled" {
  description = "Whether HeatWave cluster is enabled"
  value       = module.mysql.heatwave_enabled
}

output "mysql_summary" {
  description = "Human-readable MySQL summary"
  value       = module.mysql.summary
}

# =============================================================================
# Object Storage Outputs (Always Free - Paid Account: 30 GB total)
# =============================================================================

output "object_storage_bucket_name" {
  description = "Object Storage bucket name"
  value       = module.object_storage.bucket_name
}

output "object_storage_namespace" {
  description = "Object Storage namespace"
  value       = module.object_storage.namespace
}

output "object_storage_s3_endpoint" {
  description = "S3-compatible endpoint"
  value       = module.object_storage.s3_endpoint
}

output "object_storage_cli_upload" {
  description = "OCI CLI upload command"
  value       = module.object_storage.oci_cli_upload
}

output "object_storage_cli_list" {
  description = "OCI CLI list command"
  value       = module.object_storage.oci_cli_list
}

output "object_storage_summary" {
  description = "Human-readable Object Storage summary"
  value       = module.object_storage.summary
}

# S3-Compatible Credentials
output "s3_access_key" {
  description = "S3-compatible access key (use as AWS_ACCESS_KEY_ID)"
  value       = oci_identity_customer_secret_key.s3_access.id
}

output "s3_secret_key" {
  description = "S3-compatible secret key (use as AWS_SECRET_ACCESS_KEY)"
  value       = oci_identity_customer_secret_key.s3_access.key
  sensitive   = true
}

output "s3_endpoint" {
  description = "S3-compatible endpoint URL"
  value       = "https://${module.object_storage.namespace}.compat.objectstorage.${module.object_storage.region}.oraclecloud.com"
}

output "s3_config" {
  description = "AWS CLI / S3 configuration"
  value       = <<-EOT
    # Add to ~/.aws/credentials:
    [oci]
    aws_access_key_id = ${oci_identity_customer_secret_key.s3_access.id}
    aws_secret_access_key = <run: tofu output -raw s3_secret_key>

    # Add to ~/.aws/config:
    [profile oci]
    region = us-east-1
    s3 =
        signature_version = s3v4
        addressing_style = path

    # Required env vars for AWS CLI 2.23.5+:
    export AWS_REQUEST_CHECKSUM_CALCULATION=when_required
    export AWS_RESPONSE_CHECKSUM_VALIDATION=when_required

    # Usage:
    aws s3 ls s3://${module.object_storage.bucket_name} --endpoint-url ${module.object_storage.s3_endpoint} --profile oci
    aws s3 cp myfile.txt s3://${module.object_storage.bucket_name}/ --endpoint-url ${module.object_storage.s3_endpoint} --profile oci
  EOT
}

# =============================================================================
# Next Steps
# =============================================================================

output "next_steps" {
  description = "Post-deployment instructions"
  value       = <<-EOT

    ╔══════════════════════════════════════════════════════════════════════╗
    ║                    OCI Always Free Instance Ready                   ║
    ╚══════════════════════════════════════════════════════════════════════╝

    1. SSH to the instance:
       ssh ubuntu@${module.compute.public_ip}

    2. Connect to MySQL (from the instance via SSH):
       ssh ubuntu@${module.compute.public_ip} -L 3306:${module.mysql.ip_address}:3306
       mysql -h 127.0.0.1 -P 3306 -u ${var.mysql_admin_username} -p

    3. Object Storage:
       Bucket:    ${module.object_storage.bucket_name}
       Namespace: ${module.object_storage.namespace}
       Upload:    ${module.object_storage.oci_cli_upload}

    4. S3-compatible endpoint:
       ${module.object_storage.s3_endpoint}

    Free Tier Limits:
    ┌──────────────────────────────────────────────────────────────────────┐
    │ Compute: 4 OCPUs, 24 GB RAM (VM.Standard.A1.Flex)                  │
    │ Storage: 200 GB total block storage                                │
    │ MySQL:   50 GB Always Free HeatWave                                │
    │ Object:  10 GB Standard + 10 GB Infrequent + 10 GB Archive = 30 GB│
    │ NLB:     ${format("%-59s", var.enable_public_access ? "1 Network Load Balancer" : "disabled")}│
    ├──────────────────────────────────────────────────────────────────────┤
    │ Idle Reclaim: Oracle stops instances when ALL hold over 7 days:    │
    │   CPU 95th pctl < 20% AND Network < 20% AND Memory < 20% (A1)     │
    │ Monitoring: ${format("%-55s", length(module.monitoring) > 0 ? "${module.monitoring[0].alarm_count} alarms active (email: ${var.alert_email})" : "disabled (set enable_idle_alerts + alert_email)")}│
    └──────────────────────────────────────────────────────────────────────┘

  EOT
}

# =============================================================================
# Network Load Balancer Outputs
# =============================================================================

output "nlb_id" {
  description = "OCID of the Network Load Balancer"
  value       = var.enable_public_access ? module.nlb[0].nlb_id : null
}

output "nlb_public_ip" {
  description = "Stable public IP of the NLB (use for DNS records)"
  value       = var.enable_public_access ? module.nlb[0].public_ip : null
}

# =============================================================================
# Monitoring Outputs
# =============================================================================

output "monitoring_topic_id" {
  description = "OCID of the monitoring notification topic"
  value       = length(module.monitoring) > 0 ? module.monitoring[0].notification_topic_id : null
}

output "monitoring_alarm_count" {
  description = "Number of monitoring alarms"
  value       = length(module.monitoring) > 0 ? module.monitoring[0].alarm_count : 0
}

output "monitoring_summary" {
  description = "Monitoring alert summary"
  value       = length(module.monitoring) > 0 ? module.monitoring[0].summary : "Monitoring disabled (set enable_idle_alerts = true to enable)"
}

# =============================================================================
# Budget Alert Outputs
# =============================================================================

output "budget_id" {
  description = "OCID of the budget"
  value       = length(module.budget_alerts) > 0 ? module.budget_alerts[0].budget_id : null
}

output "budget_amount" {
  description = "Budget amount in USD"
  value       = length(module.budget_alerts) > 0 ? module.budget_alerts[0].budget_amount : null
}

output "budget_alert_count" {
  description = "Number of budget alert rules"
  value       = length(module.budget_alerts) > 0 ? module.budget_alerts[0].alert_count : 0
}

output "budget_summary" {
  description = "Budget alert summary"
  value       = length(module.budget_alerts) > 0 ? module.budget_alerts[0].summary : "Budget alerts disabled (set alert_email to enable)"
}

# =============================================================================
# Boot Volume Backup Outputs
# =============================================================================

output "boot_backup_policy" {
  description = "Boot volume backup policy name"
  value       = data.oci_core_volume_backup_policies.oracle.volume_backup_policies[0].display_name
}
