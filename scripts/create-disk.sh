#!/bin/bash

# create-disk.sh - Create persistent disk image for your OS
set -e

DISK_SIZE="100M"  # Size of the disk image
DISK_FILE="build/persistent-disk.img"

echo "=== Creating Persistent Disk Image ==="
echo ""

# Create the disk image file
echo "Creating ${DISK_SIZE} disk image..."
dd if=/dev/zero of="$DISK_FILE" bs=1M count=100 status=progress

echo ""
echo "Formatting disk with ext4 filesystem..."
# Format the disk image with ext4 filesystem
mkfs.ext4 -F "$DISK_FILE"

echo ""
echo "Setting up initial directory structure..."

# Mount the disk temporarily to set up directories
mkdir -p temp-mount
sudo mount -o loop "$DISK_FILE" temp-mount

# Create basic directory structure
sudo mkdir -p temp-mount/{home,opt,mnt,srv}
sudo mkdir -p temp-mount/home/user
sudo mkdir -p temp-mount/opt/projects

# Create a welcome file
sudo tee temp-mount/welcome.txt << 'EOF'
Welcome to your persistent filesystem!

This file is stored on the disk image and will persist between reboots.

You can:
- Create files that survive reboots
- Store your development projects
- Install additional software

Your home directory is at: /mnt/disk/home/user/
EOF

# Create a sample script
sudo tee temp-mount/test-script.sh << 'EOF'
#!/bin/sh
echo "This script runs from persistent storage!"
echo "Current date: $(date)"
echo "Files in persistent storage:"
ls -la /mnt/disk/
EOF

sudo chmod +x temp-mount/test-script.sh

# Set proper ownership (will be overridden by root in the OS, but good practice)
sudo chown -R 1000:1000 temp-mount/home/user 2>/dev/null || true

# Unmount
sudo umount temp-mount
rmdir temp-mount

echo ""
echo "✓ Persistent disk image created: $DISK_FILE"
echo "✓ Size: $DISK_SIZE"
echo "✓ Filesystem: ext4"
echo "✓ Initial files created"
echo ""
echo "The disk will be mounted at /mnt/disk/ in your OS"