# Architecture and Decisions

## Document Control

- Project: Azure Shared Hosting Platform (Hardened)
- Owner: Chinmay Jog
- Last updated: 2026-06-06
- Version: 0.1.0

## System Context

### Business and Technical Context

This system is designed to provide high-performance, cost-effective, and secure hosting for PHP/HTML websites without the overhead of container orchestrators. Security isolation, automated backups, and shared storage scaling are key challenges addressed by combining modern cloud infrastructure with proven configuration management tools.

### Architecture Goals

- **Security Isolation**: Enforce network segregation, firewall restrictions, and zero-knowledge credentials.
- **High Disk Performance**: Meet multi-tenant disk read/write requirements under concurrent traffic.
- **Repeatable & Idempotent**: Establish configuration management and infrastructure templates that can recover from disaster easily.

## High-Level Design

### Component Overview

| Component | Responsibility | Owner |
| --------- | -------------- | ----- |
| **Azure Front Door (AFD)** | Edge WAF security, caching, SSL offloading, and global load balancing. | Terraform |
| **Public Load Balancer (LB)**| Distributes HTTP/HTTPS traffic to the private spoke compute fleet. | Terraform |
| **Compute Spoke Fleet** | Scales hardened Ubuntu VMs running Apache + PHP-FPM serving tenant assets. | Terraform / Ansible |
| **Azure NetApp Files (ANF)**| Serves high-performance NFS v4.1 storage for shared website files. | Terraform |
| **MySQL Flexible Server** | Relational database engine, network-isolated via Private DNS. | Terraform |
| **Management Jumpbox** | Bastion host running dockerized Jenkins and local Ansible runner. | Terraform / Ansible |
| **Azure Key Vault (AKV)** | Secure storage of TLS certificates and database administrator passwords. | Terraform |
| **Azure Files NFS (Backups)**| Centralized backups repository mounted via NFS 4.1 in the Hub. | Terraform |

### Interaction Diagram

```text
               [ Public Users ]
                      │
                      ▼
            [ Azure Front Door & WAF ]
                      │
                      ▼
         [ Public Load Balancer ]
                      │
      ┌───────────────┴───────────────┐
      ▼ (VNet Peering)                ▼
[ Web Compute Node 01 ]    [ Web Compute Node 02 ]
  │            │             │            │
  ▼            ▼             ▼            ▼
[ Azure NetApp Volume ]    [ MySQL Flexible Server ]
(/netappwebsites - NFS v4.1)  (Private DNS Endpoint)
               ▲
               │ (Private SSH/Ansible)
       [ Management Hub ]
      (Jumpbox / Jenkins Portal)
               │ (Managed Identity)
       [ Azure Key Vault ]
```

## Data and Control Flow

### Request/Response Flow
1. User requests a hosted site.
2. Azure Front Door inspects rules via WAF, decrypts TLS, and forwards traffic to the regional Load Balancer.
3. Load Balancer routes traffic to active compute VMs in the private Spoke subnet.
4. Apache processes requests, executes PHP, and reads site code from the mounted Azure NetApp Files volume.
5. Databases queries are routed privately to the Azure MySQL Flexible Server.

### State and Data Model Notes
- All persistent site configurations and code reside on the shared NetApp NFS volume.
- Databases are hosted in the managed MySQL server.
- Backup jobs dump database schemas and compress site files, pushing them directly to the NFS `/backups` share.

### Failure Paths
- Spoke compute node failures: Load Balancer health checks redirect traffic away from unhealthy nodes.
- NFS mount failures: System configuration enforces persistent NFS automounts on boot via `fstab`.

## Deployment Architecture

### Environments
- **Local**: Local dev machine executing `Makefile` instructions and holding terraform workspaces.
- **Shared Hub**: Centralized infrastructure containing the management Jumpbox, backup NFS, and Vault.
- **Preprod Spoke**: Workload environment for QA/staging workloads.
- **Prod Spoke**: Hardened workload environment with high-availability configurations.

### Security and Compliance
- **AuthN/AuthZ model**: SSH key-based access to the Jumpbox. Jenkins login uses administrative credentials with TLS.
- **Secret management**: Dynamic retrieval from Azure Key Vault using VM User-Assigned Managed Identity (zero secrets stored in git).
- **Input validation boundaries**: Checked at Front Door WAF and validated by Apache server configurations.

## Architecture Decision Records (ADR-lite)

### Decision: ADR-001 (Hub-Spoke Network Topology)
- **Status**: Accepted
- **Context**: Management traffic and backups must be separate from web traffic.
- **Decision**: Hub VNet will contain administrative nodes (Jumpbox, Vault, backups share). Spoke VNets will contain web VMs and databases. Communication is peering-only.
- **Requirement links**: NFR-003, FR-004
- **Alternatives considered**: Single flat VNet (rejected due to lack of network boundary security).

### Decision: ADR-002 (Azure NetApp Files for Shared Storage)
- **Status**: Accepted
- **Context**: Shared hosting compute nodes must concurrently access the same web directories with low-latency and high throughput.
- **Decision**: Use Azure NetApp Files volume (`/netappwebsites`) mounted via NFS v4.1.
- **Requirement links**: NFR-002, FR-001
- **Alternatives considered**: Azure Files NFS (satisfactory for backups, but NetApp has superior sub-millisecond latency for live site requests).

### Decision: ADR-003 (Zero-Trust Key Vault Integration)
- **Status**: Accepted
- **Context**: MySQL passwords, TLS keys, and configurations must be securely retrieved during deployment and provisioning.
- **Decision**: Provision a User-Assigned Managed Identity for the Jumpbox VM, giving it secret reader access to Key Vault. Ansible uses `azure.azcollection` to query AKV secrets dynamically at runtime.
- **Requirement links**: NFR-001, FR-003

## Requirement to Design Mapping

| Requirement ID | Architectural Element | ADR ID | Notes |
| -------------- | --------------------- | ------ | ----- |
| FR-001 | Web Compute Fleet | ADR-002 | Uses Ubuntu VMs and NetApp files |
| FR-002 | Front Door & Load Balancer | ADR-001 | Global and regional traffic management |
| FR-003 | Management Jumpbox & Jenkins | ADR-003 | Automates tasks with secure credential injection |
| FR-004 | MySQL Flexible Server | ADR-001 | Private subnet and Private DNS zoning |
| NFR-001 | User-Assigned Managed Identity | ADR-003 | Zero credentials stored on disk |
| NFR-002 | Azure NetApp Volume | ADR-002 | Low-latency shared hosting backend |
| NFR-003 | Hub-Spoke VNet Peering | ADR-001 | Enforces management-workload segregation |
