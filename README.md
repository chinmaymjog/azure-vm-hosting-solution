# Azure Shared Hosting Platform (Hardened)

A modular, enterprise-grade Infrastructure-as-Code (IaC) repository for deploying a shared hosting platform on Azure. This project implements a **Hub-Spoke** architecture with a centralized **Management Jumpbox**, hardened compute nodes, and a multi-tier storage strategy.

## 🏗️ Architecture
- **Global Ingress**: Azure Front Door (AFD) with WAF for edge security.
- **Load Balancing**: Standard Public Load Balancer for regional traffic.
- **Compute**: Hardened Ubuntu VMs in a private subnet, scaleable via `vm_count`.
- **Management Hub**: Centralized VNet with a Jumpbox and shared services.
- **Multi-Tier Storage**:
    - **NetApp Volume (Websites)**: High-performance NFS v4.1 for shared web assets (Provisioned per Environment).
    - **Azure Files NFS (Backups)**: Centralized, durable Premium NFS share for backups (Provisioned in Shared Hub).
    - **Managed Data Disk**: Local LVM-partitioned storage for application-specific data.
- **Database**: Azure MySQL Flexible Server with Private DNS integration.
- **Secret Management**: Centralized **Azure Key Vault** in the Hub for zero-knowledge password and certificate storage.

## 📁 Repository Structure
```text
.
├── automation/
│   ├── ansible/        # Core infrastructure playbooks and logic
│   └── jenkins/        # Preconfigured Jenkins container and jobs
├── terraform/
│   ├── shared-hub/     # Shared Management, Backup, & Secret Plane (Jumpbox, Vault, NFS)
│   └── platform/       # Application Environment (Spoke: Web, DB, NetApp)
├── Makefile            # Simplified operational entry point
└── HOW_TO_GUIDE.md     # Step-by-step deployment instructions
```

## 🛡️ Hardened Security Architecture
- **Zero-Trust Identity**: The Jumpbox utilizes a **User-Assigned Managed Identity** to fetch database secrets from Azure Key Vault at runtime. No static DB credentials ever touch the disk.
- **Hub-Spoke Networking**: Total isolation between management (Hub) and workloads (Spokes), connected via private peering.
- **Private DNS Integration**: Cross-VNet DNS linking ensures that the management Jumpbox and Web fleet resolve internal resources via a single source of truth.

## ⚡ High-Performance Storage
- **Azure NetApp Files**: All web applications are served from a high-performance NetApp mount (`/netappwebsites`), ensuring enterprise-grade IOPS and latency for shared hosting environments.
- **Durable Backups**: Integrated NFS backup rotation to a central, geo-redundant storage account.

---
*For detailed instructions, see the [HOW_TO_GUIDE.md](./HOW_TO_GUIDE.md).*

---
*Maintained by [Chinmay Jog](https://github.com/chinmaymjog) | 📖 [Read my articles on Medium](https://medium.com/@chinmaymjog)*
