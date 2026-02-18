---
name: setup
description: Interactive setup wizard — walks through OCI configuration with guided questions
allowed-tools: Bash, Read, Write, Edit, Grep, Glob, AskUserQuestion
---

## Interactive OCI Setup Wizard

Walk the user through configuring the OCI Always Free tier infrastructure step by step. Ask questions using `AskUserQuestion` to guide choices, then generate `.env` (secrets) and `oci-prod.auto.tfvars` (config).

### Steps

#### Phase 0: OCI Account Check

Before checking local tools, ask the user if they already have an Oracle Cloud account:

- **If they don't have an account**, walk them through creating one:
  1. Direct them to sign up at https://cloud.oracle.com/free
  2. Explain they'll need: a valid email, a debit/credit card (verification only — no charges)
  3. **Important**: Tell them to choose their **Home Region** carefully — Always Free resources are only available in the home region and it **cannot be changed later**. Suggest picking the region closest to them or their users.
  4. Walk them through the sign-up form:
     - Enter name, email, country
     - Verify email (check inbox for verification link)
     - Set password and choose home region
     - Enter address and phone number
     - Add payment method (verification hold only, auto-released)
     - Wait for account provisioning (can take a few minutes)
  5. After sign-up, **strongly recommend upgrading to Pay As You Go**:
     - Log into the OCI Console at https://cloud.oracle.com
     - Click the **hamburger menu** (top-left) > **Billing & Cost Management** > **Upgrade and Pay As You Go**
     - This is still free for Always Free resources but removes capacity restrictions that often prevent ARM instance creation on trial accounts
  6. Wait for the user to confirm their account is ready before proceeding.

- **If they already have an account**, ask if it's been upgraded to Pay As You Go. If not, recommend upgrading:
  - OCI Console > **hamburger menu** (top-left) > **Billing & Cost Management** > **Upgrade and Pay As You Go**
  - This avoids ARM capacity issues on trial accounts.

#### Phase 1: Prerequisites

1. Check that `oci` CLI is installed (`command -v oci`). If not, tell the user to install it:
   - macOS: `brew install oci-cli`
   - Linux: `bash -c "$(curl -L https://raw.githubusercontent.com/oracle/oci-cli/master/scripts/install/install.sh)"`
   - Then run `oci setup config` to create `~/.oci/config`
   - After `oci setup config` completes, remind them to upload the generated API public key (printed at the end of setup, usually at `~/.oci/oci_api_key_public.pem`) to their OCI profile:
     1. Go to the OCI Console at https://cloud.oracle.com
     2. Click the **person icon** (top-right) > **My profile**
     3. Scroll down to **Resources** > **API keys** (left sidebar)
     4. Click **Add API key** > **Paste a public key**
     5. Paste the contents of the public key file (the path is shown at the end of `oci setup config`)
     6. Click **Add**
     7. The console will show a config file preview — confirm it matches `~/.oci/config`

2. Check that `~/.oci/config` exists. If not, tell the user to run `oci setup config` and upload the generated public key to their OCI profile under **Identity > Users > API Keys**.

3. Check that `tofu` or `terraform` is installed (`command -v tofu || command -v terraform`). If not, suggest `brew install opentofu`.

4. Check for an SSH public key in `~/.ssh/` (look for `id_ed25519.pub`, `id_rsa.pub`, `id_ecdsa.pub`). If none found, tell the user to generate one with `ssh-keygen -t ed25519` and wait for them to do so.

If any prerequisite is missing, stop and help the user fix it before continuing. Do not proceed with partial prerequisites.

#### Phase 2: OCI Config Discovery

1. Parse `~/.oci/config` for the `[DEFAULT]` profile to extract `tenancy`, `user`, and `region`. Show these to the user and confirm they look correct.

2. Query the availability domain:
   ```
   oci iam availability-domain list --query 'data[0].name' --raw-output
   ```
   If this fails, the OCI CLI config is likely broken — help the user debug.

3. Read the SSH public key file content.

4. Show the user a summary of discovered values:
   - Compartment (tenancy OCID)
   - User OCID
   - Region
   - Availability domain
   - SSH key file

#### Phase 3: Configuration Questions

Ask the user the following questions using `AskUserQuestion`. Group related questions together where possible (up to 4 per call).

**Question group 1 — Access mode and email:**

- **Alert email**: Ask for their email address for budget and monitoring alerts. This is optional — if provided, budget alerts are automatically created and monitoring alerts can be enabled. If left blank, no alerts are configured.

