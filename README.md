# oracle-world

Terraform/OpenTofu modules for Oracle Cloud Infrastructure (OCI) Always Free tier. Deploys a complete environment with ARM compute, MySQL HeatWave, S3-compatible object storage, monitoring, and budget alerts — all within the free tier.

## What You Get (All Free)

| Resource | Spec | Default |
|----------|------|---------|
| **Compute** | VM.Standard.A1.Flex — 4 OCPUs, 24 GB RAM (ARM) | On |
| **Boot Storage** | 50 GB (expandable to 200 GB) + weekly backups | On |
| **Block Storage** | 150 GB attached volume | On |
| **Network LB** | Stable public IP for services | On (when `enable_public_access = true`) |
| **MySQL** | 50 GB Always Free HeatWave (private subnet) | Off (`enable_mysql`) |
| **Object Storage** | 30 GB S3-compatible (auto-tiered) | Off (`enable_object_storage`) |
| **Monitoring** | Idle-detection alarms to prevent instance reclaim | Off (`enable_idle_alerts`) |
| **Budget Alerts** | Email alerts at 50%/80%/100% thresholds | Off (enabled when `alert_email` set) |

## Setup with Claude Code

The easiest way to get started. Open [Claude Code](https://docs.anthropic.com/en/docs/claude-code) in this repo and run:

```
/setup
```

The interactive wizard checks prerequisites, auto-discovers your OCI config, and walks you through every option — public vs private mode, storage layout, monitoring, ports, and more. It generates your config and tells you exactly what to do next.

## Quick Start

### 1. Create an OCI Account

Sign up at [cloud.oracle.com/free](https://cloud.oracle.com/free) for the Always Free tier. Choose your **Home Region** carefully — Always Free resources are only available there and it cannot be changed.

After sign-up, **upgrade to Pay As You Go** (Billing > Upgrade). This is still free — you won't be charged for Always Free resources — but the trial account has capacity limits that often prevent creating ARM instances.

### 2. Install Tools

```bash
# macOS (or use `nix develop` if you have Nix)
brew install oci-cli opentofu just
```

### 3. Configure OCI CLI

```bash
oci setup config    # Creates ~/.oci/config with API keys
```

Upload the generated public key to your OCI profile: **Identity > Users > API Keys**.

### 4. Generate Secrets

```bash
./generate-env.sh    # Generates .env with random state encryption passphrase (+ MySQL password if needed)
```

This creates a `.env` file (gitignored) with `TF_VAR_state_passphrase` for encrypting Terraform state at rest. **Back up this file** — losing the passphrase means losing access to your state.

### 5. Deploy

```bash
just setup                                        # Auto-discovers OCI config, generates tfvars
just init                                          # Download providers
just plan                                          # Preview changes
just apply                                         # Deploy everything
```

To enable optional modules, add to your `oci-prod.auto.tfvars`:
```hcl
enable_mysql          = true   # Also needs TF_VAR_mysql_admin_password in .env
enable_object_storage = true
```

### 6. Connect

```bash
just ssh-allow       # Open SSH from your current IP
just ssh             # Connect to the instance
just ssh-revoke      # Close SSH when done
just mysql-tunnel    # Tunnel MySQL to localhost:3306 (if MySQL enabled)
```

<details>
<summary>Manual setup (without just)</summary>

```bash
./generate-env.sh   # Creates .env with state encryption passphrase (+ MySQL password if needed)
cd terraform/environments/oci-prod
cp oci-prod.auto.tfvars.example oci-prod.auto.tfvars
# Edit oci-prod.auto.tfvars with your values (see table below)
cd ../../..
just init && just plan && just apply
```

| Variable | How to Find |
|----------|------------|
| `compartment_ocid` | `oci iam compartment list` or tenancy OCID from `~/.oci/config` |
| `user_ocid` | `grep user ~/.oci/config` |
| `availability_domain` | `oci iam availability-domain list` |
| `ssh_public_key` | `cat ~/.ssh/id_ed25519.pub` |

</details>

## Configuration

### Defaults

Everything works out of the box — you only need to provide 4 values (compartment, user, availability domain, SSH key). Everything else has a sensible default:

| Setting | Default | Override |
|---------|---------|----------|
| **Compute** | 4 OCPUs, 24 GB RAM (ARM) | `ocpus`, `memory_in_gbs` |
| **OS** | Ubuntu 24.04 Minimal (aarch64) | `operating_system`, `os_version` |
| **Storage** | 50 GB boot + 150 GB block at `/data` | `boot_volume_size_gb`, `enable_block_volume` |
| **Public access** | Enabled — NLB + port 443 open | `enable_public_access = false` |
| **Open ports** | 443/TCP only, no UDP | `additional_tcp_ports`, `additional_udp_ports` |
| **SSH** | Blocked (no inbound port 22) | `just ssh-allow` / `ssh_source_cidr` |
| **MySQL** | Off | `enable_mysql = true` |
| **Object storage** | Off | `enable_object_storage = true` |
| **Alert email** | None (optional) | `alert_email` (required for alerts below) |
| **Idle alerts** | Off | `enable_idle_alerts = true` (recommended) |
| **High-util alerts** | Off | `enable_high_utilization_alerts = true` |
| **Budget alerts** | Off (enabled when `alert_email` is set) | `budget_amount` |
| **Boot backups** | Weekly, 4 retained | — |

The default deployment creates compute + block storage + NLB — a lean base you can build on. Enable MySQL and object storage as needed. The storage split (50 GB boot + 150 GB block) uses the full 200 GB free tier. Alternatively, set `boot_volume_size_gb = 200` and `enable_block_volume = false` for simpler single-disk setup.

### Public vs Private Mode

By default, the instance is **public** (`enable_public_access = true`): a Network Load Balancer with a stable public IP is created and port 443 (HTTPS) is opened through every layer (VCN security list, instance iptables, NLB forwarding).

Set `enable_public_access = false` for private mode — no NLB, zero inbound ports, SSH only.

| | Public (default) | Private |
|---|---|---|
| **NLB** | Created (stable IP for DNS) | Not created |
| **Inbound ports** | 443/TCP open (customizable) | None |
| **SSH** | Via `ssh_source_cidr` (IP-restricted) | Via `ssh_source_cidr` (IP-restricted) |
| **Use case** | Web apps, APIs, VPN, any internet service | Dev box, workers, SSH-only access |

```hcl
# In oci-prod.auto.tfvars:
enable_public_access = true           # Default — NLB + open ports
enable_public_access = false          # Private — SSH only, no NLB

# Customize open ports (only when public):
additional_tcp_ports = [80, 443]      # Default: [443]
additional_udp_ports = [51820]        # e.g. WireGuard
```

### Idle Instance Reclaim Prevention

Oracle reclaims Always Free instances deemed "idle" when **all** of these hold over a rolling 7-day window:
- CPU utilization (95th percentile) < 20%
- Network utilization < 20%
- Memory utilization < 20% (A1 shapes only)

Enable monitoring alarms that fire after ~4 days of sustained low utilization, giving you ~3 days to act before reclamation. Requires `alert_email`:

```hcl
# In oci-prod.auto.tfvars:
alert_email        = "you@example.com"   # Required for any alerts
enable_idle_alerts = true                # Off by default
```

Optional high-utilization alerts warn when CPU or memory exceed 90%:

```hcl
enable_high_utilization_alerts = true   # Off by default
```

### Optional Modules

```hcl
# MySQL HeatWave — 50 GB Always Free, private subnet, SSH tunnel access
enable_mysql = true
# Requires TF_VAR_mysql_admin_password in .env (run ./generate-env.sh to generate)

# S3-compatible Object Storage — 30 GB auto-tiered bucket
enable_object_storage = true
```

### Other Options

```hcl
enable_block_volume  = false  # Skip 150 GB block volume (use larger boot volume instead)
boot_volume_size_gb  = 200    # Use full 200 GB as boot volume

# Object Storage archive lifecycle (when enable_object_storage = true)
# Moves objects to Archive tier after N days — 90-day minimum retention, ~1hr restore
object_storage_archive_enabled = true
object_storage_archive_days    = 180
```

## Just Recipes

| Recipe | Description |
|--------|-------------|
| `just setup` | Auto-discover OCI config, generate tfvars |
| `just init` | Initialize providers and modules |
| `just plan` | Preview infrastructure changes |
| `just apply` | Deploy infrastructure |
| `just destroy` | Tear down infrastructure |
| `just fmt` | Format all .tf files |
| `just validate` | Validate configuration |
| `just output` | Show all outputs |
| `just ssh` | SSH to the instance |
| `just mysql-tunnel` | SSH tunnel for MySQL access |
| `just my-ip` | Show your current public IP |
| `just ssh-allow` | Open SSH from your current IP and apply |
| `just ssh-revoke` | Close SSH access and apply |

## Modules

| Module | Description |
|--------|-------------|
| `oci-network` | VCN, public subnet, optional private subnet, internet gateway, security lists |
| `oci-compute` | ARM Flex instance with configurable shape |
| `oci-storage` | Block volume with attachment |
| `oci-mysql-heatwave` | Always Free MySQL with optional HeatWave |
| `oci-nlb` | Network Load Balancer for stable public IP |
| `oci-object-storage` | S3-compatible bucket with auto-tiering and lifecycle |
| `oci-monitoring` | Idle-detection and high-utilization alarms (reclaim prevention) |
| `oci-budget-alerts` | Cost monitoring at 50%/80%/100% thresholds |

## Architecture

```
┌──────────────────────────────────────────────────────────┐
│ VCN (10.0.0.0/16)                                        │
│                                                          │
│  ┌────────────────────────────────────────────────────┐  │
│  │ Public Subnet (10.0.0.0/24)                        │  │
│  │                                                    │  │
│  │  ┌────────┐   ┌──────────┐                         │  │
│  │  │ NLB    │──▶│ ARM      │                         │  │
│  │  │ :443   │   │ Instance │                         │  │
│  │  │(stable │   │ 4C/24GB  │                         │  │
│  │  │  IP)   │   └────┬─────┘                         │  │
│  │  └────────┘        │                               │  │
│  └────────────────────┼───────────────────────────────┘  │
│                       │ :3306 (optional)                 │
│  ┌────────────────────┼───────────────────────────────┐  │
│  │ Private Subnet — optional (enable_mysql = true)    │  │
│  │                    ▼                               │  │
│  │            ┌──────────────┐                        │  │
│  │            │ MySQL        │                        │  │
│  │            │ HeatWave     │                        │  │
│  │            │ 50 GB        │                        │  │
│  │            └──────────────┘                        │  │
│  └────────────────────────────────────────────────────┘  │
│                                                          │
│  ┌──────────────┐  ┌──────────────────────────────────┐  │
│  │ Block Volume │  │ Object Storage (optional)        │  │
│  │ 150 GB       │  │ 30 GB S3-compatible              │  │
│  └──────────────┘  └──────────────────────────────────┘  │
└──────────────────────────────────────────────────────────┘
```

### Network Design

The compute instance lives in a **public subnet** — OCI NAT gateways aren't included in Always Free, so a private-subnet instance couldn't reach the internet for updates. The NLB provides a stable public IP for services that survives instance recreation.

When MySQL is enabled (`enable_mysql = true`), it's isolated in a **private subnet** with no internet gateway route. Access via SSH tunnel from the instance.

**SSH is blocked by default.** Port 22 is not open until you set `ssh_source_cidr` to your IP:

```bash
just my-ip          # Print your current public IP
just ssh-allow      # Open SSH from that IP and apply
just ssh            # Connect
just ssh-revoke     # Close SSH when done
```

### Cloud-Init

The instance runs a cloud-init script on first boot:
- **iptables** — opens ports matching VCN security list (OCI Ubuntu blocks inbound by default)
- **SSH hardening** — disables password auth and root login
- **Unattended upgrades** — enables automatic security patches

Cloud-init runs once on creation. Changes require instance recreation.

## Post-Deploy

After `just apply`:

**Mount block volume** (if enabled):

```bash
just ssh
sudo mkfs.ext4 /dev/oracleoci/oraclevdb   # first time only
sudo mkdir -p /data
sudo mount /dev/oracleoci/oraclevdb /data
echo '/dev/oracleoci/oraclevdb /data ext4 defaults,_netdev 0 2' | sudo tee -a /etc/fstab
```

**Connect to MySQL** (if `enable_mysql = true`, from a separate terminal):

```bash
just mysql-tunnel
# Then: mysql -h 127.0.0.1 -P 3306 -u admin -p
```

## Free Tier Limits

| Resource | Free Limit | Project Default |
|----------|-----------|----------------|
| ARM Compute (A1.Flex) | 4 OCPUs, 24 GB RAM | 1 instance: 4 OCPUs, 24 GB |
| Boot + Block Volume | 200 GB combined, 5 backups | 50 GB boot + 150 GB block |
| Object Storage | 10 GB/tier = 30 GB (paid account) | Off (`enable_object_storage`) |
| MySQL HeatWave | 1 DB, 50 GB data + 50 GB backup | Off (`enable_mysql`) |
| Network Load Balancer | 1 NLB | 1 (when public) |
| Monitoring Alarms | Unlimited | 3 idle + 2 high-util (optional) |
| Budget Alerts | Unlimited | 4 rules |
| Outbound Data | 10 TB/month | N/A |

See [OCI Always Free Resources](https://docs.oracle.com/en-us/iaas/Content/FreeTier/freetier_topic-Always_Free_Resources.htm) for full details.

## State Security

State and plan files are **encrypted at rest** using OpenTofu state encryption (AES-GCM + PBKDF2). The passphrase is stored in `.env` (gitignored, `chmod 600`) and loaded automatically by `just` recipes. Run `./generate-env.sh` to generate a random passphrase.

### Local State (Default)

State is stored locally in `terraform.tfstate` (gitignored). This works for solo use but has no locking, versioning, or offsite backup.

### Recommended: Remote State Backend

For durability and collaboration, move state to a remote backend. State encryption works with any backend — it encrypts client-side before storage, so you get **double encryption** (client-side AES-GCM + server-side at rest).

#### Option 1: OCI Object Storage (Recommended for OCI projects)

Uses your existing OCI account with S3-compatible API. State files are tiny (~10-50 KB) so free tier impact is negligible.

```hcl
# In main.tf, replace the local backend comment with:
backend "s3" {
  bucket                      = "terraform-state"
  key                         = "oci-prod/terraform.tfstate"
  region                      = "us-ashburn-1"  # your home region
  endpoints                   = { s3 = "https://<namespace>.compat.objectstorage.<region>.oraclecloud.com" }
  skip_region_validation      = true
  skip_credentials_validation = true
  skip_requesting_account_id  = true
  skip_metadata_api_check     = true
  use_path_style              = true
}
```

You'll need S3-compatible credentials (Customer Secret Key) — the project already creates these when `enable_object_storage = true`. Set `AWS_ACCESS_KEY_ID` and `AWS_SECRET_ACCESS_KEY` in your `.env`.

**Prerequisite:** Create the bucket manually first (chicken-and-egg — Terraform can't create its own state bucket):
```bash
oci os bucket create --name terraform-state --compartment-id <compartment_ocid>
```

Docs: [OCI Object Storage S3 Compatibility](https://docs.oracle.com/en-us/iaas/Content/Object/Tasks/s3compatibleapi.htm) | [OpenTofu S3 Backend](https://opentofu.org/docs/language/settings/backends/s3/)

#### Option 2: Terraform Cloud / HCP Terraform (Easiest)

Free for up to 500 managed resources. Includes state locking, versioning, run history, and a web UI.

```hcl
cloud {
  organization = "your-org"
  workspaces {
    name = "oci-prod"
  }
}
```

Sign up at [app.terraform.io](https://app.terraform.io) and run `tofu login`.

Docs: [HCP Terraform Free Tier](https://developer.hashicorp.com/terraform/cloud-docs/overview) | [Cloud Backend Config](https://opentofu.org/docs/cli/cloud/settings/)

#### Option 3: PostgreSQL Backend (Self-hosted)

If you run PostgreSQL on the instance or elsewhere. State locking is built-in.

```hcl
backend "pg" {
  conn_str    = "postgres://user:pass@hostname/dbname"
  schema_name = "oci_prod"
}
```

Docs: [OpenTofu pg Backend](https://opentofu.org/docs/language/settings/backends/pg/)

#### Migrating to a Remote Backend

After adding the backend block to `main.tf`:

```bash
just init    # OpenTofu detects the backend change and prompts to migrate state
```

OpenTofu will copy your local state to the remote backend. Your `.env` passphrase is still needed — state is decrypted locally, sent to the backend, and re-encrypted on read.

## Important: Offsite Backups Recommended

There are reports of Oracle unexpectedly closing Always Free tier accounts without warning. While this project includes boot volume backups and `prevent_destroy` lifecycle rules, those protections only exist within OCI itself. If your account is terminated, all resources — including backups — are lost.

**Keep offsite backups of anything you can't afford to lose.** Regularly back up critical data to an external provider outside of OCI.

## License

[MIT](LICENSE)
