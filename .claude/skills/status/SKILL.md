---
name: status
description: Show current state of OCI infrastructure — IPs, resources, drift
allowed-tools: Bash, Read, Grep, Glob
---

## Infrastructure Status

Show the current state of the deployed OCI infrastructure.

### Steps

1. Check if terraform state exists: `terraform -chdir=terraform/environments/oci-prod show` (if it fails, tell the user nothing is deployed yet)
2. Run `terraform -chdir=terraform/environments/oci-prod output` to get all outputs
3. Present a clean summary to the user:
   - Instance IP (direct) and NLB IP (if public access enabled)
   - SSH connection command
   - MySQL connection info
   - Object Storage bucket name and S3 endpoint
   - Which features are enabled (public access, block volume, HeatWave)
   - Boot backup policy
4. If the user asks about drift, run `terraform -chdir=terraform/environments/oci-prod plan` and report any differences between state and actual infrastructure
