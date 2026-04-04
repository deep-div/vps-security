Step 1: Create Create a new user 
# add new user
adduser fundscreener  
# give sudo access 
usermod -aG sudo fundscreener  
# switch to new user
su - fundscreener  
# test sudo access for new user
sudo whoami
sudo apt update  

Step 2: Disable Root Login
# verify new user SSH login (run from local)
ssh fundscreener@203.57.85.118  
# open SSH config
sudo nano /etc/ssh/sshd_config  
# change PermitRootLogin yes to no
PermitRootLogin no  
# restart SSH service
sudo systemctl restart ssh  

Step 3: SSH Key setup
# generate SSH key (local machine) ## CLick enter enter enter do not give any extra paths
ssh-keygen  
# view public key
type C:\Users\Acer\.ssh\id_ed25519.pub

# create ssh directory on VPS
mkdir -p ~/.ssh  
# add public key
nano ~/.ssh/authorized_keys  
# set correct permissions
chmod 700 ~/.ssh  
chmod 600 ~/.ssh/authorized_keys  

# login using SSH key
ssh -i C:\Users\Acer\.ssh\id_ed25519.txt fundscreener@203.57.85.118  

Step 4: Disable password login
# open SSH config
sudo nano /etc/ssh/sshd_config  
# change PasswordAuthentication yes to no
PasswordAuthentication no  
# restart SSH
sudo systemctl restart ssh  