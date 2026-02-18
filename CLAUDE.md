# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

Terraform/OpenTofu IaC project that provisions an Oracle Cloud Infrastructure (OCI) Always Free tier environment. Default deployment: ARM compute + block storage. Optional modules: MySQL HeatWave (`enable_mysql`), S3-compatible object storage (`enable_object_storage`), utilization monitoring, and budget alerts.

## Commands

Prefer `just` recipes from the project root. All `tofu` commands run from `terraform/environments/oci-prod/`.

### Justfile (project root)

```bash
just setup         # Auto-discover OCI config, generate tfvars
just init          # Initialize providers and modules
just plan          # Preview changes
just apply         # Deploy infrastructure (interactive confirmation)
just apply-auto    # Deploy infrastructure (skip confirmation)
just destroy       # Tear down infrastructure
just destroy-auto  # Tear down infrastructure (skip confirmation)
just fmt           # Format all .tf files
just validate      # Validate configuration syntax
just output        # Show all outputs
just ssh           # SSH to the instance
just mysql-tunnel  # SSH tunnel for MySQL access (localhost:3306)
just my-ip         # Show your current public IP
just ssh-allow     # Open SSH from your current IP and apply
just ssh-revoke    # Close SSH access and apply
```

### Direct tofu commands

```bash
tofu -chdir=terraform/environments/oci-prod init
tofu -chdir=terraform/environments/oci-prod plan
tofu -chdir=terraform/environments/oci-prod apply
```

Prefer `tofu` (OpenTofu) over `terraform`. Both work interchangeably.

## Oracle Cloud Free Tier Setup

### 1. Create an OCI Account

