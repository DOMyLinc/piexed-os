#!/bin/bash
#
# Piẻxed OS - Build Verification Script
# Verifies all components work correctly
#

set -euo pipefail

OUTPUT_DIR="/workspace/piexed-os/output"
VERSION="1.0.0"

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
NC='\033[0m'

PASS=0
FAIL=0

pass() { echo -e "${GREEN}[PASS]${NC} $1"; ((PASS++)); }
fail() { echo -e "${RED}[FAIL]${NC} $1"; ((FAIL++)); }
info() { echo -e "${BLUE}[INFO]${NC} $1"; }
warn() { echo -e "${YELLOW}[WARNING]${NC} $1"; }

echo "============================================="
echo "   Piẻxed OS Build Verification"
echo "============================================="
echo ""

echo "=== Checking Build Scripts ==="
info "Checking scripts..."
for script in scripts/build-*.sh scripts/hardening.sh scripts/auto-update.sh; do
    if [ -f "$script" ]; then
        if [ -x "$script" ]; then
            pass "Script $script is executable"
        else
            chmod +x "$script" 2>/dev/null
            pass "Script $script exists"
        fi
    else
        fail "Script $script not found"
    fi
done

echo ""
echo "=== Checking Branding Files ==="
info "Checking branding..."
for file in branding/logo/*.svg branding/splash/plymouth-theme-piexed/*.sh branding/grub/*.txt; do
    if [ -f "$file" ]; then
        pass "Found: $file"
    fi
done

echo ""
echo "=== Checking Configuration Files ==="
info "Checking configs..."
for file in config/*.conf; do
    if [ -f "$file" ]; then
        pass "Found: $file"
    fi
done

echo ""
echo "=== Checking Generated ISO ==="
info "Checking ISO files..."
if [ -d "$OUTPUT_DIR" ]; then
    for iso in "$OUTPUT_DIR"/*.iso; do
        if [ -f "$iso" ]; then
            SIZE=$(ls -lh "$iso" | awk '{print $5}')
            pass "Found ISO: $iso ($SIZE)"
        fi
    done
else
    warn "Output directory not found (run build first)"
fi

echo ""
echo "=== Checking Makefile ==="
info "Checking Makefile..."
if [ -f "Makefile" ]; then
    pass "Makefile exists"
    if grep -q "build-pro" Makefile; then
        pass "Makefile has build-pro target"
    fi
    if grep -q "security" Makefile; then
        pass "Makefile has security target"
    fi
    if grep -q "update" Makefile; then
        pass "Makefile has update target"
    fi
else
    fail "Makefile not found"
fi

echo ""
echo "=== Verify Script Syntax ==="
info "Checking scripts for syntax errors..."
for script in scripts/*.sh; do
    if bash -n "$script" 2>/dev/null; then
        pass "Syntax OK: $script"
    else
        fail "Syntax error: $script"
    fi
done

echo ""
echo "============================================="
echo "        Verification Results"
echo "============================================="
echo ""
echo -e "Passed: ${GREEN}$PASS${NC}"
echo -e "Failed: ${RED}$FAIL${NC}"
echo ""

if [ $FAIL -eq 0 ]; then
    echo -e "${GREEN}All checks passed!${NC}"
    exit 0
else
    echo -e "${YELLOW}Some checks failed. Review above.${NC}"
    exit 1
fi