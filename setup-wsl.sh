#!/bin/bash

# setup-wsl.sh - Setup development environment for custom OS on WSL Ubuntu
set -e

echo "=== Setting up Custom OS Development Environment on WSL Ubuntu ==="
echo ""

# Check if running in WSL
if ! grep -q Microsoft /proc/version 2>/dev/null; then
    echo "Warning: This doesn't appear to be WSL. Script designed for WSL Ubuntu."
    read -p "Continue anyway? (y/n): " -n 1 -r
    echo
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        exit 1
    fi
fi

echo "Installing required packages..."
sudo apt update
sudo apt install -y \
    build-essential \
    bc \
    bison \
    flex \
    libssl-dev \
    libelf-dev \
    libncurses-dev \
    qemu-system-x86 \
    wget \
    cpio \
    gzip \
    git \
    vim \
    curl

echo ""
echo "Creating project structure..."
mkdir -p ~/my-dev-os/{build,rootfs,kernel,scripts}
cd ~/my-dev-os

echo "✓ Environment setup complete!"
echo ""
echo "Project created at: ~/my-dev-os"
echo "Windows path: \\\\wsl$\\Ubuntu\\home\\$(whoami)\\my-dev-os"
echo ""
echo "Next steps:"
echo "1. cd ~/my-dev-os"
echo "2. Create your init.c file"
echo "3. Run the build and test scripts"