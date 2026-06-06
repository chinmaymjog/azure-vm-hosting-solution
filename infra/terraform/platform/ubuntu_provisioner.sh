#!/bin/bash
set -e

# Template Variables from Terraform
NETAPP_IP="${netapp_ip}"
NETAPP_PATH="${netapp_path}"

## Provisioner log file
logfile=/var/log/provisioner.log
log() {
    echo "$(date +'%Y-%m-%d %H:%M:%S') $1" | sudo tee -a "$logfile"
}

log "Starting Web Server Provisioning"

# --- 1. OS Preparation ---
export DEBIAN_FRONTEND=noninteractive
log "Updating OS and installing core packages"
apt-get update -qq
apt-get install -y fail2ban lvm2 nfs-common xfsprogs ufw unattended-upgrades bash-completion -qq

# --- 2. Data Disk Configuration (/data) ---
log "Configuring Data Disk (/dev/sdc)"
while [ ! -b /dev/sdc ]; do
    log "Waiting for /dev/sdc..."
    sleep 5
done

if ! blkid /dev/sdc; then
    log "Creating LVM on /dev/sdc"
    pvcreate /dev/sdc
    vgcreate data_vg /dev/sdc
    lvcreate -l 100%FREE -n data_lv data_vg
    mkfs.xfs /dev/data_vg/data_lv
fi

mkdir -p /data
if ! grep -q "/data" /etc/fstab; then
    log "Adding /data to /etc/fstab"
    echo "/dev/data_vg/data_lv /data xfs defaults 0 0" | tee -a /etc/fstab
fi
mount -a

# --- 3. NetApp Shared Storage Configuration ---
if [ ! -z "$NETAPP_IP" ]; then
    # Websites Volume
    log "Configuring NetApp Websites Mount ($NETAPP_IP:$NETAPP_PATH)"
    mkdir -p /netappwebsites
    if ! grep -q "/netappwebsites" /etc/fstab; then
        echo "$NETAPP_IP:/$NETAPP_PATH /netappwebsites nfs nfsvers=4.1,hard,timeo=600,retrans=2,_netdev 0 0" | tee -a /etc/fstab
    fi

    # Backups Volume (Shared Hub NFS)
    log "Configuring Shared Hub Backups Mount (${backup_nfs_host})"
    mkdir -p /backups
    
    # Clean up old entries
    sed -i '/\/backups/d' /etc/fstab
    
    # Add fresh entry
    echo "${backup_nfs_host}:/${storage_account_name}/backups /backups nfs nfsvers=4.1,hard,timeo=600,retrans=2,_netdev 0 0" | tee -a /etc/fstab
    
    umount /backups || true
    mount -a
    
    # Ensure Apache (www-data) has execute permissions to traverse the mount point
    chmod 755 /netappwebsites
fi

# --- 4. System Hardening (Aligned with Jumpbox) ---
log "Applying System Hardening"

# Set secure UMASK
echo "umask 027" | tee -a /etc/profile

# Security Banner
cat <<EOF > /etc/mybanner
########################################################################
# Authorized access only!
# This system is monitored. Unauthorized access is strictly prohibited.
########################################################################
EOF

# SSH Hardening
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

# Firewall
log "Configuring UFW"
ufw default deny inbound
ufw default allow outbound
ufw allow 22/tcp
ufw allow 80/tcp
ufw allow 443/tcp
ufw --force enable

# Fail2Ban
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

# Auto-Updates
log "Enabling automatic security updates"
echo 'Unattended-Upgrade::Allowed-Origins { "$${distro_id}:$${distro_codename}-security"; };' > /etc/apt/apt.conf.d/50unattended-upgrades
systemctl enable unattended-upgrades
systemctl start unattended-upgrades

log "Web Server Provisioning Complete."