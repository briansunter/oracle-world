---
name: ssh
description: Manage SSH access to the OCI instance — open, connect, or close
disable-model-invocation: true
allowed-tools: Bash, Read
argument-hint: "[allow|revoke|connect]"
---

## SSH Access Management

Manage SSH access to the OCI compute instance. SSH is blocked by default and must be opened from a specific IP.

**Arguments:**
- `allow` (default): Open SSH from the user's current public IP and apply the security list change
- `revoke`: Close SSH access (remove the IP from the security list) and apply
- `connect`: SSH into the instance
- `tunnel`: Open MySQL SSH tunnel (localhost:3306)

### Steps

#### allow (default)
1. Get the user's public IP: `curl -s --max-time 5 https://ifconfig.me`
2. Show the IP and confirm with the user
3. Run: `terraform -chdir=terraform/environments/oci-prod apply -var="ssh_source_cidr=<IP>/32" -target=module.network.oci_core_security_list.main`

#### revoke
1. Run: `terraform -chdir=terraform/environments/oci-prod apply -var="ssh_source_cidr=" -target=module.network.oci_core_security_list.main`
2. Confirm SSH is now closed

#### connect
1. Get instance IP: `terraform -chdir=terraform/environments/oci-prod output -raw instance_ip`
2. Run: `ssh ubuntu@<IP>`

#### tunnel
1. Get instance IP and MySQL IP from terraform outputs
2. Run: `ssh -N -L 3306:<mysql_ip>:3306 ubuntu@<instance_ip>`
3. Tell the user to connect with: `mysql -h 127.0.0.1 -P 3306 -u admin -p`
