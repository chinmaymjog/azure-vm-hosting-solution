# Task Tracker

## Document Control

- Project: Azure Shared Hosting Platform (Hardened)
- Owner: Chinmay Jog
- Last updated: 2026-06-06
- Version: 0.1.0

## Current Focus

- Theme: End-User Hosting Platform Deployment
- Current objective: Set up and provision the hardened multi-tenant Azure hosting infrastructure.
- This week target: Complete environment configuration, bootstrap state, deploy Management Hub, and deploy the Spokes.

## Now (Do First)

Keep this section to a maximum of 3 tasks.

| ID | Task | Requirement IDs | Owner | Verification | Status |
| -- | ---- | --------------- | ----- | ------------ | ------ |
| T-001 | Configure local environment settings (`make setup`) | NFR-003 | End User | Check local `.env` generation | Not Started |
| T-002 | Bootstrap remote backend storage state (`make bootstrap`) | NFR-003 | End User | Check Azure CLI Resource Group | Not Started |
| T-003 | Deploy Shared Management & Secrets Hub VNet (`make hub-init` && `make hub-deploy`) | NFR-003 / NFR-001 | End User | Terraform output success | Not Started |

## Next (Queue)

Use this for tasks planned after Now.

| ID | Task | Requirement IDs | Verification | Notes |
| -- | ---- | --------------- | ------------ | ----- |
| T-004 | Download SSH private key from Key Vault | NFR-001 | File `./ssh-key` exists with `600` permissions | Required to connect to Jumpbox/compute fleet |
| T-005 | Deploy Spoke workload environment (`make infra-init` && `make infra-preprod`) | FR-001 / FR-002 / FR-004 / NFR-002 | Spoke resources visible in Azure Portal | Deploys Web VMs, MySQL server, NetApp files |
| T-006 | Sync automation stack and run Jenkins server (`make jenkins-sync` && `make jenkins-up`) | FR-003 / NFR-001 | Open SSH port-forwarding to port 8080 and view login | Builds & deploys Jenkins container on Jumpbox |

## Later (Backlog)

Use this for ideas or deferred work.

| ID | Task | Requirement IDs | Notes |
| -- | ---- | --------------- | ----- |
| T-007 | Execute web stack configuration playbook | FR-001 | Runs Ansible setup to install PHP/Apache on compute fleet |
| T-008 | Onboard a shared website via Jenkins portal | FR-001 / FR-004 | Run `site_add` job and check file/database creations |
| T-009 | Verify site connectivity and edge routing | FR-002 | Run cURL command or view via hosts file override |

## Done

| ID | Completed On | Requirement IDs | Validation Evidence | Notes |
| -- | ------------ | --------------- | ------------------- | ----- |

## Quick Coverage Check

- [ ] Every task in Now has requirement IDs.
- [ ] Every task in Done has validation evidence.
- [ ] docs/project-spec.md reflects current scope.
- [ ] docs/architecture.md reflects major decisions.
