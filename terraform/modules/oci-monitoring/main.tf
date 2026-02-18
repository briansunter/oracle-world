# OCI Monitoring Module — Free Tier Utilization Alerts
#
# Creates monitoring alarms to prevent Oracle from reclaiming idle Always Free
# instances and optionally alerts on high utilization.
#
# Oracle reclaims Always Free compute instances deemed "idle" when ALL of these
# hold over a rolling 7-day window:
#   - CPU utilization (95th percentile) < 20%
#   - Network utilization < 20%
#   - Memory utilization < 20% (A1 shapes only)
#
# This module creates alarms that fire when individual metrics drop below the
# reclaim thresholds, giving you time to generate load before Oracle acts.
#
# Resources created:
#   - 1 ONS notification topic + email subscription
#   - 3 idle-detection alarms (CPU, memory, network) when enable_idle_alerts = true
#   - 2 high-utilization alarms (CPU, memory) when enable_high_utilization_alerts = true
#
# Usage:
#   module "monitoring" {
#     source = "../../modules/oci-monitoring"
#
#     compartment_id = var.compartment_ocid
#     instance_id    = module.compute.instance_id
#     alert_email    = var.alert_email
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
# Notification Topic & Subscription
# =============================================================================

resource "oci_ons_notification_topic" "monitoring" {
  compartment_id = var.compartment_id
  name           = var.notification_topic_name
  description    = "Monitoring alerts for Always Free tier instance utilization"

  freeform_tags = var.tags
}

resource "oci_ons_subscription" "email" {
  compartment_id = var.compartment_id
  topic_id       = oci_ons_notification_topic.monitoring.id
  protocol       = "EMAIL"
  endpoint       = var.alert_email

  freeform_tags = var.tags
}

# =============================================================================
# Idle Detection Alarms (Reclaim Prevention)
# =============================================================================
# These fire when utilization is LOW — meaning Oracle may flag the instance as
# idle and eventually reclaim it.
#
# The MQL query window is 1 day ([1d]) — the OCI maximum interval.
# Combined with a 1-hour pending_duration, this means the alarm fires when
# the metric stays below the threshold across the latest 24-hour window.
# Repeat notifications every 6 hours re-alert while still idle, giving you
# ongoing warnings well before Oracle's 7-day reclaim deadline.

# CPU idle: fires when 1-day 95th-percentile CPU stays below threshold.
# Matches Oracle's own 95th-percentile evaluation method.
resource "oci_monitoring_alarm" "cpu_idle" {
  count = var.enable_idle_alerts ? 1 : 0

  compartment_id        = var.compartment_id
  display_name          = "cpu-idle-reclaim-risk"
  is_enabled            = true
  metric_compartment_id = var.compartment_id
  namespace             = "oci_computeagent"
  severity              = "WARNING"

  query = "CpuUtilization[1d]{resourceId = \"${var.instance_id}\"}.percentile(0.95) < ${var.cpu_idle_threshold}"

  pending_duration             = "PT1H"
  repeat_notification_duration = "PT6H"
  message_format               = "ONS_OPTIMIZED"
  destinations                 = [oci_ons_notification_topic.monitoring.id]

  body = join("", [
    "CPU utilization (95th percentile) has been below ${var.cpu_idle_threshold}% for the past 24 hours. ",
    "Oracle reclaims Always Free instances after 7 days of idle — act soon. ",
    "Generate some load or schedule a cron job to avoid reclamation.",
  ])

  freeform_tags = var.tags
}

