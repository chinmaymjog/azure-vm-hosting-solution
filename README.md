# ☁️ Azure VM-Based Hosting Solution

**Azure VM-Based Hosting Solution** is a production-ready, automated blueprint for deploying and managing high-performance web hosting environments on Azure Virtual Machines.

---

## 💡 Why this project?

> "While Kubernetes is the gold standard for cloud-native apps, many businesses require a simpler, more cost-effective way to host traditional web stacks. I built this solution to prove that VM-based hosting can be just as automated, secure, and scalable as modern container platforms—at a fraction of the complexity."

---

## ✨ Key Features

*   **Infrastructure as Code**: Modular Terraform templates for standalone VMs and auto-scaling VMSS.
*   **Automated Hardening**: Ansible playbooks that implement CIS-lite security standards from the first boot.
*   **Application Lifecycle**: One-command deployment of the WordPress stack (LEMP).
*   **Data Durability**: Integrated backup scripts for Azure Blob Storage.
*   **Unified Workflow**: A minimalist `Makefile` entry point for both IaC and Config Management.

---

## 🏗️ Quick Start

### 1. Requirements
*   **Terraform**: 1.5+
*   **Ansible**: 2.15+
*   **Azure CLI**: Logged in via `az login`.

### 2. Deploy Infrastructure
```bash
make infra-init
make infra-apply
```

### 3. Configure & Harden
```bash
# Update ansible/inventory.ini with your VM IP
make ansible-prep
make ansible-deploy
```

---

## 📖 Documentation
For detailed deployment steps and operational guidance, check the:
- 👉 **[Comprehensive User Guide](./HOW_TO_GUIDE.md)**
- 👉 **[Technical Deep-Dive Article](./docs/posts/azure-vm-hosting-article.md)**

## 🤝 Contributing
Contributions are welcome! Please see the **[Contribution Guidelines](./CONTRIBUTING.md)** for details.

## 🛡️ Security
This solution prioritizes OS hardening, including SSH lockdown, firewall management, and automated security patching. Infrastructure is deployed following the principle of least privilege.

---
*Maintained by [Chinmay Jog](https://github.com/chinmaymjog)*
