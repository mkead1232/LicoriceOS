#!/bin/bash

# create-iso.sh - Create bootable ISO for DevOS
set -e

ISO_DIR="iso"
ISO_FILE="build/devos.iso"

echo "=== Creating Bootable DevOS ISO ==="
echo ""

# Create ISO directory structure
rm -rf "$ISO_DIR"
mkdir -p "$ISO_DIR"/{boot/grub,live}

# Copy kernel and initramfs
echo "Copying kernel and initramfs..."
cp build/bzImage "$ISO_DIR/boot/vmlinuz"
cp build/initramfs.cpio.gz "$ISO_DIR/boot/initrd.img"

# Create GRUB configuration
echo "Creating GRUB bootloader configuration..."
cat > "$ISO_DIR/boot/grub/grub.cfg" << 'EOF'
set timeout=5
set default=0

menuentry "DevOS - Development Operating System" {
    linux /boot/vmlinuz console=tty1 init=/init quiet
    initrd /boot/initrd.img
}

menuentry "DevOS - Debug Mode" {
    linux /boot/vmlinuz console=tty1 init=/init debug loglevel=7
    initrd /boot/initrd.img
}
EOF

# Create ISO using grub-mkrescue
echo "Building ISO image..."
grub-mkrescue -o "$ISO_FILE" "$ISO_DIR"

echo ""
echo "✓ ISO created: $ISO_FILE"
echo "Size: $(ls -lh $ISO_FILE | awk '{print $5}')"
echo ""
echo "To test in VirtualBox:"
echo "1. Create new VM with Linux/Other Linux (64-bit)"
echo "2. Allocate 1GB RAM minimum"
echo "3. Boot from ISO: $ISO_FILE"
echo ""
echo "WARNING: Real hardware deployment has risks!"
echo "- May not have compatible drivers"
echo "- Could make system unbootable"
echo "- Test in VM first!"