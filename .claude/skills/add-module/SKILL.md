---
name: add-module
description: Scaffold a new OCI Terraform module following project conventions
allowed-tools: Read, Write, Edit, Grep, Glob
argument-hint: "<module-name>"
---

## Scaffold a New Module

Create a new Terraform module under `terraform/modules/oci-$ARGUMENTS/` following the conventions of this project.

### Project conventions

1. Read an existing module (e.g., `terraform/modules/oci-storage/`) to match the structure
2. Every module has exactly three files: `main.tf`, `variables.tf`, `outputs.tf`
3. Module header comment in `main.tf` includes: description, what it provisions, usage example
4. All modules declare their own `required_providers` block (`oracle/oci >= 5.0`)
5. `compartment_id` variable with OCID validation: `can(regex("^ocid1\\.(compartment|tenancy)\\.oc", ...))`
6. All resources get `freeform_tags = var.tags` with a `tags` variable (default `{}`)
7. Use `=====` section separators between resource groups
8. Variables have `description`, `type`, `default` (where appropriate), and `validation` blocks
9. Outputs include both IDs and human-readable summaries

### Steps

1. Validate the module name is provided
2. Create `terraform/modules/oci-$0/main.tf` with provider block, header comment, and placeholder resources
3. Create `terraform/modules/oci-$0/variables.tf` with `compartment_id` and `tags`
4. Create `terraform/modules/oci-$0/outputs.tf` with placeholder outputs
5. Tell the user to wire the module in `terraform/environments/oci-prod/main.tf`
6. Format with `terraform fmt terraform/modules/oci-$0/`
