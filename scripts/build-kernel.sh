#!/bin/bash

# build-kernel.sh - Build custom Linux kernel for development OS on WSL
set -e

KERNEL_VERSION="6.6.52"
KERNEL_DIR="kernel"
BUILD_DIR="build"

echo "=== Building Custom Linux Kernel $KERNEL_VERSION on WSL ==="
echo "This will take 15-30 minutes depending on your system..."
echo ""

mkdir -p "$KERNEL_DIR" "$BUILD_DIR"
cd "$KERNEL_DIR"

# Download kernel if not present
if [ ! -d "linux-$KERNEL_VERSION" ]; then
    echo "Downloading Linux kernel $KERNEL_VERSION..."
    if [ ! -f "linux-$KERNEL_VERSION.tar.xz" ]; then
        wget "https://cdn.kernel.org/pub/linux/kernel/v6.x/linux-$KERNEL_VERSION.tar.xz"
    fi
    echo "Extracting kernel source..."
    tar -xf "linux-$KERNEL_VERSION.tar.xz"
fi

cd "linux-$KERNEL_VERSION"

# Create minimal config for development OS
echo "Creating minimal kernel configuration..."
cat > .config << 'EOF'
# Minimal Development OS Kernel Configuration

# Basic system requirements
CONFIG_64BIT=y
CONFIG_X86_64=y
CONFIG_LOCALVERSION="-devos"

# Core kernel features
CONFIG_PRINTK=y
CONFIG_BUG=y
CONFIG_ELF_CORE=y
CONFIG_SIGNALFD=y
CONFIG_TIMERFD=y
CONFIG_EVENTFD=y
CONFIG_SHMEM=y
CONFIG_AIO=y
CONFIG_MEMBARRIER=y
CONFIG_KALLSYMS=y
CONFIG_MULTIUSER=y

# File systems
CONFIG_FILE_LOCKING=y
CONFIG_PROC_FS=y
CONFIG_PROC_KCORE=y
CONFIG_PROC_SYSCTL=y
CONFIG_SYSFS=y
CONFIG_TMPFS=y
CONFIG_TMPFS_POSIX_ACL=y
CONFIG_DEVTMPFS=y
CONFIG_DEVTMPFS_MOUNT=y

# Essential for init
CONFIG_UNIX98_PTYS=y
CONFIG_TTY=y
CONFIG_VT=y
CONFIG_VT_CONSOLE=y
CONFIG_CONSOLE_TRANSLATIONS=y

# CRITICAL: Support for initramfs/initrd
CONFIG_BLK_DEV_INITRD=y
CONFIG_INITRAMFS_SOURCE=""
CONFIG_RD_GZIP=y
CONFIG_RD_BZIP2=y
CONFIG_RD_LZMA=y
CONFIG_RD_XZ=y
CONFIG_RD_LZO=y
CONFIG_RD_LZ4=y

# Serial console support
CONFIG_SERIAL_8250=y
CONFIG_SERIAL_8250_CONSOLE=y

# Executable formats
CONFIG_BINFMT_ELF=y
CONFIG_BINFMT_SCRIPT=y

# Basic networking
CONFIG_NET=y
CONFIG_UNIX=y
CONFIG_INET=y
CONFIG_IPV6=y

# Block layer
CONFIG_BLOCK=y

# Memory management
CONFIG_MMU=y
CONFIG_FLATMEM=y
CONFIG_SPLIT_PTLOCK_CPUS=4

# SMP support
CONFIG_SMP=y
CONFIG_NR_CPUS=8

# Timer subsystem
CONFIG_TICK_ONESHOT=y
CONFIG_NO_HZ_COMMON=y
CONFIG_HIGH_RES_TIMERS=y

# x86 specific
CONFIG_X86_LOCAL_APIC=y
CONFIG_X86_IO_APIC=y
CONFIG_X86_TSC=y

# PCI support (minimal)
CONFIG_PCI=y

# Input devices (basic)
CONFIG_INPUT=y
CONFIG_INPUT_KEYBOARD=y
CONFIG_KEYBOARD_ATKBD=y

# Development/debugging support
CONFIG_DEBUG_KERNEL=y
CONFIG_DEBUG_INFO=y
CONFIG_MAGIC_SYSRQ=y

# Virtualization support (for QEMU)
CONFIG_VIRTUALIZATION=y
CONFIG_HYPERVISOR_GUEST=y
CONFIG_PARAVIRT=y
CONFIG_KVM_GUEST=y

# Essential drivers for QEMU
CONFIG_ATA=y
CONFIG_ATA_PIIX=y
CONFIG_ATA_GENERIC=y
CONFIG_PATA_LEGACY=y
CONFIG_SATA_AHCI=y
CONFIG_E1000=y

# Block device support
CONFIG_BLK_DEV=y
CONFIG_BLK_DEV_LOOP=y

# SCSI support (sometimes needed)
CONFIG_SCSI=y
CONFIG_BLK_DEV_SD=y

# Partition support
CONFIG_PARTITION_ADVANCED=y
CONFIG_MSDOS_PARTITION=y
CONFIG_EFI_PARTITION=y

CONFIG_EXT4_FS=y
CONFIG_EXT4_USE_FOR_EXT2=y
CONFIG_VIRTIO_BLK=ys

EOF

# Process configuration
echo "Processing kernel configuration..."
make olddefconfig

# Show configuration summary
echo ""
echo "Kernel configuration summary:"
echo "  Target: x86_64 development system"
echo "  Features: Basic filesystems, networking, virtualization"
echo "  Optimized for: QEMU virtual machines"
echo ""

# Build kernel
echo "Building kernel (this will take a while)..."
echo "Using $(nproc) CPU cores for compilation..."

# Build with progress indication
make -j$(nproc) bzImage | while IFS= read -r line; do
    echo "$line"
    # Show progress for long builds
    if [[ "$line" == *"CC"* ]] || [[ "$line" == *"LD"* ]]; then
        printf "."
    fi
done

echo ""
echo "Kernel compilation completed!"

# Copy to build directory
echo "Installing kernel..."
cp arch/x86/boot/bzImage "../../$BUILD_DIR/bzImage-custom"
cp System.map "../../$BUILD_DIR/System.map-$KERNEL_VERSION"
cp .config "../../$BUILD_DIR/kernel-config-$KERNEL_VERSION"

# Create symlink for easy access
cd "../../$BUILD_DIR"
ln -sf "bzImage-custom" "bzImage"

cd ..

echo ""
echo "=== Custom Kernel Build Complete ==="
echo ""
echo "Kernel files:"
echo "  Main kernel: $BUILD_DIR/bzImage"
echo "  Custom build: $BUILD_DIR/bzImage-custom"  
echo "  System map: $BUILD_DIR/System.map-$KERNEL_VERSION"
echo "  Config: $BUILD_DIR/kernel-config-$KERNEL_VERSION"
echo ""
echo "Kernel size: $(ls -lh $BUILD_DIR/bzImage | awk '{print $5}')"
echo ""
echo "Your custom kernel includes:"
echo "✓ Minimal filesystem support (/proc, /sys, tmpfs)"
echo "✓ Basic networking capabilities"
echo "✓ Serial console support"
echo "✓ QEMU virtualization optimizations"
echo "✓ Development/debugging features"
echo ""
echo "Test your custom kernel with: ./test-my-os.sh"