- **Public or private mode**: Ask whether the instance should be publicly accessible.
  - **Public (default)**: Opens port 443 on the instance. Best for web apps, APIs, VPN endpoints.
  - **Private**: No inbound ports. SSH-only access. Best for dev boxes, background workers, SSH-only use.

**Question group 2 — Optional modules and storage:**

- **MySQL**: Ask whether to enable MySQL HeatWave.
  - **Disable (default)**: No MySQL, no private subnet. Leaner deployment.
  - **Enable**: Creates a private subnet + Always Free MySQL HeatWave (50 GB). Access via SSH tunnel from the instance.

- **Object Storage**: Ask whether to enable S3-compatible Object Storage.
  - **Disable (default)**: No bucket or S3 credentials created. Simpler deployment.
  - **Enable**: Creates an S3-compatible bucket (up to 30 GB free on paid accounts: 10 GB per tier). Useful for backups, media, logs, or remote Terraform state.

- **Storage layout**: Ask how they want to split their 200 GB free storage.
  - **50 GB boot + 150 GB block (default)**: Separate data volume at `/data`. Data survives instance recreation.
  - **200 GB boot, no block volume**: Simpler setup, all storage on root. No separate mount needed.

**Question group 3 — Monitoring (only if alert email was provided):**

Skip this group if no alert email was provided — monitoring requires an email.

- **Idle detection alerts**: Ask whether to enable reclaim-prevention alerts. Explain that Oracle reclaims Always Free instances that are idle for 7 days (CPU < 20%, memory < 20%, network < 20%). These alarms warn after ~4 days of low utilization.
  - **Enable (recommended)**: Get email warnings before Oracle reclaims the instance.
  - **Disable**: No idle alerts. Suitable if you're confident the instance will stay busy.

- **High utilization alerts**: Ask whether to enable alerts when CPU or memory exceed 90%.
  - **Enable**: Useful for capacity planning on the fixed-size instance.
  - **Disable (default)**: Skip high-utilization monitoring.

**Question group 4 — Ports (only if public mode was selected):**

- **TCP ports**: Ask which TCP ports to open. Provide options:
  - **80 and 443 (default)**: HTTP + HTTPS (for web servers with redirect).
  - **443 only**: HTTPS only.
  - **Custom**: Let the user specify a comma-separated list.

- **UDP ports**: Ask if they need any UDP ports open.
  - **None (default)**: No UDP ports.
  - **51820 (WireGuard)**: For VPN use.
  - **Custom**: Let the user specify.

**Question group 5 — SSH access:**

- **SSH access**: Ask whether to whitelist their current IP for SSH access.
  - **Yes, allow SSH from my current IP (recommended)**: Detect their public IPv4 using `curl -4 -s https://ifconfig.me` and set `ssh_source_cidr` to `<ip>/32` in the tfvars. This opens port 22 from that single IP only.
  - **No, keep SSH closed**: Leave `ssh_source_cidr` empty. They can open it later with `just ssh-allow`.

**Question group 6 — Remote state backend:**

Ask about remote state backend upfront so the full plan is known before generating any files. This is important because:
- Users should decide on their state backend BEFORE their first `apply`
- If they choose OCI Object Storage, the setup flow needs to create the bucket and configure S3 credentials before init
- Asking late (after init/plan) can lead to state being created locally first, then needing migration

Present options:
- **OCI Object Storage (Recommended)**: Uses your existing OCI account with S3-compatible API. Free tier impact is negligible (~10-50 KB state files). Note: the native `backend "oci"` exists in Terraform 1.12+ but is not yet available in OpenTofu, so we use the S3-compatible API instead.
- **HCP Terraform / Terraform Cloud**: Free up to 500 managed resources. Includes locking, versioning, run history, and a web UI.
- **Skip for now**: Keep local state. Can migrate later.

Store the user's choice — it will be executed in Phase 6 (after .env and tfvars are generated but before init/plan).

**Question group 7 — Object storage details (only if object storage was enabled):**

Skip this group if object storage was not enabled.

- **Auto-tiering**: Ask whether to enable automatic tiering.
  - **Enable (recommended)**: Untouched objects automatically move to InfrequentAccess tier after 30 days, and back when accessed again. On paid accounts each tier has its own 10 GB free allowance, so auto-tiering effectively gives you more free storage.
  - **Disable**: Everything stays in Standard tier. Use this if all data is frequently accessed.

