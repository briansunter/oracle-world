# OCI Object Storage Module
# Creates Object Storage buckets for the Always Free tier
#
# Always Free Object Storage limits (Pay As You Go account):
#   - 10 GB Standard + 10 GB InfrequentAccess + 10 GB Archive = 30 GB total
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

# Get region info from identity
data "oci_identity_region_subscriptions" "regions" {
  tenancy_id = var.compartment_id
}

locals {
  # Use provided region or get from tenancy's home region
  region = var.region != "" ? var.region : (
    length(data.oci_identity_region_subscriptions.regions.region_subscriptions) > 0
    ? data.oci_identity_region_subscriptions.regions.region_subscriptions[0].region_name
    : "unknown"
  )
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

  # Prevent accidental deletion - remove this block to destroy
  lifecycle {
    prevent_destroy = true
  }
}

# =============================================================================
# Lifecycle Policy (Optional)
# =============================================================================

# Move objects to InfrequentAccess tier after specified days
resource "oci_objectstorage_object_lifecycle_policy" "main" {
  count = var.enable_lifecycle_policy ? 1 : 0

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

      # Apply to all objects or specific prefix
      object_name_filter {
        inclusion_prefixes = var.lifecycle_prefix != "" ? [var.lifecycle_prefix] : []
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
        inclusion_prefixes = var.lifecycle_prefix != "" ? [var.lifecycle_prefix] : []
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
        inclusion_prefixes = var.lifecycle_prefix != "" ? [var.lifecycle_prefix] : []
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
