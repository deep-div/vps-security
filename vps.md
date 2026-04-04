# VPS Setup Guide

## Step 1: Create a New User on VPS

- Login to your VPS
```bash
ssh root@your_server_ip
```

- Create a new user
```bash
adduser username
```

- Set password (you will be prompted)

- Add user to sudo group
```bash
usermod -aG sudo username
```

- Switch to the new user
```bash
su - username
```

- Verify sudo access
```bash
sudo whoami
```

If it returns `root`, sudo is working correctly.

---

## Notes
- Replace `username` with your desired username
- Avoid using root for daily tasks
- Keep your credentials secure
