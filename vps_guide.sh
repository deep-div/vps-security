############################################
# VPS SETUP GUIDE (Ubuntu)
# Placeholders:
#   <username>          = your new sudo user
#   <server-ip>         = your VPS IP address
#   yourdomain.com      = your domain
#   <your-windows-user> = your Windows account name
#
# TIP: keep your current SSH session open while changing SSH settings,
# and test each change in a SECOND terminal before closing the first.
# That way a typo can't lock you out.
############################################


############################################
# Step 0: First Login and System Update   [NEW]
############################################
# login as root for the first time (run from local)
ssh root@<server-ip>
# update the system
apt update && apt upgrade -y


############################################
# Step 1: Create a New User
############################################
# add new user
adduser <username>
# give sudo access to that user
usermod -aG sudo <username>
# switch to new user
su - <username>
# test sudo access for new user
sudo whoami
sudo apt update


############################################
# Step 1.1: Timezone and Time Sync   [NEW]
############################################
# check current time settings
timedatectl status
# set timezone (example: UTC, or Asia/Kolkata)
sudo timedatectl set-timezone UTC
# make sure NTP time sync is on (needed for SSL certs and logs)
sudo timedatectl set-ntp true


############################################
# Step 2: Disable Root Login
# Allowing root login via SSH is a security risk. Use the new user
# from Step 1 to log in and perform administrative tasks instead.
############################################
# verify new user SSH login (run from local)
ssh <username>@<server-ip>
# open SSH config
sudo nano /etc/ssh/sshd_config
# change PermitRootLogin yes to no
PermitRootLogin no
# [NEW] test the config for typos BEFORE restarting (no output = OK)
sudo sshd -t
# restart SSH service
sudo systemctl restart ssh


############################################
# Step 2.1: Change Default SSH Port
############################################
# open SSH config, press Ctrl+W and search for Port 22
sudo nano /etc/ssh/sshd_config
# change Port 22 to something else, for example Port 2222
Port 2222
# allow 2222 in the firewall BEFORE restarting SSH
sudo ufw allow 2222/tcp
# test config, then restart SSH service
sudo sshd -t
sudo systemctl restart ssh
# [NEW] confirm SSH is really listening on 2222
sudo ss -tlnp | grep ssh
# [NEW] Ubuntu 24.04+ ONLY: if SSH still listens on 22, it is because of
# socket activation. Fix it with:
#   sudo systemctl disable --now ssh.socket
#   sudo systemctl enable --now ssh
# test new SSH port in a NEW terminal (run from local)
ssh -p 2222 <username>@<server-ip>


############################################
# Step 3: SSH Key Setup
############################################
# generate SSH key (local machine), press Enter three times, do not give any extra paths
ssh-keygen -t ed25519
# copy public key (Windows)
type C:\Users\<your-windows-user>\.ssh\id_ed25519.pub

# create ssh directory on VPS
mkdir -p ~/.ssh
# paste public key
nano ~/.ssh/authorized_keys
# set correct permissions
chmod 700 ~/.ssh
chmod 600 ~/.ssh/authorized_keys

# [NEW] ALTERNATIVE to the manual paste above (Windows PowerShell, run from local):
# type $env:USERPROFILE\.ssh\id_ed25519.pub | ssh -p 2222 <username>@<server-ip> "mkdir -p ~/.ssh && cat >> ~/.ssh/authorized_keys"

# login using SSH key, it should not ask for password now
# [UPDATED] added -p 2222 since the port was changed
ssh -p 2222 -i C:\Users\<your-windows-user>\.ssh\id_ed25519 <username>@<server-ip>

# [NEW] OPTIONAL: create a shortcut so you never type the port or key again.
# Create/edit this file on your local machine:
#   C:\Users\<your-windows-user>\.ssh\config
# and add:
#   Host myvps
#       HostName <server-ip>
#       User <username>
#       Port 2222
#       IdentityFile ~/.ssh/id_ed25519
# Then login simply with:
ssh myvps


############################################
# Step 4: Disable Password Login
# Only do this AFTER confirming key login works in Step 3!
############################################
# open SSH config
sudo nano /etc/ssh/sshd_config
# search using Ctrl+W for PasswordAuthentication
# change PasswordAuthentication yes to no
PasswordAuthentication no
# [NEW] extra hardening (add or edit these lines in the same file)
KbdInteractiveAuthentication no
PermitEmptyPasswords no
MaxAuthTries 3
X11Forwarding no
AllowUsers <username>
# check if the change is correct
sudo sshd -T | grep passwordauthentication
# if not, also change here
sudo nano /etc/ssh/sshd_config.d/50-cloud-init.conf
# [NEW] test config, then restart SSH
sudo sshd -t
sudo systemctl restart ssh
# [NEW] test from a NEW terminal that key login still works
ssh -p 2222 <username>@<server-ip>


############################################
# Step 5: Firewall
############################################
# install ufw (firewall)
sudo apt install ufw -y
# fix broken packages (if any error earlier)
sudo apt --fix-broken install -y
# update system
sudo apt update && sudo apt upgrade -y
# [NEW] default policy: block all incoming, allow all outgoing
sudo ufw default deny incoming
sudo ufw default allow outgoing
# allow SSH (IMPORTANT before enabling firewall)
sudo ufw allow OpenSSH
# [NEW] allow your custom SSH port (if not already done in Step 2.1)
sudo ufw allow 2222/tcp
# allow HTTP (port 80)
sudo ufw allow 80
# allow HTTPS (port 443)
sudo ufw allow 443
# enable firewall
sudo ufw enable
# check firewall status
sudo ufw status verbose
# [NEW] once login on port 2222 works, close the old port 22:
sudo ufw delete allow OpenSSH
sudo ufw status numbered