- **Archive lifecycle**: Ask if they want old objects automatically moved to Archive tier.
  - **Disable (default)**: No archiving. Objects stay in Standard/InfrequentAccess.
  - **Enable**: Moves objects to Archive after N days (ask for number, default 180). Cheapest tier but: 90-day minimum retention, ~1 hour to restore. Good for data you must keep but rarely read.

#### Phase 4: Generate .env (Secrets)

Run `./generate-env.sh` to create `.env` with random secrets. The script generates all secrets internally — Claude never sees the values.

1. Check if `.env` already exists by running `test -f .env && echo exists || echo missing`.

2. **If `.env` already exists — check for existing Terraform state before offering regeneration:**
   ```bash
   test -f terraform/environments/oci-prod/terraform.tfstate && echo "STATE_EXISTS" || echo "NO_STATE"
   ls terraform/environments/oci-prod/.terraform/ 2>/dev/null && echo "INIT_EXISTS" || echo "NO_INIT"
   ```

   - **If state exists (local or initialized)**: **Default to keeping the existing `.env`.** Warn the user:
     > "Your `.env` already exists and you have existing Terraform state encrypted with its passphrase. **Regenerating `.env` would create a new passphrase, making your existing state unreadable.** I'll keep your current `.env`."
   - Only offer regeneration if the user explicitly asks, and warn them it will require destroying or migrating existing state first.
   - If MySQL is being newly enabled and `.env` may lack `TF_VAR_mysql_admin_password`, tell the user to add it manually:
     > "You're enabling MySQL but your existing `.env` may not have a MySQL password. Add one manually: `echo 'TF_VAR_mysql_admin_password="'$(openssl rand -base64 24)'"' >> .env`"

   - **If no state exists**: Safe to regenerate. Ask if they want to regenerate (this backs up the old one first). If yes, run with `--force`. If no, skip to Phase 5.

3. **If `.env` does not exist** (fresh setup): Run the script via Bash with the appropriate flags:
   ```bash
   ./generate-env.sh --mysql              # first time, MySQL enabled
   ./generate-env.sh --no-mysql           # first time, MySQL disabled
   ```
   The `--mysql` / `--no-mysql` flag is determined by whether MySQL was enabled in Phase 3.

4. **CRITICAL: Never read, cat, source, or inspect `.env` contents.** A hook blocks this — the secrets must never appear in the conversation.

5. Tell the user: "Your `.env` file has been generated with random secrets. **Back it up** — losing the passphrase means losing access to your Terraform state. The file is gitignored and loaded automatically by `just` recipes."

#### Phase 5: Generate Configuration

1. Check if `terraform/environments/oci-prod/oci-prod.auto.tfvars` already exists. If so, ask whether to overwrite or abort.

2. Generate `oci-prod.auto.tfvars` with the collected values. Only include non-default values to keep the file clean. Always include:
   - `compartment_ocid`
   - `user_ocid`
   - `availability_domain`
   - `ssh_public_key`

   Conditionally include (only when different from defaults):
   - `alert_email` (only if provided)
   - `enable_public_access` (only if `false`)
   - `additional_tcp_ports` (only if not `[80, 443]`)
   - `additional_udp_ports` (only if not empty)
   - `ssh_source_cidr` (only if user chose to whitelist their IP)
   - `enable_mysql` (only if `true`)
   - `enable_object_storage` (only if `true`)
   - `object_storage_auto_tiering` (only if `false` and object storage enabled)
   - `enable_block_volume` (only if `false`)
   - `boot_volume_size_gb` (only if not `50`)
   - `enable_idle_alerts` (only if `true`)
   - `enable_high_utilization_alerts` (only if `true`)
   - `object_storage_archive_enabled` (only if `true` and object storage enabled)
   - `object_storage_archive_days` (only if archive enabled)

   Use the same format as `oci-prod.auto.tfvars.example` with section headers and comments explaining each value.

3. Write the file using the Write tool.

#### Phase 6: Remote State Backend Setup

Execute the remote state backend choice from Phase 3, Question group 6. This must happen BEFORE `init` so state goes directly to the remote backend on first run.

**If the user chose OCI Object Storage:**

This requires an S3-compatible bucket and Customer Secret Key credentials. Run the CLI commands directly — don't just show them.

1. Create the state bucket (must exist before backend config). Run via Bash:
   ```bash
   oci os bucket create --name terraform-state --compartment-id <compartment_ocid>
   ```
   If the bucket already exists, `oci os bucket get --name terraform-state` will confirm it.

2. Get the namespace (needed for the S3 endpoint URL). Run via Bash:
   ```bash
   oci os ns get --query 'data' --raw-output
   ```
   Store the namespace value — it's needed for the backend endpoint URL.

