# 📖 Site Management Guide
## Provisioning Tenants, Web Configurations, and Verification

This guide details the operational runbook of the shared web hosting architecture. It provides clear, actionable instructions for provisioning web servers, onboarding new sites (via Jenkins or CLI), and verified secure access testing.

---

## 🏗️ 1. Web Server Provisioning & Environment Setup

Before adding individual hosting sites, the underlying Apache/PHP-FPM web server cluster must be configured and hardened.

### A. Run Server Configuration via Makefile
From the root of the repository, execute the following command to run the Ansible provisioning playbook against the target web VMs:
```bash
# Installs Apache2, PHP-FPM, security modules, systemd configurations, and GID structures
make jenkins-sync
# Execute the "configure_web_server" Job in Jenkins to trigger the playbook
```

### B. What is Provisioned
The Ansible playbook ([`server_web_configuration.yml`](infra/ansible/playbooks/server_web_configuration.yml)) establishes:
* **Web Stack:** Apache2 (`mpm_event` mode) + PHP-FPM integration via `mod_fcgid` and `proxy_fcgi`.
* **Security & Hardening:** Enforces TLS redirect rules, registers systemd template units for isolated multi-PHP environments, and locks down directory permissions.
* **Shared Storage Structure:** Mounts and configures the distributed NetApp fileshare path under:
  📁 `/netappwebsites/`
* **Isolated Group Permissions:** Restricts access using the `web_users` system group and strict GID propagation rules on document roots.

---

## 🚀 2. Onboarding New Sites

Adding a new shared website provisions an isolated database, a dedicated database user, secure NetApp web directories, and a matching Apache Virtual Host configuration.

### Method A: Using the Hosting Management Portal (Jenkins) — *Recommended*
1. Open your browser and navigate to the portal:
   * Start an SSH tunnel to the Jumpbox:
     ```bash
     ssh -L 8080:localhost:8080 -i ./ssh-key azureuser@<JUMPBOX_IP>
     ```
   * Open **[http://localhost:8080](http://localhost:8080)**
2. Log in using your admin credentials.
3. Under the **Hosting Management Portal** folder, select the **`site_add`** Job.
4. Click **Build with Parameters** and input:
   * **`site_url`**: The fully qualified domain of the site (e.g., `mysharedsite.com`).
   * **`php_version`**: Select the targeted PHP runtime (e.g., `php8.1` or `php8.2`).
5. Click **Build**. The pipeline will:
   * Bootstrap the isolated MySQL Database on the Azure Database for MySQL Flexible Server.
   * Generate secure system credentials and write them to the encrypted site register.
   * Establish isolated NetApp directories and deploy a default `index.php` welcome page.
   * Deploy the Apache Virtual Host configuration and hot-reload Apache across the web VM cluster.

### Method B: Manual CLI Run (Ansible)
If you need to trigger onboarding directly from the Jumpbox VM command line:
```bash
ansible-playbook -i /etc/ansible/hosts /etc/ansible/playbooks/php_site_add.yml \
  --extra-vars "site_url=mysharedsite.com php_version=php8.1"
```

---

## 🔒 3. Secure Verification & Access Testing

Because Azure Front Door (AFD) requires DNS TXT validation before routing custom domains, you can verify your sites instantly using **Direct-to-Load-Balancer Routing**.

### ⚡ 1. Rapid Command Line Verification (cURL)
To bypass Front Door and test the raw Apache Virtual Host matching immediately, send a request directly to the **Public Load Balancer IP** while overriding the HTTP `Host` header:

```bash
curl -i -H "Host: <your-new-site-url>" http://<LOAD_BALANCER_PUBLIC_IP>
```
*Example:*
```bash
curl -i -H "Host: mysharedsite.com" http://<LOAD_BALANCER_PUBLIC_IP>
```
*(If successful, you will receive an HTTP `200 OK` response with the custom HTML signature containing your site slug and PHP version!)*

---

### 🖥️ 2. Full Browser Validation (Local Hostfile Override)
To access and test your shared website interactively in a web browser without buying a domain or configuring DNS records:

1. **Open your local Mac hostfile with administrative privileges:**
   ```bash
   sudo nano /etc/hosts
   ```
2. **Add a local DNS map pointing your site's domain directly to the Load Balancer IP:**
   ```text
   <LOAD_BALANCER_PUBLIC_IP>   <your-new-site-url>
   ```
   *(For example: `<LOAD_BALANCER_PUBLIC_IP> mysharedsite.com`)*
3. **Save and Exit** (`Ctrl + O`, `Enter`, then `Ctrl + X`).
4. **Open your web browser and navigate directly to:**
   👉 **`http://<your-new-site-url>`**

---

### 🌐 3. Production Deployment (Adding Custom Domains to Front Door)
To expose your website publicly to the open internet through the Azure Front Door Edge WAF, update your Terraform configuration in [`frontdoor.tf`](infra/terraform/platform/frontdoor.tf):

1. **Register the custom domain resource:**
   ```terraform
   resource "azurerm_cdn_frontdoor_custom_domain" "site_domain" {
     name                     = "mysharedsite-domain"
     cdn_frontdoor_profile_id = azurerm_cdn_frontdoor_profile.afd.id
     host_name                = "mysharedsite.com"
     
     tls {
       certificate_type    = "ManagedCertificate"
       minimum_tls_version = "TLS12"
     }
   }
   ```
2. **Bind the domain to the default route:**
   ```terraform
   resource "azurerm_cdn_frontdoor_route" "route" {
     # ... other route settings ...
     cdn_frontdoor_custom_domain_ids = [
       azurerm_cdn_frontdoor_custom_domain.site_domain.id
     ]
   }
   ```
3. **Apply the Terraform change:**
   ```bash
   cd infra/terraform/platform && terraform apply -var-file="environments/preprod.tfvars" -auto-approve
   ```
4. **DNS Activation:** In your DNS registrar (e.g., GoDaddy, Cloudflare), add the dynamic `_dnsauth` TXT record generated in your Azure Portal to complete Front Door ownership validation.
