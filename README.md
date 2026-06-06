# Azure Shared Hosting Platform (Hardened)

A modular, enterprise-grade Infrastructure-as-Code (IaC) repository for deploying a secure, high-performance shared hosting platform on Azure.

## Start Here

Before proceeding, review the onboarding checks:
- [x] Align repository layout to project standards.
- [x] Read the engineering standards in `repo-standards.md`.
- [x] Review `CONTRIBUTING.md` and Conventional Commits guidelines.
- [x] Read `docs/project-spec.md` to understand goals and scope.
- [x] Read `docs/architecture.md` to understand design choices and ADRs.
- [x] Follow `HOW_TO_GUIDE.md` for environment bootstrapping.

## Problem Statement

Traditional VM hosting often suffers from manual toil, security drift, and high costs. Setting up a secure, multi-tenant web environment that isolates database secrets, secures administrative access, and handles shared volumes can be slow and error-prone. This project addresses these pain points by offering:
- Automated, reproducible environment builds via Terraform.
- Automated server configurations and site onboarding via Ansible.
- Sealed secret access and centralized backups to minimize security risks.

## Key Features

- **Global Ingress & WAF**: Azure Front Door with Web Application Firewall for edge protection.
- **Hardened Spokes**: Scales out VMs in private subnets, fronted by Azure Load Balancers.
- **Hub-Spoke Isolation**: Separate Management Hub VNet with SSH Jumpbox, linked via private peering.
- **Zero-Trust Secrets**: User-Assigned Managed Identities and Azure Key Vault for database password lookups.
- **Multi-Tier Storage**: Azure NetApp Files for high-performance NFS v4.1 web volumes, plus Azure Files NFS for centralized, geo-redundant backups.
- **Administrative Portal**: Hardened Jenkins automation server running on the Jumpbox for site creation and maintenance.

## High-Level Architecture

The hosting platform is structured as a **Hub-Spoke architecture** to isolate management operations from customer-facing web traffic:
- **Shared Hub VNet**: Contains the Management Jumpbox, Azure Key Vault, and Central Backups storage.
- **Platform Spoke VNet**: Contains the Ubuntu VM scale set (compute fleet), Azure Database for MySQL Flexible Server, Private Load Balancer, and Azure NetApp Files volume.
- **Cross-VNet Communication**: Secured via VNet Peering and Private Endpoints.

Reference the details in [architecture.md](file:///Users/chinmayjog/repos/personal/azure-vm-hosting-solution/docs/architecture.md).

## Technology Stack

- **Runtime & OS**: Ubuntu 22.04 LTS VMs, PHP 8.1/8.2, Apache 2.4
- **Infrastructure as Code**: Terraform >= 1.5.0
- **Configuration & Deployment**: Ansible >= 2.15.0
- **CI/CD & Portal**: Jenkins (Dockerized)
- **Cloud Platform**: Microsoft Azure

## Repository Structure

Keep this tree aligned with the actual repository layout:

```text
azure-vm-hosting-solution/
|-- .github/
|   `-- workflows/          # CI/CD workflows and policy checks
|-- config/                 # Non-secret config templates
|-- docs/                   # Planning and execution source of truth
|   |-- architecture.md     # Component flow and Architecture Decision Records (ADRs)
|   |-- project-spec.md     # Goals, requirements, and scope
|   `-- tasks.md            # Active tasks and validation tracker
|   `-- posts/              # Blog posts and showcased articles
|-- infra/
|   |-- ansible/            # Ansible playbooks and web host configurations
|   |-- jenkins/            # Jenkins Docker configuration and jobs XMLs
|   `-- terraform/          # Terraform modules (platform and shared-hub)
|-- scripts/                # Helper and automation scripts
|-- src/                    # Code/source directories (placeholder)
|-- tests/                  # Integration and system tests
|-- .gitignore              # Ignored files (secrets, local environments)
|-- CONTRIBUTING.md         # Contribution and branching workflows
|-- HOW_TO_GUIDE.md         # Step-by-step setup and deployment guide
|-- Makefile                # Operational entry point
|-- SITE_MANAGEMENT.md      # Site provisioning and daily operations
`-- README.md               # Main project introduction
```

## Installation

Local setup requires:
- Azure CLI installed and authenticated (`az login`)
- Terraform installed
- Make utility installed

Run the following command to initialize your local environment configuration:
```bash
make setup
```

Follow the complete instructions in [HOW_TO_GUIDE.md](file:///Users/chinmayjog/repos/personal/azure-vm-hosting-solution/HOW_TO_GUIDE.md).

## Usage

Day-to-day operations are simplified using the root-level `Makefile`:
- **Bootstrap Storage State**: `make bootstrap`
- **Deploy Shared Management Hub**: `make hub-init && make hub-deploy`
- **Deploy Workloads (Preprod/Prod)**: `make infra-init && make infra-preprod`
- **Sync Ansible & Jenkins**: `make jenkins-sync && make jenkins-up`

For instructions on adding and configuring sites, refer to [SITE_MANAGEMENT.md](file:///Users/chinmayjog/repos/personal/azure-vm-hosting-solution/SITE_MANAGEMENT.md).

## Roadmap

- [x] Restructure codebase layout to project starter standards.
- [ ] Implement automated lint checks for Ansible playbooks and Terraform code.
- [ ] Add unit testing for template generation scripts.
- [ ] Secure administrative portal with OAuth2 logins.

## Documentation

Link core docs:
- [docs/project-spec.md](file:///Users/chinmayjog/repos/personal/azure-vm-hosting-solution/docs/project-spec.md): Requirements and scope source of truth.
- [docs/architecture.md](file:///Users/chinmayjog/repos/personal/azure-vm-hosting-solution/docs/architecture.md): Design decisions and requirement mapping.
- [docs/tasks.md](file:///Users/chinmayjog/repos/personal/azure-vm-hosting-solution/docs/tasks.md): Execution tracker and verification evidence.

---
*Maintained by [Chinmay Jog](https://github.com/chinmaymjog) | 📖 [Read my articles on Medium](https://medium.com/@chinmaymjog)*