3. The user must create S3 credentials manually in the OCI Console (these can't be created via CLI):
   1. Go to OCI Console → **Identity & Security** → **Users** → click their user
   2. Scroll to **Resources** → **Customer Secret Keys** (left sidebar)
   3. Click **Generate Secret Key**, give it a name like "terraform-state"
   4. **Copy the secret key immediately** — it's only shown once
   5. The access key ID is shown in the list after creation
   6. Tell the user to add the values to `.env` themselves:
      ```bash
      echo 'AWS_ACCESS_KEY_ID="<their_access_key>"' >> .env
      echo 'AWS_SECRET_ACCESS_KEY="<their_secret_key>"' >> .env
      ```
      **Do NOT read `.env` after writing.** The user pastes their own values.
   7. Wait for the user to confirm they've added the credentials before proceeding.

4. Update the backend block in `main.tf` using the Edit tool. Uncomment and fill in the existing S3 backend block with the discovered namespace and region:
   ```hcl
   backend "s3" {
     bucket                      = "terraform-state"
     key                         = "oci-prod/terraform.tfstate"
     region                      = "<region>"
     endpoints                   = { s3 = "https://<namespace>.compat.objectstorage.<region>.oraclecloud.com" }
     skip_region_validation      = true
     skip_credentials_validation = true
     skip_requesting_account_id  = true
     skip_metadata_api_check     = true
     use_path_style              = true
   }
   ```

5. Proceed to Phase 7 — `just init` will configure the remote backend and send state directly there.

**If the user chose HCP Terraform:**

1. Direct them to sign up at https://app.terraform.io
2. Run `tofu login`
3. Update `main.tf` with a `cloud {}` block (use Edit tool):
   ```hcl
   cloud {
     organization = "<their-org>"
     workspaces {
       name = "oci-prod"
     }
   }
   ```
4. Proceed to Phase 7 — `just init` will configure the backend.

**If the user chose "Skip for now":** Proceed directly to Phase 7.

#### Phase 7: Initialize and Plan

Run init and plan so the user can see what will be created:

1. Run `just init` via Bash. If it fails, help the user debug (common issues: missing OCI config, bad credentials, network errors). If a remote backend was configured in Phase 6, init will set it up now.

2. Run `just plan` via Bash. Show the user a summary of what will be created/changed/destroyed.

#### Phase 8: Deploy

After init and plan succeed, deploy the infrastructure:

1. Ask the user if they'd like to proceed with `just apply-auto` to deploy now, or do it later.
   - If yes, run `just apply-auto` via Bash. Show the summary output after apply completes.
   - If no, tell them they can run `just apply` later when ready.

2. If the user deployed with `enable_object_storage = true` AND chose OCI Object Storage for remote state in Phase 6, run `just s3-creds-to-env` via Bash after apply completes. This extracts the Terraform-managed S3 credentials and writes them to `.env` — **Claude never sees the credential values**. This is a convenience step: the user already created manual S3 credentials in Phase 6 for the state backend, but this captures the Terraform-managed credentials too (which may be useful for other S3 operations).

#### Phase 9: Post-Deploy Tips

Show the user what to do after deployment:

1. Connect to the instance:
   - If SSH was whitelisted during setup: `just ssh` to connect directly
   - If SSH was not whitelisted: `just ssh-allow` first to open SSH from their current IP, then `just ssh`
   - To revoke SSH access later: `just ssh-revoke`
   - If block volume enabled: it's automatically formatted and mounted at `/data` on first boot via cloud-init

2. If MySQL enabled: `just mysql-tunnel` for MySQL access

4. Remind them to back up `.env` — losing the passphrase means losing access to Terraform state.

### Notes

- Use `tofu` for all commands (not `terraform`) per project convention.
- Secrets (`TF_VAR_state_passphrase`, `TF_VAR_mysql_admin_password`) go in `.env` — never in `.auto.tfvars` or committed files. The `.env` file is gitignored and loaded automatically by `just` via `set dotenv-load`.
- **Never read, cat, source, or inspect `.env` contents.** A `PreToolUse` hook (`.claude/hooks/protect-env.sh`) blocks access. All secret generation is handled by `./generate-env.sh` — Claude calls it but never sees the values.
- The generated tfvars should be clean and well-commented, matching the style of `oci-prod.auto.tfvars.example`.
- If the user's OCI account is a trial (not upgraded to Pay As You Go), warn them that ARM instances may fail to create due to capacity limits — recommend upgrading to PAYG (still free for Always Free resources).
