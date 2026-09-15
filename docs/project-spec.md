# Problem

## What are you building, and why?

An automated, secured shared hosting platform on Azure VMs - deploying
and managing multi-tenant PHP/HTML sites has historically meant
hardcoded credentials on disk, manual web host setup that drifts
between environments, and no centralized backup plan. This repo
automates all of it with Terraform, Ansible, and a Jenkins portal, at
enterprise scale: Azure NetApp Files for sub-millisecond shared
storage and a preprod+prod environment split.

## Goals

- Provision a hardened Hub-Spoke Azure network with a single command
  chain (`make bootstrap`, `make hub-deploy`, `make infra-preprod` /
  `make infra-prod`).
- Scale the web compute fleet by changing `vm_count` and re-applying.
- Provision new tenant sites in under 2 minutes via the Jenkins portal
  or a direct Ansible CLI run.
- Retrieve database and SSH secrets dynamically from Azure Key Vault -
  no static credentials stored on disk or in Git.

## Non-Goals

- Kubernetes orchestration - this is VM-based hosting on purpose, to
  keep the stack approachable without a container orchestrator.
- A customer-facing control panel (cPanel-style) - administration is
  Jenkins/Ansible only.
- Multi-region or multi-subscription topology.

## Success Criteria

- The infrastructure can be fully deployed, updated, and destroyed
  using `make` commands.
- VMs scale up/down by changing variables and re-running
  `terraform apply`.
- Private endpoints and managed identities fetch secrets from Key
  Vault with zero static credentials.
- A new site is reachable within 2 minutes of running the onboarding
  job.

## Risks

- NetApp Files quota constraints or cost overhead - mitigated by
  setting a minimum pool size and, for non-production spokes, being
  able to fall back to standard Azure Files NFS (see the `main`
  branch, which does exactly that by default).
- Management network breach - mitigated with Fail2Ban, disabled root
  login, and NSG rules restricting SSH to the Hub.
- Secret rotation failures - mitigated with Key Vault versioning and
  Ansible dynamic secret lookups.

## Notes

- Requires an active Azure subscription with quota for Azure NetApp
  Files and Standard D-series VMs, the Azure CLI, Terraform, and Make.
- Want a cheaper, quota-free first deploy instead - single environment,
  Azure Files NFS instead of NetApp Files? See the `main` branch.
- See [HOW_TO_GUIDE.md](../HOW_TO_GUIDE.md) for the deployment walkthrough
  and [SITE_MANAGEMENT.md](../SITE_MANAGEMENT.md) for the day-2 operator
  runbook.