Sign up at https://signup.oraclecloud.com/ for the Always Free tier. You'll need:
- A valid email address
- A debit/credit card (for verification only — you won't be charged)
- Choose a **Home Region** carefully — Always Free resources are only available in your home region and it cannot be changed later

After sign-up you get $300 trial credits (30 days) plus Always Free resources that never expire.

Docs: https://docs.oracle.com/en-us/iaas/Content/FreeTier/freetier.htm

### 2. Install and Configure OCI CLI

```bash
# macOS
brew install oci-cli

# Linux
bash -c "$(curl -L https://raw.githubusercontent.com/oracle/oci-cli/master/scripts/install/install.sh)"

# Initial setup — creates ~/.oci/config with API keys
oci setup config
```

This prompts for your tenancy OCID, user OCID, region, and generates an API key pair. Upload the public key to your OCI user profile in the console under Identity > Users > API Keys.

Docs: https://docs.oracle.com/en-us/iaas/Content/API/SDKDocs/cliinstall.htm

### 3. Install OpenTofu

```bash
# macOS
brew install opentofu

# Linux (snap)
snap install --classic opentofu
```

Docs: https://opentofu.org/docs/intro/install/

### 4. Find Required Values

```bash
# Compartment OCID (use tenancy OCID for root compartment)
grep tenancy ~/.oci/config

# User OCID (needed for S3-compatible credentials)
grep user ~/.oci/config

# Availability domain
oci iam availability-domain list --query 'data[0].name' --raw-output
```

### 5. Deploy

```bash
./generate-env.sh                # Generate .env with state encryption passphrase (+ MySQL password if needed)
cp terraform/environments/oci-prod/oci-prod.auto.tfvars.example \
   terraform/environments/oci-prod/oci-prod.auto.tfvars
# Edit oci-prod.auto.tfvars with your values

# (Recommended) Set up a remote state backend BEFORE first init — see "Remote State Backend" below
just init
just plan
just apply
```

> **Warning**: Never regenerate `.env` when Terraform state already exists. The state encryption passphrase in `.env` is used to encrypt/decrypt state files. A new passphrase makes existing state permanently unreadable. If you need to add secrets (e.g., MySQL password), append to `.env` rather than regenerating it.

## Always Free Tier Limits

These are the hard limits. This project's defaults are tuned to maximize free resources without exceeding them.

| Resource | Free Limit | This Project's Default |
|----------|-----------|----------------------|
| **ARM Compute (A1.Flex)** | 4 OCPUs, 24 GB RAM total (splittable across up to 4 instances) | 1 instance: 4 OCPUs, 24 GB |
| **AMD Compute (E2.1.Micro)** | 2 instances, 1/8 OCPU + 1 GB each | Not used (shape is selectable) |
| **Boot + Block Volume** | 200 GB combined, 5 backups | 50 GB boot + 150 GB block = 200 GB |
| **Object Storage** | 20 GB combined (Always Free account) or 10 GB/tier = 30 GB (paid account) | Off (`enable_object_storage`) |
| **Object Storage API** | 50,000 requests/month | N/A |
| **MySQL HeatWave** | 1 DB system, 50 GB data + 50 GB backup | Off (`enable_mysql`) |
| **VCN** | 2 VCNs | 1 VCN |
| **Outbound Data** | 10 TB/month | N/A |
| **Monitoring Alarms** | Unlimited (free) | 3 idle + 2 high-util (optional, off by default) |
| **Budget Alerts** | Unlimited | 4 rules (50%/80%/100%/any-spend) |

Full reference: https://docs.oracle.com/en-us/iaas/Content/FreeTier/freetier_topic-Always_Free_Resources.htm

### Key Caveats

- **Home region only**: Always Free resources can only be created in your home region
- **Capacity limits**: ARM instances may be unavailable in some regions due to demand — retry later or try during off-peak hours
- **Object Storage tiers**: Always Free-only accounts get 20 GB combined; paid/upgraded accounts get 10 GB per tier (30 GB total)
- **Budget minimum**: OCI API requires budget amount >= $1, so the module uses `max(1, var.budget_amount)` even when you set `budget_amount = 0` — an additional alert at $0.01 catches any actual charges
- **Idle instance reclaim**: Oracle reclaims Always Free instances deemed "idle" when ALL of these hold over a rolling 7-day window: CPU 95th percentile < 20%, network utilization < 20%, memory utilization < 20% (A1 shapes only). Set `enable_idle_alerts = true` to get email warnings after ~4 days of low utilization — giving you ~3 days to act before reclamation
- **prevent_destroy**: MySQL and object storage buckets have `prevent_destroy = true` lifecycle rules to prevent accidental deletion. Remove these blocks manually before running `tofu destroy` on those resources

## Architecture

```
terraform/
├── environments/
│   └── oci-prod/          # Production environment (entry point)
│       ├── main.tf        # Module composition and provider config
│       ├── variables.tf   # All input variables (~30)
│       ├── outputs.tf     # All outputs (~30)
│       ├── cloud-init.yaml.tftpl  # First-boot config (iptables, SSH, upgrades)
│       └── *.auto.tfvars  # Local config (gitignored)
├── modules/               # Reusable, self-contained modules
│   ├── oci-network/       # VCN, public subnet, optional private subnet, internet gateway, security lists
│   ├── oci-compute/       # ARM VM.Standard.A1.Flex instance
│   ├── oci-storage/       # Block volume + attachment
│   ├── oci-mysql-heatwave/# Always Free MySQL with optional HeatWave
│   ├── oci-object-storage/# S3-compatible bucket with auto-tiering/lifecycle
│   ├── oci-monitoring/    # Idle-detection & high-utilization alarms (reclaim prevention)
│   └── oci-budget-alerts/ # Cost monitoring at 50%/80%/100% thresholds
└── shared/
    └── variables.tf       # Shared variable definitions
```

**Key design decisions:**
- Modules are independent — network persists when compute is destroyed/recreated
- MySQL (`enable_mysql`, default `false`) and object storage (`enable_object_storage`, default `false`) are optional modules
- Block storage is conditionally created via `count` (`enable_block_volume` variable, default `true`)
- Private subnet is only created when `enable_mysql = true`
- `enable_public_access` (default `true`) is the master switch for public-facing services: when `false`, no inbound TCP/UDP ports are opened (security list and iptables go dark), only SSH via `ssh_source_cidr` remains
- `additional_tcp_ports` (default `[443]`) and `additional_udp_ports` (default `[]`) customize which ports are open when public access is enabled; same lists feed VCN security list and instance iptables (cloud-init)
- MySQL and object storage have `prevent_destroy` lifecycle rules (when enabled)
- MySQL is in a private subnet (no internet gateway route) — access via SSH tunnel from the instance
- Compute stays in the public subnet because OCI NAT gateways are not free tier — a private-subnet instance couldn't reach the internet for updates
- Boot volume has a Bronze backup policy (weekly, 4 retained) — fits within 5 free backups
- Compute shape validation restricts to `VM.Standard.A1.Flex` and `VM.Standard.E2.1.Micro` (both free tier eligible)
- Variable validations enforce free tier boundaries (OCPUs 1-4, memory 1-24 GB, boot volume 47-200 GB)
- Cloud-init on first boot opens iptables (OCI Ubuntu blocks inbound by default), hardens SSH, enables unattended upgrades

## Provider

- `oracle/oci` >= 5.0 — all OCI resources (uses `~/.oci/config` DEFAULT profile)

## Environment Setup

1. Generate `.env` with random secrets:
   ```bash
   ./generate-env.sh              # interactive — prompts for MySQL
   ./generate-env.sh --mysql      # non-interactive, include MySQL password
   ./generate-env.sh --no-mysql   # non-interactive, skip MySQL password
   ```
   The script generates `TF_VAR_state_passphrase` (always) and `TF_VAR_mysql_admin_password` (when MySQL enabled) using `openssl rand`. The `.env` file is gitignored, `chmod 600`, and loaded automatically by `just` via `set dotenv-load`.

2. Copy `terraform/environments/oci-prod/oci-prod.auto.tfvars.example` → `oci-prod.auto.tfvars`
3. Fill in required values: `compartment_ocid`, `user_ocid`, `availability_domain`, `ssh_public_key`
4. Optional: set `enable_mysql = true` and `enable_object_storage = true` for those modules
5. State is encrypted at rest via OpenTofu state encryption (AES-GCM + PBKDF2, `enforced = true`). Back up your `.env` — losing the passphrase means losing access to state.
6. (Recommended) Set up a remote backend for state locking, versioning, and offsite backup — see "Remote State Backend" section below.

## Security Defaults

### Secrets Management

All secrets live in `.env` (gitignored, `chmod 600`), never in `.auto.tfvars` or committed files:

| Secret | Source | Storage |
|--------|--------|---------|
| State encryption passphrase | `openssl rand -base64 32` via `generate-env.sh` | `.env` → `TF_VAR_state_passphrase` |
| MySQL admin password | `openssl rand` via `generate-env.sh --mysql` | `.env` → `TF_VAR_mysql_admin_password` |
| OCI API private key | `oci setup config` | `~/.oci/config` (outside project) |
| S3 secret key | Generated by Terraform | State file (encrypted) |

- **State encryption**: OpenTofu encrypts state and plan files at rest (AES-GCM + PBKDF2). Enforced — unencrypted state is rejected.
- **`.env` is never read by Claude**: A `PreToolUse` hook (`.claude/hooks/protect-env.sh`) blocks Read, Edit, Write, and Bash tools from accessing `.env` or echoing `TF_VAR_` secret values.
- **`generate-env.sh` handles all secret creation**: The script generates secrets internally and writes directly to `.env`. Claude calls the script but never sees the output values.
- **Backup `.env`**: Losing the passphrase means losing access to your Terraform state. `--force` creates a timestamped backup before overwriting.
- **Never regenerate `.env` with existing state**: The passphrase encrypts state files. Regenerating creates a new passphrase that cannot decrypt existing state. To add new secrets (e.g., MySQL password), append to `.env` instead of regenerating.

### Network Security

Only **443/TCP (HTTPS)** is open by default via `enable_public_access = true`. Set `enable_public_access = false` for private mode — no inbound ports, SSH only.

**SSH (port 22) is blocked** until `ssh_source_cidr` is set to a specific IP CIDR. Use `just ssh-allow` to open SSH from your current IP and `just ssh-revoke` to close it. SSH is independent of `enable_public_access`.

```hcl
# In oci-prod.auto.tfvars:
enable_public_access = true                # false = private mode (SSH only)
ssh_source_cidr      = "203.0.113.5/32"    # Your residential IP (just my-ip)
additional_tcp_ports  = [443]               # When public: open these TCP ports
additional_udp_ports  = [51820]             # When public: open these UDP ports
```

MySQL is in a private subnet (no internet route, no public IP). Only ports 3306/33060 are open from the public subnet. Access via SSH tunnel from the instance. ICMP ping and path MTU discovery are always allowed.

## Conventions

- All modules follow the standard `main.tf` / `variables.tf` / `outputs.tf` structure
- Variables use comprehensive `validation` blocks (regex, CIDR, range checks)
- Resources are tagged with `environment` and `managed_by` freeform tags
- Sensitive outputs are marked `sensitive = true`
- Module names in `main.tf` match their directory names without the `oci-` prefix (e.g., `module "network"` → `oci-network/`)

## Cloud-Init

The instance runs `cloud-init.yaml.tftpl` on first boot:
- Opens iptables for `additional_tcp_ports` / `additional_udp_ports` (OCI Ubuntu blocks inbound by default)
- Hardens SSH (disables password auth and root login)
- Enables unattended security upgrades

Cloud-init runs once on creation. Changes require instance recreation (terraform taint or destroy/apply).

## Post-Deploy

After `just apply`:

1. **Block volume**: Automatically formatted (ext4) and mounted at `/data` on first boot via cloud-init. Persists across reboots via `/etc/fstab`.
2. **MySQL access** (if enabled): `just mysql-tunnel` then connect with `mysql -h 127.0.0.1 -P 3306 -u admin -p`

## Remote State Backend

Local state works for solo use but has no locking, versioning, or offsite backup. **Recommended: set up a remote backend BEFORE your first `just init`** so state goes directly to the remote backend and never exists only locally. Migrating later works but is an extra step that can be avoided.

### Recommended Options

1. **OCI Object Storage** (S3-compatible) — stays within OCI, uses existing credentials, free tier impact negligible (~10-50 KB state files). Requires creating a bucket first (`oci os bucket create`), then adding an `s3` backend block with `use_path_style = true` and OCI-specific skip flags. S3 credentials (Customer Secret Key) go in `.env` as `AWS_ACCESS_KEY_ID`/`AWS_SECRET_ACCESS_KEY`.
   - Docs: https://docs.oracle.com/en-us/iaas/Content/Object/Tasks/s3compatibleapi.htm
   - Backend: https://opentofu.org/docs/language/settings/backends/s3/

2. **HCP Terraform / Terraform Cloud** — free up to 500 resources. Includes locking, versioning, run history, web UI. Just `tofu login` and add a `cloud {}` block.
   - Docs: https://developer.hashicorp.com/terraform/cloud-docs/overview

3. **PostgreSQL** — self-hosted, built-in locking. Good if you already run Postgres.
   - Backend: https://opentofu.org/docs/language/settings/backends/pg/

### Migration

Replace the commented backend in `main.tf` → run `just init` → OpenTofu prompts to migrate local state to the remote backend. State encryption (client-side) works with all backends — you get double encryption.

### Important

- State bucket must be created manually before migration (chicken-and-egg)
- S3 credentials for OCI go in `.env` (same as other secrets — never committed)
- The `.env` passphrase is still required — state is encrypted/decrypted client-side regardless of backend

## Skills

Slash commands for common operations (defined in `.claude/skills/`):

| Command | Description |
|---------|-------------|
| `/setup` | Interactive wizard — generates `.env` (secrets via `generate-env.sh`), `oci-prod.auto.tfvars` (config), and optionally sets up remote state backend |
| `/deploy [plan\|apply\|destroy]` | Deploy infrastructure via `just` recipes (manual only) |
| `/ssh [allow\|revoke\|connect\|tunnel]` | Manage SSH access (manual only) |
| `/status` | Show current infrastructure state and outputs |
| `/add-port <port>[/udp]` | Open or close a port across all layers |
| `/add-module <name>` | Scaffold a new Terraform module |

`/deploy` and `/ssh` are `disable-model-invocation: true` — only the user can trigger them, not Claude autonomously.

### Skill Safety

- All skills must use `just` recipes (not raw `tofu`) to ensure `.env` secrets are loaded via `set dotenv-load`.
- Skills must never read, cat, source, or inspect `.env` — a `PreToolUse` hook blocks this. Use `test -f .env` to check existence only.
- Secret generation is handled exclusively by `./generate-env.sh` — skills call it with `--mysql`/`--no-mysql` flags but never see the generated values.

## Reference Links

- OCI Always Free Resources: https://docs.oracle.com/en-us/iaas/Content/FreeTier/freetier_topic-Always_Free_Resources.htm
- OCI Free Tier FAQ: https://www.oracle.com/cloud/free/faq/
- OCI CLI Setup: https://docs.oracle.com/en-us/iaas/Content/API/SDKDocs/cliinstall.htm
- OCI CLI Config File: https://docs.oracle.com/en-us/iaas/Content/API/Concepts/sdkconfig.htm
- OpenTofu Docs: https://opentofu.org/docs/
- OCI Terraform Provider: https://registry.terraform.io/providers/oracle/oci/latest/docs
