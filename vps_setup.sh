############################################
# VPS SETUP GUIDE
# Placeholders:
#   <username>          = your new sudo user
#   <server-ip>         = your VPS IP address
#   yourdomain.com      = your domain
#   <your-windows-user> = your Windows account name
############################################


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
# restart SSH service
sudo systemctl restart ssh


############################################
# Step 2.1: Change Default SSH Port
############################################
# open SSH config, press Ctrl+W and search for Port 22
sudo nano /etc/ssh/sshd_config
# change Port 22 to something else, for example Port 2222
Port 2222
# allow 2222 in the firewall
sudo ufw allow 2222
# restart SSH service
sudo systemctl restart ssh
# test new SSH port (run from local), port changed to 2222
ssh -p 2222 <username>@<server-ip>


############################################
# Step 3: SSH Key Setup
############################################
# generate SSH key (local machine), press Enter three times, do not give any extra paths
ssh-keygen
# copy public key (Windows)
type C:\Users\<your-windows-user>\.ssh\id_ed25519.pub

# create ssh directory on VPS
mkdir -p ~/.ssh
# paste public key
nano ~/.ssh/authorized_keys
# set correct permissions
chmod 700 ~/.ssh
chmod 600 ~/.ssh/authorized_keys
# login using SSH key, it should not ask for password now
ssh -i C:\Users\<your-windows-user>\.ssh\id_ed25519 <username>@<server-ip>
# next time you login simply use this, no password should be asked
ssh <username>@<server-ip>


############################################
# Step 4: Disable Password Login
############################################
# open SSH config
sudo nano /etc/ssh/sshd_config
# search using Ctrl+W for PasswordAuthentication
# change PasswordAuthentication yes to no
PasswordAuthentication no
# check if the change is correct
sudo sshd -T | grep passwordauthentication
# if not, also change here
sudo nano /etc/ssh/sshd_config.d/50-cloud-init.conf
# restart SSH
sudo systemctl restart ssh


############################################
# Step 5: Firewall
############################################
# install ufw (firewall)
sudo apt install ufw -y
# fix broken packages (if any error earlier)
sudo apt --fix-broken install -y
# update system
sudo apt update && sudo apt upgrade -y
# allow SSH (IMPORTANT before enabling firewall)
sudo ufw allow OpenSSH
# allow HTTP (port 80)
sudo ufw allow 80
# allow HTTPS (port 443)
sudo ufw allow 443
# enable firewall
sudo ufw enable
# check firewall status
sudo ufw status


############################################
# Step 6: Fail2Ban Against Brute-Force Attacks
############################################
# install fail2ban
sudo apt install fail2ban -y
# enable fail2ban service on startup
sudo systemctl enable fail2ban
# start fail2ban service
sudo systemctl start fail2ban
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
# Step 7: Install Docker
############################################
# install required packages
sudo apt install apt-transport-https ca-certificates curl software-properties-common -y
# add Docker GPG key
curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo apt-key add -
# add Docker repository
sudo add-apt-repository "deb [arch=amd64] https://download.docker.com/linux/ubuntu jammy stable"
# update packages
sudo apt update
# install Docker
sudo apt install docker-ce -y
# start Docker
sudo systemctl start docker
# enable Docker on boot
sudo systemctl enable docker
# verify Docker
docker --version


############################################
# Step 8: Enable Automatic Security Updates
############################################
sudo apt install unattended-upgrades -y
sudo dpkg-reconfigure --priority=low unattended-upgrades


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


############################################
# Step 9: Setup SSL Certificates
############################################
# RUN LOCALLY: the domain should point to your VPS IP address.
# Go to your domain's DNS settings and add an A record with your VPS IP.
ping yourdomain.com

sudo apt update
sudo apt install certbot -y
sudo certbot certonly --standalone -d yourdomain.com -d www.yourdomain.com


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
echo "[Docker]" && systemctl is-active docker && \
echo "[Auto Updates]" && systemctl is-enabled unattended-upgrades && \
echo "[Open Ports]" && ss -tuln
