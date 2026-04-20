#!/bin/bash
#
# Piẻxed OS - GitHub Upload Helper
# Run this to upload your OS to GitHub
#

echo "=========================================="
echo "  Piẻxed OS - GitHub Upload"
echo "=========================================="
echo ""

# Check if git is installed
if ! command -v git &> /dev/null; then
    echo "[INFO] Git not installed. Installing..."
    sudo apt-get update
    sudo apt-get install -y git
fi

# Go to the right directory
cd "$(dirname "$0")/.."

echo "[1] Go to https://github.com and create an account"
echo "[2] Create a new repository called 'piexed-os'"
echo ""
read -p "Press Enter when ready..."

echo "[3] Configure Git with your GitHub email and name:"
echo ""
echo "Enter your name (e.g., John Doe):"
read NAME
git config --global user.name "$NAME"

echo "Enter your email (e.g., john@gmail.com):"
read EMAIL
git config --global user.email "$EMAIL"

echo ""

# Initialize git if not already
if [ ! -d ".git" ]; then
    echo "[4] Initializing Git..."
    git init
    git add .
    git commit -m "Initial commit - Piẻxed OS v1.0.0 Professional Edition"
fi

echo ""
echo "[5] Add your GitHub repository:"
echo ""
echo "Enter your GitHub repository URL:"
echo "example: https://github.com/username/piexed-os.git"
read REPO_URL

git remote add origin $REPO_URL 2>/dev/null || true
git remote set-url origin $REPO_URL

echo ""
echo "[6] Pushing to GitHub..."
echo ""
git branch -M main
git push -u origin main

echo ""
echo "=========================================="
echo "  UPLOAD COMPLETE!"
echo "=========================================="
echo ""
echo "Now go to GitHub Actions to see your build!"
echo ""
echo "1. Go to: https://github.com/YOUR_USERNAME/piexed-os/actions"
echo "2. Watch the build run"
echo "3. Download ISO from: https://github.com/YOUR_USERNAME/piexed-os/releases"
echo ""
echo "Done! 🎉"