Step 1: Create Create a new user 
# add new user
adduser devuser  
# give sudo access to that user
usermod -aG sudo devuser  
# switch to new user
su - devuser  
# test sudo access for new user
sudo whoami
sudo apt update  

Step 2: Disable Root Login, as it is a security risk to allow root login via SSH. Instead, we will use the new user we created in Step 1 to log in and perform administrative tasks.
# verify new user SSH login (run from local)
ssh devuser@203.57.85.118  
# open SSH config
sudo nano /etc/ssh/sshd_config  
# change PermitRootLogin yes to no
PermitRootLogin no  
# restart SSH service
sudo systemctl restart ssh  

Step 2.1 Change Default SSH Port 
# Run Ctrl+W and search for Port 22, change it to something else, for example Port 2222
sudo nano /etc/ssh/sshd_config
# change Port 22 to something else, for example Port 2222
Port 2222
# allow 2222 restart SSH service
sudo ufw allow 2222
# Restart SSH service
sudo systemctl restart ssh
# test new SSH port (run from local) PORT Changed TO 2222
ssh -p 2222 devuser@203.57.85.118 

Step 3: SSH Key setup
# generate SSH key (local machine) ## CLick enter enter enter do not give any extra paths
ssh-keygen  
# copy public key
type C:\Users\Acer\.ssh\id_ed25519.pub

# create ssh directory on VPS
mkdir -p ~/.ssh  
# paste public key
nano ~/.ssh/authorized_keys  
# set correct permissions
chmod 700 ~/.ssh  
chmod 600 ~/.ssh/authorized_keys  
# login using SSH key, it should not ask for password now
ssh -i C:\Users\Acer\.ssh\id_ed25519.txt devuser@203.57.85.118  
# Next time you login simply use, no password should be asked
ssh devuser@203.57.85.118

Step 4: Disable password login
# open SSH config
sudo nano /etc/ssh/sshd_config  
# Search using Ctrl+W for PasswordAuthentication
change PasswordAuthentication yes to no
# Check if the change is correct
sudo sshd -T | grep passwordauthentication
# If not also change here 
sudo nano /etc/ssh/sshd_config.d/50-cloud-init.conf
# restart SSH
sudo systemctl restart ssh  

Step 5: Firewall
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

Step 6: Fail2Ban against brute-force attacks
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

Step 6.1: Configure lynis for security auditing
sudo apt install lynis -y
sudo lynis audit system

Step 7: Install Docker
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

Step 8: Enable Automatic Security Updates
sudo apt install unattended-upgrades -y
sudo dpkg-reconfigure --priority=low unattended-upgrades

Step 8.1: Swap Setup
# Create 2GB swap file
sudo fallocate -l 2G /swapfile
# Set correct permissions (security)
sudo chmod 600 /swapfile
# Format it as swap
sudo mkswap /swapfile
# Enable swap
sudo swapon /swapfile
# Make it permanent (survives reboot)
echo '/swapfile none swap sw 0 0' | sudo tee -a /etc/fstab
# Set swappiness (use swap less, keep system fast)
sudo sysctl vm.swappiness=10
# Make swappiness permanent
echo 'vm.swappiness=10' | sudo tee -a /etc/sysctl.conf

Step 9: Setup SSL Certificates
# RUN IN LOCAL: It should point to your VPS IP address. Go in your domain DNS add VPS IP.
ping fundscreener.online
sudo apt update
sudo apt install certbot -y
sudo certbot certonly --standalone -d fundscreener.online -d www.fundscreener.online

Step 10: ALL Check
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