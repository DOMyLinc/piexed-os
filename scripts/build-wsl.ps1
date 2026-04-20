# Piẻxed OS - Windows Build Helper
# Run this in PowerShell to set up WSL and build the ISO

Write-Host "============================================" -ForegroundColor Cyan
Write-Host "   Piẻxed OS - Build Helper for Windows" -ForegroundColor Cyan
Write-Host "============================================" -ForegroundColor Cyan
Write-Host ""

# Check if WSL is installed
if (!(Get-Command wsl -ErrorAction SilentlyContinue)) {
    Write-Host "[INFO] WSL not found. Installing WSL..." -ForegroundColor Yellow
    
    # Enable WSL
    dism.exe /online /enable-feature /featurename:Microsoft-Windows-Subsystem-Linux /all /norestart
    dism.exe /online /enable-feature /featurename:VirtualMachinePlatform /all /norestart
    
    Write-Host "[INFO] Please restart your PC and run this script again." -ForegroundColor Green
    Write-Host "[INFO] After restart, run: wsl --install" -ForegroundColor Green
    exit
}

# Check if Ubuntu is installed
$ubuntuInstalled = wsl -l -v | Select-String "Ubuntu"

if (!$ubuntuInstalled) {
    Write-Host "[INFO] Ubuntu not found. Installing..." -ForegroundColor Yellow
    wsl --install -d Ubuntu
    Write-Host "[INFO] Please restart and run this script again." -ForegroundColor Green
    exit
}

Write-Host "[INFO] WSL and Ubuntu are ready!" -ForegroundColor Green
Write-Host ""

# Run build in WSL
Write-Host "[INFO] Starting build process..." -ForegroundColor Cyan
Write-Host ""

# Update WSL
wsl -d Ubuntu -- bash -c "sudo apt update && sudo apt upgrade -y"

# Install dependencies
wsl -d Ubuntu -- bash -c "sudo apt install -y debootstrap squashfs-tools xorriso grub-pc-bin grub-efi-amd64-bin mtools git curl wget"

# Navigate to project
$projectPath = Split-Path -Parent $PSScriptRoot
$projectPath = "$projectPath\piexed-os"

if (Test-Path $projectPath) {
    Write-Host "[INFO] Building Piẻxed OS Professional Edition..." -ForegroundColor Cyan
    
    # Run build
    wsl -d Ubuntu -- bash -c "cd $projectPath && sudo make build-pro"
    
    Write-Host ""
    Write-Host "[SUCCESS] Build complete!" -ForegroundColor Green
    Write-Host ""
    Write-Host "ISO location (in WSL):" -ForegroundColor Cyan
    wsl -d Ubuntu -- bash -c "ls -lh $projectPath/output/*.iso"
} else {
    Write-Host "[ERROR] Project not found at: $projectPath" -ForegroundColor Red
}

Write-Host ""
Write-Host "Done!" -ForegroundColor Green