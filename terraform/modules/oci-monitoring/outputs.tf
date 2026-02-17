# Outputs for OCI Monitoring Module

output "notification_topic_id" {
  description = "OCID of the monitoring notification topic"
  value       = oci_ons_notification_topic.monitoring.id
}

output "alarm_ids" {
  description = "OCIDs of all monitoring alarms"
  value = compact(concat(
    [for a in oci_monitoring_alarm.cpu_idle : a.id],
    [for a in oci_monitoring_alarm.memory_idle : a.id],
    [for a in oci_monitoring_alarm.network_idle : a.id],
    [for a in oci_monitoring_alarm.cpu_high : a.id],
    [for a in oci_monitoring_alarm.memory_high : a.id],
  ))
}

output "alarm_count" {
  description = "Number of monitoring alarms created"
  value = (
    (var.enable_idle_alerts ? 3 : 0) +
    (var.enable_high_utilization_alerts ? 2 : 0)
  )
}

output "summary" {
  description = "Human-readable monitoring summary"
  value       = <<-EOT
    Monitoring: ${var.notification_topic_name}
    ─────────────────────────────────────
    Notification:  ${var.alert_email} (confirm subscription in email)
    Idle alerts:   ${var.enable_idle_alerts ? "enabled (CPU < ${var.cpu_idle_threshold}%, Memory < ${var.memory_idle_threshold}%, Network near-zero)" : "disabled"}
    High alerts:   ${var.enable_high_utilization_alerts ? "enabled (CPU > ${var.cpu_high_threshold}%, Memory > ${var.memory_high_threshold}%)" : "disabled"}
    Total alarms:  ${(var.enable_idle_alerts ? 3 : 0) + (var.enable_high_utilization_alerts ? 2 : 0)}

    Reclaim thresholds (Oracle's 7-day window):
      CPU:     95th percentile < 20%
      Memory:  average < 20% (A1 shapes only)
      Network: < 20% utilization
  EOT
}
