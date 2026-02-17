---
name: deploy
description: Deploy or update OCI infrastructure — runs plan and apply
disable-model-invocation: true
allowed-tools: Bash, Read, Grep, Glob
argument-hint: "[plan|apply|destroy]"
---

## Deploy OCI Infrastructure

Run the Terraform/OpenTofu workflow for `terraform/environments/oci-prod/`.

**Arguments:**
- No argument or `apply`: run `plan` then `apply` (with user confirmation)
- `plan`: preview changes only
- `destroy`: tear down infrastructure (requires confirmation)

### Steps

1. Check that `terraform/environments/oci-prod/oci-prod.auto.tfvars` exists. If not, tell the user to run `just setup` or copy the example file first.
2. Check that `TF_VAR_mysql_admin_password` is set in the environment. Warn if missing.
3. Run `terraform -chdir=terraform/environments/oci-prod init -input=false` if `.terraform/` doesn't exist.
4. If `$ARGUMENTS` is `plan` or empty:
   - Run `terraform -chdir=terraform/environments/oci-prod plan`
   - Show the user a summary of what will be created/changed/destroyed
5. If `$ARGUMENTS` is `apply` or empty:
   - Ask the user to confirm before applying
   - Run `terraform -chdir=terraform/environments/oci-prod apply`
   - Show the summary output after apply completes
6. If `$ARGUMENTS` is `destroy`:
   - Warn about `prevent_destroy` on MySQL and object storage
   - Ask the user to confirm
   - Run `terraform -chdir=terraform/environments/oci-prod destroy`

Use `terraform` (not `tofu`) since that's what's available on this system via mise.
