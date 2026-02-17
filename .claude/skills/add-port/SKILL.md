---
name: add-port
description: Open or close a TCP/UDP port on the instance — updates security list, iptables, and NLB
allowed-tools: Read, Edit, Bash, Grep, Glob
argument-hint: "<port>[/udp] or remove <port>"
---

## Add or Remove a Port

Open or close an inbound port across all three layers: VCN security list, instance iptables (cloud-init), and NLB forwarding.

**Arguments:**
- `<port>`: Add a TCP port (e.g., `80`, `8080`)
- `<port>/udp`: Add a UDP port (e.g., `51820/udp`)
- `remove <port>`: Remove a TCP port
- `remove <port>/udp`: Remove a UDP port

### How ports work in this project

Ports are controlled by two variables in `terraform/environments/oci-prod/variables.tf`:
- `additional_tcp_ports` (default: `[443]`)
- `additional_udp_ports` (default: `[]`)

These feed into three places via `locals` in `main.tf`:
1. **VCN security list** — network-level firewall
2. **Cloud-init template** — instance-level iptables rules
3. **NLB forwarding** — load balancer listeners/backends

When `enable_public_access = false`, both lists are forced empty regardless of these variables.

### Steps

1. Read `terraform/environments/oci-prod/oci-prod.auto.tfvars` to check current port settings
2. If no port override exists in tfvars, the defaults from `variables.tf` apply
3. Add or remove the port from the appropriate list in `oci-prod.auto.tfvars`
4. Warn the user that cloud-init changes (iptables) require instance recreation to take effect, while security list and NLB changes apply immediately via `terraform apply`
5. Ask if they want to run `terraform plan` to preview the change
