#!/bin/bash

# test-my-os.sh - Complete OS testing script for WSL Ubuntu
set -e

echo "=== LicoriceOS - Complete Build & Test (WSL Ubuntu) ==="
echo ""

# Configuration
BUILD_DIR="build"
ROOTFS_DIR="rootfs" 
KERNEL_VERSION="6.6.52"

mkdir -p "$BUILD_DIR"

# Step 1: Build init program
echo "[1/4] Building init program..."
if [ ! -f "$BUILD_DIR/init" ]; then
    if [ ! -f "init.c" ]; then
        echo "Error: init.c not found!"
        echo "Create init.c first with your custom init program"
        exit 1
    fi
    gcc -static -o "$BUILD_DIR/init" init.c
    echo "✓ Init built successfully"
else
    echo "✓ Init already exists"
fi

# Step 2: Create minimal rootfs
echo ""
echo "[2/4] Creating root filesystem..."

# In test-my-os.sh, add this check:
if [ ! -d "$ROOTFS_DIR" ] || [ ! -f "$ROOTFS_DIR/bin/gcc" ]; then
    echo "Rootfs missing or incomplete. Rebuilding..."
    ./scripts/copy-binaries.sh
fi

# Create directory structure
mkdir -p "$ROOTFS_DIR"/{bin,sbin,etc,proc,sys,dev,tmp,var,lib,usr/{bin,sbin},root,mnt}
chmod 1777 "$ROOTFS_DIR/tmp"

# Copy our init
cp "$BUILD_DIR/init" "$ROOTFS_DIR/init"
chmod 755 "$ROOTFS_DIR/init"

# Create a simple shell (not used since we have built-in shell, but good for compatibility)
cat > "$ROOTFS_DIR/bin/sh" << 'EOF'
#!/bin/sh
echo "External shell - not normally used"
echo "The built-in shell in init handles commands"
exit 0
EOF
chmod 755 "$ROOTFS_DIR/bin/sh"

# Create essential device files (requires sudo)
sudo mknod "$ROOTFS_DIR/dev/console" c 5 1 2>/dev/null || true
sudo mknod "$ROOTFS_DIR/dev/null" c 1 3 2>/dev/null || true
sudo mknod "$ROOTFS_DIR/dev/zero" c 1 5 2>/dev/null || true

# Basic config files
echo "root:x:0:0:root:/root:/bin/sh" > "$ROOTFS_DIR/etc/passwd"
echo "root:x:0:" > "$ROOTFS_DIR/etc/group"
echo "devos" > "$ROOTFS_DIR/etc/hostname"

# Create hosts file
cat > "$ROOTFS_DIR/etc/hosts" << 'EOF'
127.0.0.1   localhost devos
::1         localhost devos
EOF

# Create initramfs archive
cd "$ROOTFS_DIR"
find . | cpio -o -H newc | gzip > "../$BUILD_DIR/initramfs.cpio.gz"
cd ..

echo "✓ Root filesystem created"

# Step 3: Create persistent disk if needed
echo ""
echo "[3/5] Setting up persistent storage..."
if [ ! -f "build/persistent-disk.img" ]; then
    echo "Creating persistent disk image..."
    if [ ! -f "scripts/create-disk.sh" ]; then
        echo "Error: create-disk.sh script not found!"
        echo "Please create the disk creation script first"
        exit 1
    fi
    ./scripts/create-disk.sh
else
    echo "✓ Persistent disk already exists"
fi

