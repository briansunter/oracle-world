# Outputs for oci-object-storage module

# =============================================================================
# Bucket Information
# =============================================================================

output "bucket_id" {
  description = "OCID of the bucket"
  value       = oci_objectstorage_bucket.main.bucket_id
}

output "bucket_name" {
  description = "Name of the bucket"
  value       = oci_objectstorage_bucket.main.name
}

output "namespace" {
  description = "Object Storage namespace"
  value       = data.oci_objectstorage_namespace.ns.namespace
}

output "storage_tier" {
  description = "Storage tier of the bucket"
  value       = oci_objectstorage_bucket.main.storage_tier
}

output "versioning" {
  description = "Versioning status"
  value       = oci_objectstorage_bucket.main.versioning
}

output "etag" {
  description = "Entity tag for the bucket"
  value       = oci_objectstorage_bucket.main.etag
}

output "created_by" {
  description = "User who created the bucket"
  value       = oci_objectstorage_bucket.main.created_by
}

output "time_created" {
  description = "Bucket creation time"
  value       = oci_objectstorage_bucket.main.time_created
}

# =============================================================================
# S3 Compatibility Endpoints
# =============================================================================

output "region" {
  description = "OCI region for this bucket"
  value       = local.region
}

output "s3_endpoint" {
  description = "S3-compatible endpoint for this bucket"
  value       = "https://${data.oci_objectstorage_namespace.ns.namespace}.compat.objectstorage.${local.region}.oraclecloud.com"
}

output "swift_endpoint" {
  description = "Swift-compatible endpoint for this bucket"
  value       = "https://swiftobjectstorage.${local.region}.oraclecloud.com/v1/${data.oci_objectstorage_namespace.ns.namespace}"
}

output "oci_cli_upload" {
  description = "OCI CLI command to upload a file"
  value       = "oci os object put -ns ${data.oci_objectstorage_namespace.ns.namespace} -bn ${oci_objectstorage_bucket.main.name} --file <local-file>"
}

output "oci_cli_download" {
  description = "OCI CLI command to download a file"
  value       = "oci os object get -ns ${data.oci_objectstorage_namespace.ns.namespace} -bn ${oci_objectstorage_bucket.main.name} --name <object-name> --file <local-file>"
}

output "oci_cli_list" {
  description = "OCI CLI command to list objects"
  value       = "oci os object list -ns ${data.oci_objectstorage_namespace.ns.namespace} -bn ${oci_objectstorage_bucket.main.name}"
}

# =============================================================================
# Pre-Authenticated Request (if created)
# =============================================================================

output "par_id" {
  description = "OCID of the pre-authenticated request"
  value       = var.create_par ? oci_objectstorage_preauthrequest.main[0].id : null
}

output "par_access_uri" {
  description = "Full access URI for the pre-authenticated request"
  value       = var.create_par ? oci_objectstorage_preauthrequest.main[0].access_uri : null
  sensitive   = true
}

output "par_full_url" {
  description = "Complete URL for PAR access"
  value       = var.create_par ? "https://objectstorage.${local.region}.oraclecloud.com${oci_objectstorage_preauthrequest.main[0].access_uri}" : null
  sensitive   = true
}

output "par_expiry" {
  description = "PAR expiration time"
  value       = var.create_par ? oci_objectstorage_preauthrequest.main[0].time_expires : null
}

# =============================================================================
# Summary
# =============================================================================

output "summary" {
  description = "Human-readable summary of the Object Storage bucket"
  value       = <<-EOT
    Object Storage Bucket: ${oci_objectstorage_bucket.main.name}
    Namespace: ${data.oci_objectstorage_namespace.ns.namespace}
    Storage Tier: ${oci_objectstorage_bucket.main.storage_tier}
    Versioning: ${oci_objectstorage_bucket.main.versioning}
    Auto-tiering: ${oci_objectstorage_bucket.main.auto_tiering}
    Public Access: ${oci_objectstorage_bucket.main.access_type == "ObjectRead" ? "Yes" : "No"}

    Always Free Limits (Pay As You Go):
    - 10 GB Standard + 10 GB InfrequentAccess + 10 GB Archive = 30 GB
    - 50,000 API requests/month
  EOT
}