############################################
# Step 6: Fail2Ban Against Brute-Force Attacks
############################################
# install fail2ban
sudo apt install fail2ban -y
# [NEW] tell Fail2Ban about the custom SSH port (default only watches 22)
sudo tee /etc/fail2ban/jail.local > /dev/null <<'EOF'
[sshd]
enabled = true
port = 2222
maxretry = 5
findtime = 10m
bantime = 1h
EOF
# enable fail2ban service on startup
sudo systemctl enable fail2ban
# start (or restart to load jail.local)
sudo systemctl restart fail2ban
# check fail2ban status
sudo systemctl status fail2ban
# (optional) check banned IPs
sudo fail2ban-client status
# (optional) check SSH jail specifically
sudo fail2ban-client status sshd


############################################
# Step 6.1: Lynis Security Auditing
############################################
sudo apt install lynis -y
sudo lynis audit system


############################################
# Step 7: Install Docker   [UPDATED]
# Uses Docker's current official method (apt-key is deprecated,
# and the release name is no longer hardcoded to "jammy").
############################################
# install required packages
sudo apt install ca-certificates curl -y
# add Docker GPG key
sudo install -m 0755 -d /etc/apt/keyrings
sudo curl -fsSL https://download.docker.com/linux/ubuntu/gpg -o /etc/apt/keyrings/docker.asc
sudo chmod a+r /etc/apt/keyrings/docker.asc
# add Docker repository (auto-detects your Ubuntu version)
echo "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.asc] https://download.docker.com/linux/ubuntu $(. /etc/os-release && echo "${UBUNTU_CODENAME:-$VERSION_CODENAME}") stable" | sudo tee /etc/apt/sources.list.d/docker.list > /dev/null
# update packages
sudo apt update
# install Docker (includes Compose and Buildx plugins)
sudo apt install docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin -y
# start Docker
sudo systemctl start docker
# enable Docker on boot
sudo systemctl enable docker
# verify Docker
docker --version
docker compose version
# [NEW] run docker without sudo (log out and back in afterwards)
# NOTE: members of the docker group effectively have root access.
sudo usermod -aG docker <username>
# [NEW] test Docker
docker run hello-world
# [NEW] WARNING: ports published by Docker (-p 8080:80) BYPASS UFW rules.
# Bind to localhost if a port should not be public: -p 127.0.0.1:8080:80


############################################
# Step 8: Enable Automatic Security Updates
############################################
sudo apt install unattended-upgrades -y
sudo dpkg-reconfigure --priority=low unattended-upgrades
# [NEW] verify it works (dry run)
sudo unattended-upgrade --dry-run --debug


############################################
# Step 8.1: Swap Setup
############################################
# create 2GB swap file
sudo fallocate -l 2G /swapfile
# set correct permissions (security)
sudo chmod 600 /swapfile
# format it as swap
sudo mkswap /swapfile
# enable swap
sudo swapon /swapfile
# make it permanent (survives reboot)
echo '/swapfile none swap sw 0 0' | sudo tee -a /etc/fstab
# set swappiness (use swap less, keep system fast)
sudo sysctl vm.swappiness=10
# make swappiness permanent
echo 'vm.swappiness=10' | sudo tee -a /etc/sysctl.conf
# [NEW] verify swap is active
swapon --show
free -h


############################################
# Step 9: Setup SSL Certificates
############################################
# RUN LOCALLY: the domain should point to your VPS IP address.
# Go to your domain's DNS settings and add A records (for @ and www) with your VPS IP.
ping yourdomain.com

sudo apt update
sudo apt install certbot -y
# NOTE: --standalone needs port 80 free (stop nginx/apache first if running)
sudo certbot certonly --standalone -d yourdomain.com -d www.yourdomain.com
# [NEW] certificates are saved in:
#   /etc/letsencrypt/live/yourdomain.com/
# [NEW] check auto-renewal timer and test renewal
sudo systemctl status certbot.timer
sudo certbot renew --dry-run


############################################
# Step 9.1: Reboot Test   [NEW]
# Confirms everything (SSH port, firewall, Docker, swap) survives a restart.
############################################
sudo reboot
# wait about a minute, then login again (run from local)
ssh -p 2222 <username>@<server-ip>


############################################
# Step 10: Final Check
############################################
echo "---- VPS SECURITY CHECK ----" && \
echo "[User]" && whoami && \
echo "[Sudo Access]" && sudo -n true && echo OK || echo FAIL && \
echo "[SSH Root Login Disabled]" && sudo sshd -T | grep permitrootlogin && \
echo "[SSH Password Auth Disabled]" && sudo sshd -T | grep passwordauthentication && \
echo "[SSH Port]" && sudo sshd -T | grep ^port && \
echo "[Firewall Status]" && sudo ufw status | grep Status && \
echo "[Fail2Ban]" && systemctl is-active fail2ban && \
echo "[Fail2Ban SSH Jail]" && sudo fail2ban-client status sshd | head -n 4 && \
echo "[Docker]" && systemctl is-active docker && \
echo "[Auto Updates]" && systemctl is-enabled unattended-upgrades && \
echo "[Swap]" && swapon --show && \
echo "[Time Sync]" && timedatectl | grep -i "synchronized" && \
echo "[SSL Renewal Timer]" && systemctl is-active certbot.timer && \
echo "[Open Ports]" && ss -tuln
