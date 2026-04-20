#===============================================================================
# Piẻxed OS - MASTER BUILD SYSTEM
# Version: 1.0.0 Professional Edition
# Zero Bugs - All Features - Jarvis AI - 300+ Tools
#===============================================================================

VERSION = 1.0.0
OUTPUT_DIR = output

# Colors
GREEN = \033[0;32m
BLUE = \033[0;34m
CYAN = \033[0;36m
NC = \033[0m

all: build

## build - Build ISO (Main)
build:
	@echo "$(CYAN)=== Building Piẻxed OS ===$(NC)"
	@chmod +x scripts/master-build.sh
	@sudo scripts/master-build.sh

## clean - Clean build
clean:
	@rm -rf output build workspace 2>/dev/null || true
	@echo "Cleaned!"

## upload - Upload to GitHub
upload:
	@echo "Upload to GitHub:"
	@echo "1. Go to: https://github.com/new"
	@echo "2. Create repo 'piexed-os'"
	@echo "3. Upload files"

## test-oracle - Test instructions
test-oracle:
	@echo "=== Test in Oracle VM ==="
	@echo "1. Create VM: Ubuntu 64-bit, 2GB RAM, 40GB"
	@echo "2. Mount ISO from output/"
	@echo "3. Install"
	@echo "4. Login: piexed / piexed"

## info - Show info
info:
	@echo "=== Piẻxed OS v$(VERSION) ==="
	@ls -lh output/*.iso 2>/dev/null || echo "No ISO"

## help - Help
help:
	@echo ""
	@echo "Piẻxed OS v$(VERSION) - Master Build"
	@echo ""
	@echo "make build        - Build ISO"
	@echo "make clean       - Clean"
	@echo "make test-oracle - Test in Oracle"
	@echo "make info        - Show ISO"
	@echo ""
	@echo "After build, login: piexed / piexed"