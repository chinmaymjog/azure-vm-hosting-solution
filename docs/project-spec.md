# Problem Specification

## Document Control

- Project: Azure Shared Hosting Platform (Hardened)
- Owner: Chinmay Jog
- Last updated: 2026-06-06
- Version: 0.1.0

## Problem Statement

Deploying and managing multi-tenant shared hosting platforms on virtual machines has historically been associated with security risks, manual toil, and storage configuration complexities. Specifically:
- Hardcoding database credentials and certificates on disk introduces high-security vulnerability.
- Manual web host setup causes configuration drift across environments.
- Lack of centralized backup plans risks data loss.
- High-churn VM environments struggle with shared web storage IOPS and latency constraints.

This project implements an automated, secure, and enterprise-grade hosting solution to address these pain points.

# Goals

### Functional Requirements
- **FR-001 (Multi-Tenant Compute)**: Support provisioning scaling compute hosts running hardened Apache + PHP-FPM, scalable via `vm_count`.
- **FR-002 (Secured Edge & Load Balancing)**: Protect all public ingress using Azure Front Door (AFD) WAF, routing traffic to a private regional load balancer.
- **FR-003 (Administrative Automation)**: Provide a centralized Jenkins portal to perform administrative actions (site provisioning, database backups, SSL certificate creation).
- **FR-004 (Private DB Isolation)**: Integrate Azure MySQL Flexible Server inside a private subnet, resolving only via Private DNS zones.
- **FR-005 (Automated Backup & Restore)**: Schedule and archive site files and database dumps to geo-redundant storage.

### Non-Functional Requirements
- **NFR-001 (Zero-Trust Identity)**: Retrieve database secrets dynamically from Azure Key Vault using User-Assigned Managed Identities on the Jumpbox VM. No static credentials stored on disk.
- **NFR-002 (High-Performance Shared Storage)**: Serve all web assets from a high-performance Azure NetApp Files NFS v4.1 volume mounted on the compute nodes.
- **NFR-003 (Network Segregation)**: Enforce a strict Hub-Spoke topology where the management/backup plane (Hub) is network-isolated from Spoke workloads, using VNet Peering and restricted Network Security Groups (NSGs).

# Non Goals

- Kubernetes orchestration: This project focuses purely on VM-based hosting to demonstrate high-performance automation without container orchestrator complexity.
- User-facing control panel: Direct cPanel-like interface for customers is out of scope; administration is managed via Jenkins and Ansible.

# Success Criteria

- The infrastructure can be fully deployed, updated, and destroyed using `make` commands.
- Virtual machines can scale up/down by changing variables and running terraform apply.
- Private endpoints and managed identities successfully fetch secrets from Azure Key Vault without static credentials.
- Multi-tenant site provisioning takes under 2 minutes per site via Jenkins jobs.

# Stakeholders

- Technical Architect / Lead: Chinmay Jog
- Infrastructure Team

# Assumptions

- Access to an active Azure Subscription with sufficient quotas for Azure NetApp Files and Standard D-series VMs.
- Local administrator machine has the Azure CLI, Terraform, and Make installed.

# Risks

| Risk | Mitigation |
| ---- | ---------- |
| NetApp Files quota constraints or cost overhead | Set minimum pool size (2 TiB) and optimize file distributions, or fall back to standard Azure Files NFS for non-production spokes. |
| Management network breach | Jumpbox VM SSH access is hardened with Fail2Ban, security banners, disabled root login, and strict incoming NSG rules. |
| Secret rotation failures | Utilize Azure Key Vault versioning and Ansible dynamic secret lookups to fetch the latest active key versions. |

# Scope Summary

- **In Scope**: Infrastructure templates (Terraform), Configuration playbooks (Ansible), automation tasks (Jenkins files), security hardening scripts, network topologies, and NetApp configurations.
- **Out of Scope**: Public web-hosting billing, client-side domain registration automation, VM OS kernel compiles.

# References

- [HOW_TO_GUIDE.md](../HOW_TO_GUIDE.md)
- [SITE_MANAGEMENT.md](../SITE_MANAGEMENT.md)
