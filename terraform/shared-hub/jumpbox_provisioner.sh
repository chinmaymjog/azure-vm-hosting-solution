#!/bin/bash
set -e

## Provisioner log file
logfile=/var/log/provisioner.log
log() {
    echo "$(date +'%Y-%m-%d %H:%M:%S') $1" | sudo tee -a "$logfile"
}

log "Starting Jumpbox Hardening"

# 1. Update and install security tools
export DEBIAN_FRONTEND=noninteractive
log "Updating OS and installing security packages"
apt-get update -qq
apt-get install -y fail2ban ufw unattended-upgrades nfs-common bash-completion -qq

# 1.1 Install Ansible and Management Tools
log "Installing Ansible and Azure CLI"
apt-get install -y software-properties-common curl apt-transport-https lsb-release gnupg -qq

# Add Microsoft GPG key and Repository
curl -sL https://packages.microsoft.com/keys/microsoft.asc | gpg --dearmor | tee /etc/apt/trusted.gpg.d/microsoft.gpg > /dev/null
AZ_REPO=$(lsb_release -cs)
echo "deb [arch=amd64] https://packages.microsoft.com/repos/azure-cli/ $AZ_REPO main" | tee /etc/apt/sources.list.d/azure-cli.list

# Add Ansible PPA
add-apt-repository --yes --update ppa:ansible/ansible

# Install Tools
apt-get update -qq
apt-get install -y ansible azure-cli python3-pip python3-pymysql -qq

# 1.2 Install Docker and Docker Compose
log "Installing Docker and Docker Compose"
apt-get install -y docker.io docker-compose-v2 -qq
systemctl enable docker
systemctl start docker
usermod -aG docker azureuser

# Install Azure Ansible Collection (for Key Vault lookups)
log "Installing Azure Ansible Collections"
sudo -u azureuser ansible-galaxy collection install azure.azcollection
# Note: We pip install as root to ensure libraries are available for become tasks
pip3 install msal msal-extensions azure-identity azure-keyvault-secrets azure-mgmt-compute azure-mgmt-network azure-mgmt-resource --quiet

# 2. Mount Shared Backups (Azure Files NFS)
log "Configuring Shared Backups Mount (${backup_nfs_host})"
mkdir -p /backups

# Remove any existing (potentially broken) /backups entries
sed -i '/\/backups/d' /etc/fstab

# Add the correct, dynamic entry
log "Adding fresh fstab entry for ${storage_account_name}"
echo "${backup_nfs_host}:/${storage_account_name}/backups /backups nfs nfsvers=4.1,hard,timeo=600,retrans=2,_netdev 0 0" | tee -a /etc/fstab

# Unmount if already partially mounted, then mount all
umount /backups || true
mount -a

# 3. System Policy
log "Setting secure UMASK"
echo "umask 027" | tee -a /etc/profile

# 4. Banner
log "Creating security banner"
cat <<EOF > /etc/mybanner
########################################################################
# Authorized access only!
# This system is monitored. Unauthorized access is strictly prohibited.
########################################################################
EOF

# 5. Configure UFW (Firewall)
log "Configuring Firewall"
ufw default deny inbound
ufw default allow outbound
ufw allow 22/tcp
ufw --force enable

# 6. Harden SSH
log "Securing SSH"
cat <<EOF > /etc/ssh/sshd_config
AuthorizedKeysFile .ssh/authorized_keys
Protocol 2
Banner /etc/mybanner
PermitRootLogin no
PasswordAuthentication no
PermitEmptyPasswords no
MaxAuthTries 3
ClientAliveInterval 300
ClientAliveCountMax 2
X11Forwarding no
Subsystem sftp /usr/lib/openssh/sftp-server
UsePAM yes
EOF
systemctl restart ssh

# 7. Fail2Ban configuration
log "Configuring Fail2Ban"
cat <<EOF > /etc/fail2ban/jail.local
[sshd]
enabled = true
port = ssh
filter = sshd
logpath = /var/log/auth.log
maxretry = 3
bantime = 3600
EOF
systemctl restart fail2ban

# 8. Enable Unattended Upgrades
log "Enabling automatic security updates"
systemctl enable unattended-upgrades
systemctl start unattended-upgrades

log "Jumpbox Hardening and Backup Mount Complete."
