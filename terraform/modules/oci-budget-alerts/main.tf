# OCI Budget Alerts Module
# Creates budget with alert rules for free tier monitoring
#
# This module provisions:
#   - Monthly budget tracking
#   - Alert rules at 50%, 80%, and 100% thresholds
#   - Optional immediate alert on any charges (for $0 budget)
#
# Usage:
#   module "budget_alerts" {
#     source = "../../modules/oci-budget-alerts"
#
#     compartment_id = var.compartment_ocid
#     budget_name    = "free-tier-budget"
#     budget_amount  = 0
#     alert_email    = "alerts@example.com"
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
# Budget
# =============================================================================

# Note: OCI requires amount >= 1, so we use max(1, budget_amount)
# For free tier monitoring, set budget_amount = 1 and rely on the "any_spend" alert
resource "oci_budget_budget" "free_tier" {
  compartment_id = var.compartment_id
  amount         = max(1, var.budget_amount)
  reset_period   = "MONTHLY"
  display_name   = var.budget_name

  # Target the entire compartment
  target_type = "COMPARTMENT"
  targets     = [var.compartment_id]

  description = "Free tier budget - alerts on any charges"

  freeform_tags = var.tags
}

# =============================================================================
# Alert Rules
# =============================================================================

# Alert at 50% - Early warning (forecast-based)
resource "oci_budget_alert_rule" "warning_50" {
  budget_id      = oci_budget_budget.free_tier.id
  display_name   = "free-tier-warning-50pct"
  type           = "FORECAST" # Based on projected spend
  threshold      = 50
  threshold_type = "PERCENTAGE"
  recipients     = var.alert_email
  message        = "OCI spending is projected to reach 50% of budget. Review usage to stay within free tier."

  freeform_tags = var.tags
}

# Alert at 80% - Approaching limit
resource "oci_budget_alert_rule" "warning_80" {
  budget_id      = oci_budget_budget.free_tier.id
  display_name   = "free-tier-warning-80pct"
  type           = "ACTUAL" # Based on actual spend
  threshold      = 80
  threshold_type = "PERCENTAGE"
  recipients     = var.alert_email
  message        = "OCI spending has reached 80% of budget. Take action to avoid exceeding free tier."

  freeform_tags = var.tags
}

# Alert at 100% - Exceeded
resource "oci_budget_alert_rule" "exceeded_100" {
  budget_id      = oci_budget_budget.free_tier.id
  display_name   = "free-tier-exceeded-100pct"
  type           = "ACTUAL"
  threshold      = 100
  threshold_type = "PERCENTAGE"
  recipients     = var.alert_email
  message        = "WARNING: OCI spending has exceeded free tier budget! Review and reduce usage immediately."

  freeform_tags = var.tags
}

# Alert on ANY actual spend (for free tier monitoring)
# This triggers when any charges are detected
resource "oci_budget_alert_rule" "any_spend" {
  count          = var.budget_amount <= 1 ? 1 : 0
  budget_id      = oci_budget_budget.free_tier.id
  display_name   = "any-charges-detected"
  type           = "ACTUAL"
  threshold      = 0.01 # Minimum threshold - any charges
  threshold_type = "ABSOLUTE"
  recipients     = var.alert_email
  message        = "ALERT: Actual charges detected on OCI account. This indicates usage outside the free tier."

  freeform_tags = var.tags
}
