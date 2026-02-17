# oracle-world

Terraform/OpenTofu modules for Oracle Cloud Infrastructure (OCI) Always Free tier. Deploys a complete environment with ARM compute, MySQL HeatWave, S3-compatible object storage, monitoring, and budget alerts — all within the free tier.

## What You Get (All Free)

| Resource | Spec |
|----------|------|
| **Compute** | VM.Standard.A1.Flex — 4 OCPUs, 24 GB RAM (ARM) |
| **Boot Storage** | 50 GB (expandable to 200 GB) + weekly backups |
| **Block Storage** | 150 GB attached volume |
| **MySQL** | 50 GB Always Free HeatWave (private subnet) |
| **Object Storage** | 30 GB S3-compatible (auto-tiered: Standard + Infrequent + Archive) |
| **Network LB** | Stable public IP for services (when `enable_public_access = true`) |
| **Monitoring** | Idle-detection alarms to prevent instance reclaim (optional) |
| **Budget Alerts** | Email alerts at 50%/80%/100% thresholds and on any charges |

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

### 4. Deploy

```bash
just setup                                        # Auto-discovers OCI config, generates tfvars
export TF_VAR_mysql_admin_password="YourPass123!"  # MySQL password (env var, not in files)
just init                                          # Download providers
just plan                                          # Preview changes
just apply                                         # Deploy everything
```

### 5. Connect

```bash
just ssh-allow       # Open SSH from your current IP
just ssh             # Connect to the instance
just mysql-tunnel    # Tunnel MySQL to localhost:3306 (separate terminal)
just ssh-revoke      # Close SSH when done
```

<details>
<summary>Manual setup (without just)</summary>

```bash
cd terraform/environments/oci-prod
cp oci-prod.auto.tfvars.example oci-prod.auto.tfvars
# Edit oci-prod.auto.tfvars with your values (see table below)
export TF_VAR_mysql_admin_password="YourPass123!"
tofu init && tofu plan && tofu apply
```

| Variable | How to Find |
|----------|------------|
| `compartment_ocid` | `oci iam compartment list` or tenancy OCID from `~/.oci/config` |
| `user_ocid` | `grep user ~/.oci/config` |
| `availability_domain` | `oci iam availability-domain list` |
| `ssh_public_key` | `cat ~/.ssh/id_ed25519.pub` |
| `alert_email` | Your email for budget/monitoring alerts |

</details>

## Configuration

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

Enable monitoring alarms that fire after ~4 days of sustained low utilization, giving you ~3 days to act before reclamation:

```hcl
# In oci-prod.auto.tfvars:
enable_idle_alerts = true       # Off by default
alert_email        = "you@example.com"
```

Optional high-utilization alerts warn when CPU or memory exceed 90%:

```hcl
enable_high_utilization_alerts = true   # Off by default
```

### Other Options

```hcl
enable_block_volume  = false  # Skip 150 GB block volume (use larger boot volume instead)
boot_volume_size_gb  = 200    # Use full 200 GB as boot volume

# Object Storage archive lifecycle (disabled by default)
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
| `oci-network` | VCN, public + private subnets, internet gateway, security lists |
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
│                       │ :3306                            │
│  ┌────────────────────┼───────────────────────────────┐  │
│  │ Private Subnet (10.0.1.0/24) — no internet        │  │
│  │                    ▼                               │  │
│  │            ┌──────────────┐                        │  │
│  │            │ MySQL        │                        │  │
│  │            │ HeatWave     │                        │  │
│  │            │ 50 GB        │                        │  │
│  │            └──────────────┘                        │  │
│  └────────────────────────────────────────────────────┘  │
│                                                          │
│  ┌──────────────┐  ┌──────────────────────────────────┐  │
│  │ Block Volume │  │ Object Storage (S3-compatible)   │  │
│  │ 150 GB       │  │ 30 GB auto-tiered                │  │
│  └──────────────┘  └──────────────────────────────────┘  │
└──────────────────────────────────────────────────────────┘
```

### Network Design

The compute instance lives in a **public subnet** — OCI NAT gateways aren't included in Always Free, so a private-subnet instance couldn't reach the internet for updates. The NLB provides a stable public IP for services that survives instance recreation.

MySQL is isolated in a **private subnet** with no internet gateway route. Access via SSH tunnel from the instance.

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

**Connect to MySQL** (from a separate terminal):

```bash
just mysql-tunnel
# Then: mysql -h 127.0.0.1 -P 3306 -u admin -p
```

## Free Tier Limits

| Resource | Free Limit | Project Default |
|----------|-----------|----------------|
| ARM Compute (A1.Flex) | 4 OCPUs, 24 GB RAM | 1 instance: 4 OCPUs, 24 GB |
| Boot + Block Volume | 200 GB combined, 5 backups | 50 GB boot + 150 GB block |
| Object Storage | 10 GB/tier = 30 GB (paid account) | 1 bucket, auto-tiering |
| MySQL HeatWave | 1 DB, 50 GB data + 50 GB backup | MySQL.Free shape |
| Network Load Balancer | 1 NLB | 1 (when public) |
| Monitoring Alarms | Unlimited | 3 idle + 2 high-util (optional) |
| Budget Alerts | Unlimited | 4 rules |
| Outbound Data | 10 TB/month | N/A |

See [OCI Always Free Resources](https://docs.oracle.com/en-us/iaas/Content/FreeTier/freetier_topic-Always_Free_Resources.htm) for full details.

## State Backend

Local state by default. To use a remote backend, uncomment in `main.tf`:

```hcl
backend "pg"  { schema_name = "oci_prod" }
backend "s3"  { bucket = "tf-state" ... }
backend "gcs" { bucket = "tf-state" ... }
```

## Important: Offsite Backups Recommended

There are reports of Oracle unexpectedly closing Always Free tier accounts without warning. While this project includes boot volume backups and `prevent_destroy` lifecycle rules, those protections only exist within OCI itself. If your account is terminated, all resources — including backups — are lost.

**Keep offsite backups of anything you can't afford to lose.** Regularly back up critical data to an external provider outside of OCI.

## License

[MIT](LICENSE)