# Step 4: Get kernel
echo ""
echo "[3/4] Preparing kernel..."
if [ ! -f "$BUILD_DIR/bzImage" ]; then
    echo "No kernel found. You have options:"
    echo "  1) Download Alpine Linux kernel (fast, 10MB)"
    echo "  2) Use Ubuntu kernel from host (if available)"
    echo "  3) Build custom kernel (slow, educational)"
    echo ""
    read -p "Choose option (1-3): " choice
    
    case $choice in
        1)
            echo "Downloading Alpine Linux kernel..."
            wget -O "$BUILD_DIR/bzImage" "https://dl-cdn.alpinelinux.org/alpine/v3.18/releases/x86_64/netboot/vmlinuz-lts" || {
                echo "Download failed. Trying alternative source..."
                wget -O "$BUILD_DIR/bzImage" "http://archive.ubuntu.com/ubuntu/dists/jammy/main/installer-amd64/current/legacy-images/netboot/ubuntu-installer/amd64/linux"
            }
            ;;
        2)
            echo "Looking for Ubuntu kernel..."
            UBUNTU_KERNEL=$(ls /boot/vmlinuz-* 2>/dev/null | head -1)
            if [ -n "$UBUNTU_KERNEL" ]; then
                sudo cp "$UBUNTU_KERNEL" "$BUILD_DIR/bzImage"
                echo "✓ Copied Ubuntu kernel: $UBUNTU_KERNEL"
            else
                echo "No Ubuntu kernel found. Downloading Alpine kernel..."
                wget -O "$BUILD_DIR/bzImage" "https://dl-cdn.alpinelinux.org/alpine/v3.18/releases/x86_64/netboot/vmlinuz-lts"
            fi
            ;;
        3)
            echo "Building custom kernel (this will take 20+ minutes)..."
            ./scripts/build-kernel.sh
            ;;
        *)
            echo "Invalid choice. Downloading Alpine kernel as fallback..."
            wget -O "$BUILD_DIR/bzImage" "https://dl-cdn.alpinelinux.org/alpine/v3.18/releases/x86_64/netboot/vmlinuz-lts"
            ;;
    esac
    
    echo "✓ Kernel ready"
else
    echo "✓ Kernel already exists"
fi

# Verify kernel is valid
if [ ! -s "$BUILD_DIR/bzImage" ]; then
    echo "Error: Kernel file is empty or invalid"
    exit 1
fi

# Step 4: Test in QEMU
echo ""
echo "[4/4] Starting QEMU test..."
echo ""
echo "=== BOOTING YOUR CUSTOM DEVELOPMENT OS ==="
echo ""
echo "Your OS will start in QEMU. Try these commands:"
echo "  help           - show all available commands"
echo "  echo hello     - test basic output"
echo "  ps             - show running processes"
echo "  cat /proc/cpuinfo - show CPU information"
echo "  free           - show memory usage"
echo "  ls /           - list root directory"
echo "  pwd            - show current directory"
echo "  exit           - shutdown the OS"
echo ""
echo "To exit QEMU: Press Ctrl+A, then X"
echo "============================================"
echo ""

# Check if we're in WSL and warn about performance
if grep -q Microsoft /proc/version 2>/dev/null; then
    echo "Note: Running in WSL - QEMU performance may be slower than native Linux"
    echo ""
fi

# Step 4: Determine which kernel to use
echo ""
echo "[4/4] Starting QEMU test..."

# Auto-detect which kernel to use
KERNEL_FILE=""
if [ -f "$BUILD_DIR/bzImage-custom" ]; then
    KERNEL_FILE="$BUILD_DIR/bzImage-custom"
    echo "Using custom built kernel"
elif [ -f "$BUILD_DIR/bzImage" ]; then
    KERNEL_FILE="$BUILD_DIR/bzImage"
    echo "Using downloaded kernel"
else
    echo "Error: No kernel found!"
    exit 1
fi

echo "Kernel: $KERNEL_FILE"


qemu-system-x86_64 \
    -kernel "$KERNEL_FILE" \
    -initrd "$BUILD_DIR/initramfs.cpio.gz" \
    -append "console=tty1 init=/init quiet loglevel=3" \
    -display gtk \
    -hda build/persistent-disk.img \
    -m 1024M \
    -smp 2 \
    -enable-kvm 2>/dev/null || qemu-system-x86_64 \
    -kernel "$KERNEL_FILE" \
    -initrd "$BUILD_DIR/initramfs.cpio.gz" \
    -append "console=tty1 init=/init quiet loglevel=3" \
    -display gtk \
    -hda build/persistent-disk.img \
    -m 1024M \
    -smp 2

echo ""
echo "=== QEMU SESSION ENDED ==="
echo ""