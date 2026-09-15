# Problem

## What are you building, and why?

An automated, secured shared hosting platform on Azure VMs - deploying
and managing multi-tenant PHP/HTML sites has historically meant
hardcoded credentials on disk, manual web host setup that drifts
between environments, and no centralized backup plan. This repo
automates all of it with Terraform, Ansible, and a Jenkins portal.

## Goals

- Provision a hardened Hub-Spoke Azure network with a single command
  chain (`make bootstrap`, `make hub-deploy`, `make infra-deploy`).
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
- Private endpoints and managed identities fetch secrets from Key
  Vault with zero static credentials.
- A new site is reachable within 2 minutes of running the onboarding
  job.

## Risks

- Real Azure cost from day one - Front Door, a Jumpbox, MySQL Flexible
  Server, and Premium Azure Files NFS are all billed resources. See
  `docs/architecture.md` for how `main` keeps this as low as
  practical; the `advanced` branch trades cost for Azure NetApp Files
  and a preprod+prod split.
- Management network breach - mitigated with Fail2Ban, disabled root
  login, and NSG rules restricting SSH to the Hub.
- Secret rotation failures - mitigated with Key Vault versioning and
  Ansible dynamic secret lookups.

## Notes

- Requires an active Azure subscription, the Azure CLI, Terraform, and
  Make.
- See [HOW_TO_GUIDE.md](../HOW_TO_GUIDE.md) for the deployment walkthrough
  and [SITE_MANAGEMENT.md](../SITE_MANAGEMENT.md) for the day-2 operator
  runbook.
