# Copy the expand-disk script content above
chmod +x scripts/expand-disk.sh
./scripts/expand-disk.sh#!/bin/bash

# expand-disk.sh - Expand disk image to accommodate GCC and development tools
set -e

DISK_FILE="build/persistent-disk.img"
NEW_SIZE="500M"  # Expand to 500MB to fit GCC

echo "=== Expanding Persistent Disk Image ==="
echo ""

if [ ! -f "$DISK_FILE" ]; then
    echo "Error: $DISK_FILE not found!"
    echo "Create the disk first with: ./scripts/create-disk.sh"
    exit 1
fi

# Show current size
echo "Current disk size:"
ls -lh "$DISK_FILE"

echo ""
echo "Expanding disk image to $NEW_SIZE..."

# Add more space to the disk image
dd if=/dev/zero bs=1M count=400 >> "$DISK_FILE" status=progress

echo ""
echo "Resizing filesystem..."

# Resize the filesystem to use the new space
resize2fs "$DISK_FILE"

echo ""
echo "New disk size:"
ls -lh "$DISK_FILE"

echo ""
echo "✓ Disk expansion complete!"
echo "The disk image now has space for GCC and development tools."
