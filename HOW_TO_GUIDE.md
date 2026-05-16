# 📖 Deployment Guide: Azure VM Hosting Solution

This guide provides step-by-step instructions on how to provision, harden, and deploy a web hosting stack on Azure Virtual Machines.

---

## 🏗️ Step 1: Provisioning Infrastructure (Terraform)

The infrastructure layer creates the Virtual Network, Security Groups, and the Virtual Machine itself.

1.  **Configure Azure CLI**:
    ```bash
    az login
    ```
2.  **Initialize Terraform**:
    ```bash
    cd infra
    terraform init
    ```
3.  **Deploy**:
    ```bash
    terraform apply
    ```
    *Note: Note down the Public IP address from the output.*

---

## 📜 Step 2: Server Preparation (Ansible)

Once the VM is running, we use Ansible to harden the OS and prepare the environment.

1.  **Create Inventory**:
    Create a file named `ansible/inventory.ini`:
    ```ini
    [webservers]
    your_vm_ip_here ansible_user=ubuntu ansible_ssh_private_key_file=~/.ssh/id_rsa
    ```
2.  **Run Prep Playbook**:
    ```bash
    make ansible-prep
    ```
    This playbook will:
    *   Update system packages.
    *   Harden SSH configuration.
    *   Enable UFW Firewall (80, 443, 22).
    *   Set up automated security updates.

---

## 🚀 Step 3: Deploying the Application

Now we deploy the full WordPress stack (Nginx, PHP-FPM, MySQL).

1.  **Run Deploy Playbook**:
    ```bash
    make ansible-deploy
    ```
2.  **Verify**:
    Visit `http://your_vm_ip_here` in your browser.

---

## 🛡️ Operational Maintenance

### Backups
The solution includes a script to backup the database and assets to Azure Blob Storage.
1.  **Setup Storage**: Ensure an Azure Storage Account is available.
2.  **Run Backup**:
    ```bash
    cd ansible/scripts
    ./backup_to_blob.sh
    ```

### Scaling
To switch from a standalone VM to a Scale Set (VMSS), use the `arm_virtual_machine_scale_set.tf` template in the `infra` directory.

---
*Maintained by [Chinmay Jog](https://github.com/chinmaymjog)*
