# Outputs for oci-mysql-heatwave module

# =============================================================================
# DB System Outputs
# =============================================================================

output "db_system_id" {
  description = "OCID of the MySQL DB system"
  value       = oci_mysql_mysql_db_system.main.id
}

output "db_system_state" {
  description = "Current state of the MySQL DB system"
  value       = oci_mysql_mysql_db_system.main.state
}

output "mysql_version" {
  description = "MySQL version running on the DB system"
  value       = oci_mysql_mysql_db_system.main.mysql_version
}

# =============================================================================
# Connection Outputs
# =============================================================================

output "ip_address" {
  description = "IP address of the MySQL DB system"
  value       = oci_mysql_mysql_db_system.main.ip_address
}

output "hostname" {
  description = "Hostname of the MySQL DB system"
  value       = oci_mysql_mysql_db_system.main.hostname_label
}

output "port" {
  description = "MySQL port"
  value       = oci_mysql_mysql_db_system.main.port
}

output "port_x" {
  description = "MySQL X Protocol port"
  value       = oci_mysql_mysql_db_system.main.port_x
}

output "connection_string" {
  description = "MySQL connection string"
  value       = "${oci_mysql_mysql_db_system.main.ip_address}:${oci_mysql_mysql_db_system.main.port}"
}

output "connection_command" {
  description = "MySQL CLI connection command"
  value       = "mysql -h ${oci_mysql_mysql_db_system.main.ip_address} -u ${var.admin_username} -p"
}

# =============================================================================
# Endpoints Output
# =============================================================================

output "endpoints" {
  description = "All endpoint information for the MySQL DB system"
  value = {
    ip_address = oci_mysql_mysql_db_system.main.ip_address
    hostname   = oci_mysql_mysql_db_system.main.hostname_label
    port       = oci_mysql_mysql_db_system.main.port
    port_x     = oci_mysql_mysql_db_system.main.port_x
  }
}

# =============================================================================
# HeatWave Cluster Outputs
# =============================================================================

output "heatwave_cluster_id" {
  description = "OCID of the HeatWave cluster (if enabled)"
  value       = var.enable_heatwave ? oci_mysql_heat_wave_cluster.main[0].id : null
}

output "heatwave_cluster_state" {
  description = "Current state of the HeatWave cluster (if enabled)"
  value       = var.enable_heatwave ? oci_mysql_heat_wave_cluster.main[0].state : null
}

output "heatwave_enabled" {
  description = "Whether HeatWave cluster is enabled"
  value       = var.enable_heatwave
}

# =============================================================================
# Summary Output
# =============================================================================

output "summary" {
  description = "Human-readable summary of the MySQL DB system"
  sensitive   = true
  value       = <<-EOT
    MySQL DB System: ${oci_mysql_mysql_db_system.main.display_name}
    Version: ${oci_mysql_mysql_db_system.main.mysql_version}
    State: ${oci_mysql_mysql_db_system.main.state}
    IP: ${oci_mysql_mysql_db_system.main.ip_address}
    Port: ${oci_mysql_mysql_db_system.main.port}
    HeatWave: ${var.enable_heatwave ? "Enabled" : "Disabled"}

    Connect with: mysql -h ${oci_mysql_mysql_db_system.main.ip_address} -u ${var.admin_username} -p
  EOT
}
