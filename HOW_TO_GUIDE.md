# 🚀 Deployment Guide: Azure Shared Hosting Platform

This guide covers the end-to-end deployment of the hardened architecture, from initial Azure setup to final Ansible configuration.

---

## 🛠️ Step 0: Preparation

### 0.1 Azure Authentication
Ensure you are logged in and have the correct subscription set:
```bash
az login
az account set --subscription "YOUR_SUBSCRIPTION_ID"
```

### 0.2 Project Branding & State Setup
Choose a project prefix (e.g., `myhosting new`) to brand your Azure resources:
```bash
export PROJECT_NAME="myhosting new"
```

To prevent global naming conflicts on Azure (since Storage Account names must be globally unique) and ensure absolute compatibility with resource naming rules, we automatically sanitize and persist your configuration. 

Run the setup command to initialize your configuration:
```bash
make setup
```
This will automatically:
1. Strip all non-alphanumeric characters and spaces from your project name (e.g., `myhosting new` becomes `myhostingnew`).
2. Generate a unique backend storage account name (e.g., `stmyhostingnew1a2b3c`).
3. Save both the cleaned `PROJECT_NAME` and `TF_STATE_STORAGE` to your local `.env` file.

The `Makefile` and Terraform will automatically load these variables from `.env` in all future runs, ensuring you never have to export `PROJECT_NAME` again!

---

### 0.3 Zero-Trust Preparation
You no longer need to generate SSH keys manually. The platform now automatically generates a secure key pair and vaults it in Azure during the Hub deployment.

---

---

## 📦 Step 1: Bootstrap State Storage (Once)
Terraform needs a secure place to store its state before it can begin.

```bash
make bootstrap
```
This will securely execute the Azure CLI commands in the background using your unique project prefix, creating the resource group, storage account, and state blob container.

---

## 🏗️ Step 2: Infrastructure Deployment (Terraform)

### 2.1 Shared Management & Backup Hub
The Hub contains the Jumpbox, the management network, and the Shared Backup Share. It persists across environment cycles.
```bash
# Initialize and link to your state storage
make hub-init

### 1.2 Deploy the Shared Hub
This step creates your management network, the Ansible Jumpbox, your backup storage, and **generates your secure SSH keys**.

```bash
make hub-deploy
```

**⚠️ IMPORTANT: Download your Private Key**
After the hub is deployed, you must download the generated private key from the Key Vault to access your VMs:
```bash
# Replace <VAULT_NAME> with the one shown in your hub-deploy output (e.g. kv-shrdhosting-...)
az keyvault secret download --name ssh-private-key --vault-name <VAULT_NAME> --file ssh-key
chmod 600 ssh-key
```
*Note: The output will provide the `ssh_command_jumpbox`.*

### 2.2 Platform Spokes (Environments)
Deploy isolated environments (e.g., `preprod`, `prod`) using Workspaces.
```bash
# Initialize the platform layer
make infra-init

# Deploy Preprod
make infra-preprod
```

---

## 🚀 Phase 3: Jenkins Automation & Platform Configuration
Now that the "Hardware" is ready, we use a containerized Jenkins Management Portal to drive our Ansible configurations securely.

### 3.1 Sync & Spin Up Jenkins
1.  **Sync Automation Stack**: Push your Jenkins configuration and Ansible playbooks to the Jumpbox. This automatically generates a dynamic inventory for all active environments.
    ```bash
    make jenkins-sync
    ```
2.  **Spin Up Jenkins**: Securely pass your private SSH key in-memory and start the Jenkins portal on the Jumpbox.
    ```bash
    make jenkins-up
    ```

### 3.2 Access the Hosting Management Portal
To securely access the Jenkins portal without exposing port 8080 to the public internet, use SSH Port Forwarding:
```bash
# Get the Jumpbox IP from terraform output in the shared-hub directory
ssh -L 8080:localhost:8080 -i ./ssh-key azureuser@<JUMPBOX_IP>
```
1. Open your browser and navigate to `http://localhost:8080`
2. **Username:** `admin`
3. **Password:** `SecureAdminPassword2026!`

### 3.3 Configure & Onboard Sites via UI
You no longer need to run raw Ansible commands! Inside Jenkins:
- Navigate to the **Hosting Management Portal** folder.
- Run the **Setup Web Stack** job to install Nginx and PHP across your environments using the dynamic dropdowns.
- Run the **Onboard Site** job to automatically provision databases, users, VHosts, and NetApp directories via a simple UI!

### 3.3 Deploy Your Code
Once onboarded, deploy your code directly to the high-performance NetApp volume:
```bash
# Example: Deploying a static/PHP app
scp -i ./ssh-key -r ./my-code/* azureuser@<VM_IP>:/netappwebsites/<SITE_NAME>/public/
```

### 3.4 Test Your Site
Since we haven't configured public DNS yet, you can test your site by adding an entry to your local machine's hosts file:
1.  **Get the Front Door IP** or the **Load Balancer Public IP**.
2.  **Add to `/etc/hosts` (macOS/Linux)**:
    ```bash
    <PUBLIC_IP>  mysite.preprod.local
    ```
3.  **Visit**: `http://mysite.preprod.local` in your browser.

---

## 💾 Storage Layout Reference
- **`/netappwebsites`**: (NetApp NFS) High-performance volume for application code.
- **`/backups`**: (Azure Files NFS) Centralized repository in the Hub.
- **`/data`**: (LVM Disk) Local persistent storage for cache/logs.

## 🔐 Secret Management & Access
The platform uses **Azure Key Vault** to manage all sensitive information.
- **Passwords**: Generated randomly during `make hub-deploy`.
- **SSH Keys**: The private key is generated by Terraform and stored in the Vault. No local `ssh-key` file is needed for deployment.
- **Retrieval**: To log in, you must download the private key from your Vault:
    ```bash
    # Get your Vault Name from the hub-deploy output
    az keyvault secret download --name ssh-private-key --vault-name <VAULT_NAME> --file ssh-key-new
    chmod 600 ssh-key-new
    ```
- **Access**: Only authorized users and service principals can read secrets. You can view the generated DB password in the Azure Portal under the `kv-shrdhosting-...` resource.

> [!IMPORTANT]
> **Vault Firewall**: The Key Vault is hardened with a network firewall. Your current public IP is automatically whitelisted during `make hub-deploy`. If your IP changes, you will need to re-run the command to regain access.

## 🛡️ Verification Checklist
- [ ] **Connectivity**: Access site via `frontdoor_url`.
- [ ] **Secrets**: Verify the Database was created using the secret from Key Vault.
- [ ] **Hardening**: Check `/var/log/provisioner.log` on any VM.
- [ ] **Storage**: Verify `/backups` mount on Jumpbox and Web VMs.
