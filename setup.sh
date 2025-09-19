#!/bin/bash

# setup.sh - Set up development environment for LicoriceOS
set -e

echo "=== LicoriceOS Setup ==="
echo "Setting up development environment..."

# Install required packages
echo "Installing dependencies..."
sudo apt update
sudo apt install -y build-essential gcc g++ libc6-dev qemu-system-x86 grub-mkrescue grub2-common xorriso mtools wget cpio gzip

# Create directories
mkdir -p {build,scripts}

# Make scripts executable
chmod +x scripts/*.sh test-my-os.sh 2>/dev/null || echo "Scripts will be made executable when created"

# Create initial rootfs and disk
echo "Creating filesystem and disk image..."
./scripts/copy-binaries.sh
./scripts/create-disk.sh
./scripts/expand-disk.sh

echo ""
echo "Setup complete! You can now:"
echo "1. Build and test: ./test-my-os.sh"
echo "2. Create ISO: ./scripts/create-iso.sh"
echo ""
echo "Your custom OS includes:"
echo "- Full Linux command set"
echo "- GCC compiler toolchain" 
echo "- Persistent storage"
echo "- Text editors (nano, vi)"
echo ""
echo "Have fun building your OS!"