# Memory idle: fires when 1-day average memory stays below threshold.
# Only relevant for A1 (ARM) shapes — Oracle checks memory for A1 instances.
resource "oci_monitoring_alarm" "memory_idle" {
  count = var.enable_idle_alerts ? 1 : 0

  compartment_id        = var.compartment_id
  display_name          = "memory-idle-reclaim-risk"
  is_enabled            = true
  metric_compartment_id = var.compartment_id
  namespace             = "oci_computeagent"
  severity              = "WARNING"

  query = "MemoryUtilization[1d]{resourceId = \"${var.instance_id}\"}.mean() < ${var.memory_idle_threshold}"

  pending_duration             = "PT1H"
  repeat_notification_duration = "PT6H"
  message_format               = "ONS_OPTIMIZED"
  destinations                 = [oci_ons_notification_topic.monitoring.id]

  body = join("", [
    "Memory utilization has been below ${var.memory_idle_threshold}% for the past 24 hours. ",
    "Oracle reclaims Always Free A1 instances after 7 days of idle — act soon. ",
    "Run memory-consuming workloads or allocate buffers to avoid reclamation.",
  ])

  freeform_tags = var.tags
}

# Network idle: fires when 1-day average inbound bytes are near zero.
# Oracle checks "network utilization < 20%" but the metric is raw bytes, not a
# percentage. A near-zero byte count is a strong proxy for idle networking.
# Threshold: < 1 KB average inbound over 1 day (~0 real traffic).
resource "oci_monitoring_alarm" "network_idle" {
  count = var.enable_idle_alerts ? 1 : 0

  compartment_id        = var.compartment_id
  display_name          = "network-idle-reclaim-risk"
  is_enabled            = true
  metric_compartment_id = var.compartment_id
  namespace             = "oci_computeagent"
  severity              = "WARNING"

  query = "NetworksBytesIn[1d]{resourceId = \"${var.instance_id}\"}.mean() < 1024"

  pending_duration             = "PT1H"
  repeat_notification_duration = "PT6H"
  message_format               = "ONS_OPTIMIZED"
  destinations                 = [oci_ons_notification_topic.monitoring.id]

  body = join("", [
    "Inbound network traffic has been near zero for the past 24 hours. ",
    "Oracle reclaims Always Free instances after 7 days of idle — act soon. ",
    "Ensure the instance is receiving traffic or schedule periodic health checks.",
  ])

  freeform_tags = var.tags
}

# =============================================================================
# High Utilization Alarms (Optional)
# =============================================================================
# These fire when utilization is HIGH — useful for capacity planning on the
# fixed-size Always Free instance. 15-minute pending avoids transient spikes.

resource "oci_monitoring_alarm" "cpu_high" {
  count = var.enable_high_utilization_alerts ? 1 : 0

  compartment_id        = var.compartment_id
  display_name          = "cpu-high-utilization"
  is_enabled            = true
  metric_compartment_id = var.compartment_id
  namespace             = "oci_computeagent"
  severity              = "WARNING"

  query = "CpuUtilization[5m]{resourceId = \"${var.instance_id}\"}.mean() > ${var.cpu_high_threshold}"

  pending_duration             = "PT15M"
  repeat_notification_duration = "PT1H"
  message_format               = "ONS_OPTIMIZED"
  destinations                 = [oci_ons_notification_topic.monitoring.id]

  body = "CPU utilization has exceeded ${var.cpu_high_threshold}% for 15+ minutes. The Always Free A1 instance has ${4} OCPUs — consider optimizing workloads."

  freeform_tags = var.tags
}

resource "oci_monitoring_alarm" "memory_high" {
  count = var.enable_high_utilization_alerts ? 1 : 0

  compartment_id        = var.compartment_id
  display_name          = "memory-high-utilization"
  is_enabled            = true
  metric_compartment_id = var.compartment_id
  namespace             = "oci_computeagent"
  severity              = "WARNING"

  query = "MemoryUtilization[5m]{resourceId = \"${var.instance_id}\"}.mean() > ${var.memory_high_threshold}"

  pending_duration             = "PT15M"
  repeat_notification_duration = "PT1H"
  message_format               = "ONS_OPTIMIZED"
  destinations                 = [oci_ons_notification_topic.monitoring.id]

  body = "Memory utilization has exceeded ${var.memory_high_threshold}% for 15+ minutes. The Always Free A1 instance has 24 GB — consider optimizing workloads."

  freeform_tags = var.tags
}
