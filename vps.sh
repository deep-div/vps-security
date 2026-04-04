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
# Next time you login simply use
ssh devuser@203.57.85.118

Step 4: Disable password login
# open SSH config
sudo nano /etc/ssh/sshd_config  
# Search using Ctrl+W for PasswordAuthentication
change PasswordAuthentication yes to no
# restart SSH
sudo systemctl restart ssh  

Step 5: Step 4: Firewall 