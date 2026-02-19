# Outputs for OCI Budget Alerts Module

output "budget_id" {
  description = "OCID of the budget"
  value       = oci_budget_budget.free_tier.id
}

output "budget_amount" {
  description = "Budget amount in USD"
  value       = oci_budget_budget.free_tier.amount
}

output "alert_rules" {
  description = "List of alert rule IDs"
  value = compact([
    oci_budget_alert_rule.warning_50.id,
    oci_budget_alert_rule.warning_80.id,
    oci_budget_alert_rule.exceeded_100.id,
    try(oci_budget_alert_rule.any_spend[0].id, null)
  ])
}

output "alert_count" {
  description = "Number of alert rules created"
  value       = var.budget_amount <= 1 ? 4 : 3
}

output "summary" {
  description = "Human-readable summary"
  value       = <<-EOT
    Budget: ${oci_budget_budget.free_tier.display_name}
    Amount: $${oci_budget_budget.free_tier.amount}/month
    Alerts: ${var.alert_email}
    Thresholds: 50% (forecast), 80% (actual), 100% (exceeded)${var.budget_amount <= 1 ? ", any charges" : ""}
  EOT
}
