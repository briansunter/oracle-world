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
2. Check that `.env` exists (`test -f .env`). If missing, tell the user to run `./generate-env.sh`. **Do NOT read `.env` contents** — a hook blocks this.
3. Run `just init` if `terraform/environments/oci-prod/.terraform/` doesn't exist.
4. If `$ARGUMENTS` is `plan` or empty:
   - Run `just plan`
   - Show the user a summary of what will be created/changed/destroyed
5. If `$ARGUMENTS` is `apply` or empty:
   - Ask the user to confirm before applying
   - Run `just apply`
   - Show the summary output after apply completes
6. If `$ARGUMENTS` is `destroy`:
   - Warn about `prevent_destroy` on MySQL and object storage
   - Ask the user to confirm
   - Run `just destroy`

### Important

- Always use `just` recipes (not raw `tofu` commands) — `just` loads `.env` secrets automatically via `set dotenv-load`.
- Never run `source .env` — the hook blocks this. The `just` dotenv integration handles it transparently.
