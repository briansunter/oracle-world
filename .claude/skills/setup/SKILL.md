---
name: setup
description: Interactive setup wizard — walks through OCI configuration with guided questions
allowed-tools: Bash, Read, Write, Edit, Grep, Glob, AskUserQuestion
---

## Interactive OCI Setup Wizard

Walk the user through configuring the OCI Always Free tier infrastructure step by step. Ask questions using `AskUserQuestion` to guide choices, then generate `oci-prod.auto.tfvars`.

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
  - **Public (default)**: Creates a Network Load Balancer with a stable public IP, opens port 443. Best for web apps, APIs, VPN endpoints.
  - **Private**: No NLB, no inbound ports. SSH-only access. Best for dev boxes, background workers, SSH-only use.

**Question group 2 — Optional modules and storage:**

- **MySQL**: Ask whether to enable MySQL HeatWave.
  - **Disable (default)**: No MySQL, no private subnet. Leaner deployment.
  - **Enable**: Creates a private subnet + Always Free MySQL HeatWave (50 GB). Access via SSH tunnel from the instance.

- **Object Storage**: Ask whether to enable S3-compatible Object Storage.
  - **Disable (default)**: No bucket or S3 credentials created.
  - **Enable**: Creates a 30 GB S3-compatible bucket with auto-tiering.

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
  - **443 only (default)**: HTTPS only.
  - **80 and 443**: HTTP + HTTPS (for web servers with redirect).
  - **Custom**: Let the user specify a comma-separated list.

- **UDP ports**: Ask if they need any UDP ports open.
  - **None (default)**: No UDP ports.
  - **51820 (WireGuard)**: For VPN use.
  - **Custom**: Let the user specify.

**Question group 5 — Object storage (only if object storage was enabled):**

Skip this group if object storage was not enabled.

- **Archive lifecycle**: Ask if they want automatic archiving of old objects.
  - **Disable (default)**: Objects stay in their current tier.
  - **Enable**: Move objects to Archive tier after N days (ask for number of days, default 180). Mention 90-day minimum retention and ~1 hour restore time.

#### Phase 4: Generate Configuration

1. Check if `terraform/environments/oci-prod/oci-prod.auto.tfvars` already exists. If so, ask whether to overwrite or abort.

2. Generate `oci-prod.auto.tfvars` with the collected values. Only include non-default values to keep the file clean. Always include:
   - `compartment_ocid`
   - `user_ocid`
   - `availability_domain`
   - `ssh_public_key`

   Conditionally include (only when different from defaults):
   - `alert_email` (only if provided)
   - `enable_public_access` (only if `false`)
   - `additional_tcp_ports` (only if not `[443]`)
   - `additional_udp_ports` (only if not empty)
   - `enable_mysql` (only if `true`)
   - `enable_object_storage` (only if `true`)
   - `enable_block_volume` (only if `false`)
   - `boot_volume_size_gb` (only if not `50`)
   - `enable_idle_alerts` (only if `true`)
   - `enable_high_utilization_alerts` (only if `true`)
   - `object_storage_archive_enabled` (only if `true` and object storage enabled)
   - `object_storage_archive_days` (only if archive enabled)

   Use the same format as `oci-prod.auto.tfvars.example` with section headers and comments explaining each value.

3. Write the file using the Write tool.

#### Phase 5: Next Steps

Show the user what to do next:

1. If MySQL was enabled, set the MySQL password:
   ```
   export TF_VAR_mysql_admin_password="YourSecurePassword123!"
   ```
   Remind them: 8-32 characters, must include uppercase, lowercase, number, and special character.
   Skip this step if MySQL is disabled.

2. Initialize and deploy:
   ```
   just init
   just plan
   just apply
   ```

3. After deployment:
   - `just ssh-allow` to open SSH from their current IP
   - `just ssh` to connect
   - If block volume enabled: mount instructions
   - If MySQL enabled: `just mysql-tunnel` for MySQL access

Ask if they'd like to proceed with `just init` now or do it later.

### Notes

- Use `tofu` for all commands (not `terraform`) per project convention.
- Never write `TF_VAR_mysql_admin_password` to any file — it must stay as an environment variable.
- The generated tfvars should be clean and well-commented, matching the style of `oci-prod.auto.tfvars.example`.
- If the user's OCI account is a trial (not upgraded to Pay As You Go), warn them that ARM instances may fail to create due to capacity limits — recommend upgrading to PAYG (still free for Always Free resources).
