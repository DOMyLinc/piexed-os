# Piẻxed OS - Upload to GitHub Guide

## Option 1: Use GitHub CLI (Fastest)

### Step 1: Install GitHub CLI
```bash
# Linux (Ubuntu)
curl -fsSL https://cli.github.com/packages/githubcli-archive-keyring.gpg | sudo dd of=/usr/share/keyrings/githubcli-archive-keyring.gpg
echo "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/githubcli-archive-keyring.gpg] https://cli.github.com/packages stable main" | sudo tee /etc/apt/sources.list.d/github-cli.list > /dev/null
sudo apt update
sudo apt install gh

# Or use winget (Windows)
winget install GitHub.cli
```

### Step 2: Login to GitHub
```bash
gh auth login
```
- Select **HTTPS** as the protocol
- Select **Yes** to authenticate with GitHub credentials
- Login in the browser

### Step 3: Create Repository
```bash
gh repo create piexed-os --public --source=. --push --description "Piẻxed OS - Professional Linux Distribution"
```

---

## Option 2: Manual Upload (Easier)

### Step 1: Download this project as ZIP
1. Go to this folder: `C:\Users\user\Desktop\tiktokclone\piexed-os\piexed-os`
2. Select ALL files
3. Right-click → Send to → Compressed (zip) folder

### Step 2: Create GitHub Repo
1. Go to: https://github.com/new
2. Repository name: `piexed-os`
3. Description: `Piẻxed OS - Professional Linux Distribution`
4. Select **Public**
5. Click **Create repository**

### Step 3: Upload Files
1. On your new repo page, click **uploading an existing file**
2. Drag and drop all files from the ZIP
3. Click **Commit changes**

---

## Option 3: Use Git (Traditional)

### Step 1: Install Git
- **Windows**: Download from https://git-scm.com
- **Linux**: `sudo apt install git`

### Step 2: Configure Git
```bash
git config --global user.name "Your Name"
git config --global user.email "your@email.com"
```

### Step 3: Upload
```bash
# In the piexed-os folder:
cd piexed-os

git init
git add .
git commit -m "Piẻxed OS v1.0.0"

# Create repo on GitHub first, then:
git remote add origin https://github.com/YOUR_USERNAME/piexed-os.git
git push -u origin main
```

---

## After Upload - The ISO Auto-Builds!

### Step 1: Watch Build
1. Go to: `https://github.com/YOUR_USERNAME/piexed-os/actions`
2. Click on the build job
3. Wait ~20 minutes for it to complete

### Step 2: Download ISO
1. Go to: `https://github.com/YOUR_USERNAME/piexed-os/releases`
2. Click on the artifact
3. Download the ISO

---

## Alternative: Use Replit (No Install Needed!)

### Step 1: Go to Replit
1. Go to: https://replit.com
2. Create a new Replit (Bash template)

### Step 2: Run Build
```bash
# In Replit terminal:
git clone https://github.com/YOUR_USERNAME/piexed-os.git
cd piexed-os
sudo apt update
sudo apt install -y debootstrap squashfs-tools xorriso
sudo make build-pro
# Download output file when done
```

---

## Need Help?

**Chat with me if you need help!**

The GitHub Actions workflow will automatically:
✅ Build the ISO
✅ Upload as artifact
✅ Create release when you tag a version

---

**After upload, tell me your GitHub username and I'll help share it! 🚀**