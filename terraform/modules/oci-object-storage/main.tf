# OCI Object Storage Module
# Creates Object Storage buckets for the Always Free tier
#
# Always Free-only account limits:
#   - 20 GB combined across Standard, InfrequentAccess, and Archive tiers
#   - 50,000 API requests per month
#
# This module provisions:
#   - Namespace lookup (required for bucket creation)
#   - Object Storage bucket with configurable storage tier
#   - Optional versioning and lifecycle rules
#
# Storage Tiers:
#   - Standard: Frequently accessed data (default)
#   - InfrequentAccess: Data accessed less than once per month
#   - Archive: Rarely accessed data (minimum 90-day retention)
#
# Usage:
#   module "object_storage" {
#     source = "../../modules/oci-object-storage"
#
#     compartment_id = var.compartment_ocid
#     bucket_name    = "my-backup-bucket"
#     storage_tier   = "Standard"
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
# Data Sources
# =============================================================================

# Get the Object Storage namespace (required for bucket operations)
data "oci_objectstorage_namespace" "ns" {
  compartment_id = var.compartment_id
}

data "oci_identity_compartment" "target" {
  id = var.compartment_id
}

# =============================================================================
# Object Storage Bucket
# =============================================================================

resource "oci_objectstorage_bucket" "main" {
  compartment_id = var.compartment_id
  namespace      = data.oci_objectstorage_namespace.ns.namespace
  name           = var.bucket_name

  # Storage tier: Standard, InfrequentAccess, or Archive
  storage_tier = var.storage_tier

  # Access type: NoPublicAccess (default) or ObjectRead
  access_type = var.public_access ? "ObjectRead" : "NoPublicAccess"

  # Enable versioning for data protection
  versioning = var.enable_versioning ? "Enabled" : "Disabled"

  # Auto-tiering: automatically move objects between Standard and InfrequentAccess
  # based on access patterns (only valid for Standard tier buckets)
  # Valid values: "Disabled" or "InfrequentAccess"
  auto_tiering = var.storage_tier == "Standard" && var.enable_auto_tiering ? "InfrequentAccess" : "Disabled"

  # Object events for notifications (optional)
  object_events_enabled = var.enable_object_events

  # Metadata (optional)
  metadata = var.metadata

  freeform_tags = var.tags

  lifecycle {
    prevent_destroy = true
  }
}

# =============================================================================
# Lifecycle Policy (Optional)
# =============================================================================

locals {
  prefix_filter         = var.lifecycle_prefix != "" ? [var.lifecycle_prefix] : []
  lifecycle_enabled     = var.enable_lifecycle_policy && (var.infrequent_access_days > 0 || var.archive_days > 0 || var.delete_after_days > 0)
  policy_compartment_id = var.policy_compartment_id != "" ? var.policy_compartment_id : var.compartment_id
  policy_scope          = can(regex("^ocid1\\.tenancy\\.oc", var.compartment_id)) ? "tenancy" : "compartment ${data.oci_identity_compartment.target.name}"
}

# Move objects to InfrequentAccess tier after specified days
resource "oci_objectstorage_object_lifecycle_policy" "main" {
  count = local.lifecycle_enabled ? 1 : 0

  namespace = data.oci_objectstorage_namespace.ns.namespace
  bucket    = oci_objectstorage_bucket.main.name

  # Rule to transition objects to InfrequentAccess tier
  dynamic "rules" {
    for_each = var.infrequent_access_days > 0 ? [1] : []
    content {
      name        = "move-to-infrequent-access"
      action      = "INFREQUENT_ACCESS"
      is_enabled  = true
      time_amount = var.infrequent_access_days
      time_unit   = "DAYS"

      object_name_filter {
        inclusion_prefixes = local.prefix_filter
      }
    }
  }

  # Rule to transition objects to Archive tier
  dynamic "rules" {
    for_each = var.archive_days > 0 ? [1] : []
    content {
      name        = "move-to-archive"
      action      = "ARCHIVE"
      is_enabled  = true
      time_amount = var.archive_days
      time_unit   = "DAYS"

      object_name_filter {
        inclusion_prefixes = local.prefix_filter
      }
    }
  }

  # Rule to delete objects after specified days
  dynamic "rules" {
    for_each = var.delete_after_days > 0 ? [1] : []
    content {
      name        = "delete-old-objects"
      action      = "DELETE"
      is_enabled  = true
      time_amount = var.delete_after_days
      time_unit   = "DAYS"

      object_name_filter {
        inclusion_prefixes = local.prefix_filter
      }
    }
  }
}

# =============================================================================
# Pre-Authenticated Request (Optional - for S3 compatibility)
# =============================================================================

resource "oci_objectstorage_preauthrequest" "main" {
  count = var.create_par ? 1 : 0

  namespace    = data.oci_objectstorage_namespace.ns.namespace
  bucket       = oci_objectstorage_bucket.main.name
  name         = "${var.bucket_name}-par"
  access_type  = var.par_access_type
  time_expires = var.par_expiry

  # Bucket-level PAR (no object name)
  bucket_listing_action = var.par_access_type == "AnyObjectReadWrite" || var.par_access_type == "AnyObjectRead" ? "ListObjects" : null
}

# =============================================================================
# S3-Compatible Credentials (Customer Secret Key)
# =============================================================================

resource "oci_identity_customer_secret_key" "s3_access" {
  count = var.user_id != "" ? 1 : 0

  display_name = "${var.instance_name}-s3-access"
  user_id      = var.user_id
}

# =============================================================================
# IAM Policy for Object Storage Lifecycle
# Required for auto-archive lifecycle policies to work
# =============================================================================

resource "oci_identity_policy" "object_storage_lifecycle" {
  count          = local.lifecycle_enabled ? 1 : 0
  compartment_id = local.policy_compartment_id
  name           = "${var.bucket_name}-lifecycle-policy"
  description    = "Allow Object Storage service to manage objects for lifecycle policies"

  statements = [
    "Allow service objectstorage-${var.region} to manage object-family in ${local.policy_scope}"
  ]

  freeform_tags = var.tags
}
