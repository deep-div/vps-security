# Step 1: Create a Non-Root User

- Create user
adduser username

- Give sudo (admin) privileges
usermod -aG sudo username

- Switch to the new user
su - username

- Verify current user
whoami

- Test sudo access
sudo apt update