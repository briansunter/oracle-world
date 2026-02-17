# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

Terraform/OpenTofu IaC project that provisions a complete Oracle Cloud Infrastructure (OCI) Always Free tier environment: ARM compute, MySQL HeatWave, S3-compatible object storage, network load balancer, utilization monitoring, and budget alerts.

## Commands

Prefer `just` recipes from the project root. All `tofu` commands run from `terraform/environments/oci-prod/`.

### Justfile (project root)

```bash
just setup         # Auto-discover OCI config, generate tfvars
just init          # Initialize providers and modules
just plan          # Preview changes
just apply         # Deploy infrastructure
just destroy       # Tear down infrastructure
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
cd terraform/environments/oci-prod
cp oci-prod.auto.tfvars.example oci-prod.auto.tfvars
# Edit oci-prod.auto.tfvars with your values

tofu init
tofu plan
tofu apply
```

Set MySQL password via environment variable to avoid it in files:
```bash
export TF_VAR_mysql_admin_password="YourPassword123!"
```

## Always Free Tier Limits

These are the hard limits. This project's defaults are tuned to maximize free resources without exceeding them.

| Resource | Free Limit | This Project's Default |
|----------|-----------|----------------------|
| **ARM Compute (A1.Flex)** | 4 OCPUs, 24 GB RAM total (splittable across up to 4 instances) | 1 instance: 4 OCPUs, 24 GB |
| **AMD Compute (E2.1.Micro)** | 2 instances, 1/8 OCPU + 1 GB each | Not used (shape is selectable) |
| **Boot + Block Volume** | 200 GB combined, 5 backups | 50 GB boot + 150 GB block = 200 GB |
| **Object Storage** | 20 GB combined (Always Free account) or 10 GB/tier = 30 GB (paid account) | 1 bucket, auto-tiering enabled |
| **Object Storage API** | 50,000 requests/month | N/A |
| **MySQL HeatWave** | 1 DB system, 50 GB data + 50 GB backup | MySQL.Free shape, 50 GB |
| **Network Load Balancer** | 1 NLB | 1 NLB (when `enable_public_access = true`) |
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
│   ├── oci-network/       # VCN, public + private subnets, internet gateway, security lists
│   ├── oci-compute/       # ARM VM.Standard.A1.Flex instance
│   ├── oci-storage/       # Block volume + attachment
│   ├── oci-mysql-heatwave/# Always Free MySQL with optional HeatWave
│   ├── oci-nlb/           # Network Load Balancer (stable public IP for instance)
│   ├── oci-object-storage/# S3-compatible bucket with auto-tiering/lifecycle
│   ├── oci-monitoring/    # Idle-detection & high-utilization alarms (reclaim prevention)
│   └── oci-budget-alerts/ # Cost monitoring at 50%/80%/100% thresholds
└── shared/
    └── variables.tf       # Shared variable definitions
```

**Key design decisions:**
- Modules are independent — network and MySQL persist when compute is destroyed/recreated
- Block storage is conditionally created via `count` (`enable_block_volume` variable)
- `enable_public_access` (default `true`) is the master switch for public-facing services: when `false`, NLB is not created, no inbound TCP/UDP ports are opened (security list, iptables, NLB all go dark), only SSH via `ssh_source_cidr` remains
- `additional_tcp_ports` (default `[443]`) and `additional_udp_ports` (default `[]`) customize which ports are open when public access is enabled; same lists feed VCN security list, instance iptables (cloud-init), and NLB forwarding
- MySQL and object storage have `prevent_destroy` lifecycle rules
- NLB sits in front of the compute instance providing a stable public IP that survives instance recreation
- MySQL is in a private subnet (no internet gateway route) — access via SSH tunnel from the instance
- Compute stays in the public subnet because OCI NAT gateways are not free tier — a private-subnet instance couldn't reach the internet for updates
- Boot volume has a Bronze backup policy (weekly, 4 retained) — fits within 5 free backups
- Compute shape validation restricts to `VM.Standard.A1.Flex` and `VM.Standard.E2.1.Micro` (both free tier eligible)
- Variable validations enforce free tier boundaries (OCPUs 1-4, memory 1-24 GB, boot volume 47-200 GB)
- Cloud-init on first boot opens iptables (OCI Ubuntu blocks inbound by default), hardens SSH, enables unattended upgrades

## Provider

- `oracle/oci` >= 5.0 — all OCI resources (uses `~/.oci/config` DEFAULT profile)

## Environment Setup

1. Copy `terraform/environments/oci-prod/oci-prod.auto.tfvars.example` → `oci-prod.auto.tfvars`
2. Fill in required values: `compartment_ocid`, `user_ocid`, `availability_domain`, `ssh_public_key` (plus `alert_email` if you want budget/monitoring alerts)
3. Set `TF_VAR_mysql_admin_password` as an environment variable (8-32 chars, must include uppercase, lowercase, number, special char)
4. State is local by default; remote backends (pg/s3/gcs) are commented in `main.tf`

## Security Defaults

Only **443/TCP (HTTPS)** is open by default via `enable_public_access = true`. Set `enable_public_access = false` for private mode — no NLB, no inbound ports, SSH only.

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

1. **Mount block volume**: `sudo mkfs.ext4 /dev/oracleoci/oraclevdb && sudo mount /dev/oracleoci/oraclevdb /data` (first time only, add to `/etc/fstab`)
2. **MySQL access**: `just mysql-tunnel` then connect with `mysql -h 127.0.0.1 -P 3306 -u admin -p`

## Skills

Slash commands for common operations (defined in `.claude/skills/`):

| Command | Description |
|---------|-------------|
| `/setup` | Interactive setup wizard — walks through OCI config with guided questions |
| `/deploy [plan\|apply\|destroy]` | Deploy or update infrastructure (manual only) |
| `/ssh [allow\|revoke\|connect\|tunnel]` | Manage SSH access (manual only) |
| `/status` | Show current infrastructure state and outputs |
| `/add-port <port>[/udp]` | Open or close a port across all layers |
| `/add-module <name>` | Scaffold a new Terraform module |

`/deploy` and `/ssh` are `disable-model-invocation: true` — only the user can trigger them, not Claude autonomously.

## Reference Links

- OCI Always Free Resources: https://docs.oracle.com/en-us/iaas/Content/FreeTier/freetier_topic-Always_Free_Resources.htm
- OCI Free Tier FAQ: https://www.oracle.com/cloud/free/faq/
- OCI CLI Setup: https://docs.oracle.com/en-us/iaas/Content/API/SDKDocs/cliinstall.htm
- OCI CLI Config File: https://docs.oracle.com/en-us/iaas/Content/API/Concepts/sdkconfig.htm
- OpenTofu Docs: https://opentofu.org/docs/
- OCI Terraform Provider: https://registry.terraform.io/providers/oracle/oci/latest/docs
