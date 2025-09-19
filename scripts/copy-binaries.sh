#!/bin/bash

# copy-binaries.sh - Copy essential Linux commands and complete GCC toolchain
set -e

ROOTFS_DIR="rootfs"

echo "=== Copying Linux binaries and GCC toolchain from WSL Ubuntu to rootfs ==="
echo ""

# Essential commands to copy
COMMANDS=(
    "ls" "cat" "echo" "touch" "mkdir" "rm" "cp" "mv"
    "pwd" "cd" "chmod" "chown" "grep" "find" "ps"
    "free" "df" "mount" "umount" "which" "wc"
    "head" "tail" "sort" "uniq" "cut" "awk" "sed"
    "tar" "gzip" "gunzip" "vi" "nano" "less" "more"
    "gcc" "g++" "make" "ld" "as" "ar" "objdump" "nm" "strip"
    "cpp" "cc" "pkg-config" "objcopy" "strings" "readelf"
    "file" "ldd" "strace" "basename" "dirname" "realpath"
    "clear"
)

echo "Creating directories..."
mkdir -p "$ROOTFS_DIR"/{bin,sbin,usr/{bin,sbin,lib,include,share},lib,lib64,etc,tmp,var,dev,proc,sys,mnt}

echo ""
echo "Copying essential commands..."

for cmd in "${COMMANDS[@]}"; do
    CMD_PATH=""
    
    # Check common directories in order of preference
    for dir in /usr/bin /bin /usr/local/bin /sbin /usr/sbin; do
        if [ -f "$dir/$cmd" ]; then
            CMD_PATH="$dir/$cmd"
            break
        fi
    done
    
    if [ -n "$CMD_PATH" ]; then
        echo "Copying $cmd from $CMD_PATH"
        cp "$CMD_PATH" "$ROOTFS_DIR/bin/"
    else
        echo "Warning: $cmd not found"
    fi
done

echo ""
echo "Copying GCC toolchain and internal components..."

# Copy GCC library directory if it exists
if [ -d "/usr/lib/gcc" ]; then
    echo "Copying GCC library directory..."
    cp -r "/usr/lib/gcc" "$ROOTFS_DIR/usr/lib/"
fi

# Copy GCC libexec directory (this is where cc1 actually lives)
if [ -d "/usr/libexec/gcc" ]; then
    echo "Copying GCC libexec directory (contains cc1)..."
    mkdir -p "$ROOTFS_DIR/usr/libexec"
    cp -r "/usr/libexec/gcc" "$ROOTFS_DIR/usr/libexec/"
    
    # Make sure all tools in libexec are executable
    find "$ROOTFS_DIR/usr/libexec/gcc" -type f -exec chmod +x {} \;
    echo "✓ cc1 and other GCC tools copied from /usr/libexec/gcc"
fi

# Copy GCC-related libexec tools if they exist
if [ -d "/usr/libexec/gcc" ]; then
    echo "Copying GCC libexec tools..."
    mkdir -p "$ROOTFS_DIR/usr/libexec"
    cp -r "/usr/libexec/gcc" "$ROOTFS_DIR/usr/libexec/"
fi

echo ""
echo "Finding and copying ALL GCC dependencies..."

# Get all GCC dependencies and copy them
if [ -f "/usr/bin/gcc" ]; then
    ldd /usr/bin/gcc 2>/dev/null | grep -o '/[^ ]*' | while read libpath; do
        if [ -f "$libpath" ]; then
            libname=$(basename "$libpath")
            if [ ! -f "$ROOTFS_DIR/lib/$libname" ]; then
                echo "  Copying GCC dependency: $libname"
                cp "$libpath" "$ROOTFS_DIR/lib/"
            fi
        fi
    done
fi

# Also get cc1 dependencies
CC1_PATH=$(find /usr/lib/gcc -name "cc1" 2>/dev/null | head -1)
if [ -n "$CC1_PATH" ] && [ -f "$CC1_PATH" ]; then
    echo "Finding cc1 dependencies..."
    ldd "$CC1_PATH" 2>/dev/null | grep -o '/[^ ]*' | while read libpath; do
        if [ -f "$libpath" ]; then
            libname=$(basename "$libpath")
            if [ ! -f "$ROOTFS_DIR/lib/$libname" ]; then
                echo "  Copying cc1 dependency: $libname"
                cp "$libpath" "$ROOTFS_DIR/lib/"
            fi
        fi
    done
fi

echo ""
echo "Copying system headers for compilation..."

# Copy essential header files that GCC needs
if [ -d "/usr/include" ]; then
    echo "Copying system headers from /usr/include..."
    cp -r "/usr/include"/* "$ROOTFS_DIR/usr/include/" 2>/dev/null || echo "Some headers failed to copy"
fi

# Copy architecture-specific headers
if [ -d "/usr/include/x86_64-linux-gnu" ]; then
    echo "Copying x86_64 headers..."
    mkdir -p "$ROOTFS_DIR/usr/include/x86_64-linux-gnu"
    cp -r "/usr/include/x86_64-linux-gnu"/* "$ROOTFS_DIR/usr/include/x86_64-linux-gnu/" 2>/dev/null
fi

echo ""
echo "Copying essential libraries..."

# Copy basic libraries that most commands need
LIB_DIRS="/lib/x86_64-linux-gnu /usr/lib/x86_64-linux-gnu /lib64"

for libdir in $LIB_DIRS; do
    if [ -d "$libdir" ]; then
        echo "Checking libraries in $libdir..."
        
        # Copy essential libraries
        ESSENTIAL_LIBS=(
            "libc.so.6" "libdl.so.2" "libpthread.so.0" "libm.so.6" 
            "librt.so.1" "libcrypt.so.1" "libz.so.1" "libgcc_s.so.1"
            "libstdc++.so.6" "libgomp.so.1" "libisl.so.23"
            "libmpc.so.3" "libmpfr.so.6" "libgmp.so.10"
        )
        
        for lib in "${ESSENTIAL_LIBS[@]}"; do
            if [ -f "$libdir/$lib" ]; then
                echo "  Copying $lib"
                cp "$libdir/$lib" "$ROOTFS_DIR/lib/"
            fi
        done
        
        # Copy ld-linux (dynamic linker)
        for linker in ld-linux-x86-64.so.2 ld-linux.so.2; do
            if [ -f "$libdir/$linker" ]; then
                echo "  Copying $linker"
                cp "$libdir/$linker" "$ROOTFS_DIR/lib/"
                mkdir -p "$ROOTFS_DIR/lib64"
                cp "$libdir/$linker" "$ROOTFS_DIR/lib64/"
            fi
        done
        
        # Copy static libraries needed for compilation
        STATIC_LIBS=(libc.a libm.a libpthread.a libdl.a librt.a libcrypt.a)
        for staticlib in "${STATIC_LIBS[@]}"; do
            if [ -f "$libdir/$staticlib" ]; then
                echo "  Copying static library $staticlib"
                cp "$libdir/$staticlib" "$ROOTFS_DIR/usr/lib/"
            fi
        done
    fi
done

echo ""
echo "Copying runtime startup files..."

# Copy crt files needed for C compilation
CRT_FILES="/usr/lib/x86_64-linux-gnu/crt*.o"
for crtfile in $CRT_FILES; do
    if [ -f "$crtfile" ]; then
        echo "Copying $(basename $crtfile)"
        cp "$crtfile" "$ROOTFS_DIR/usr/lib/"
    fi
done

# Copy additional object files
for objfile in /usr/lib/x86_64-linux-gnu/{libc_nonshared.a,libpthread_nonshared.a}; do
    if [ -f "$objfile" ]; then
        echo "Copying $(basename $objfile)"
        cp "$objfile" "$ROOTFS_DIR/usr/lib/"
    fi
done

echo ""
echo "Automatically detecting library dependencies for all binaries..."

# Use ldd to find dependencies for ALL copied binaries
for binary in "$ROOTFS_DIR/bin"/*; do
    if [ -f "$binary" ] && [ -x "$binary" ]; then
        echo "Checking dependencies for $(basename $binary)..."
        
        # Get library dependencies
        ldd "$binary" 2>/dev/null | grep -o '/[^ ]*' | while read libpath; do
            if [ -f "$libpath" ]; then
                libname=$(basename "$libpath")
                
                # Copy to rootfs lib directory if not already there
                if [ ! -f "$ROOTFS_DIR/lib/$libname" ]; then
                    echo "  Auto-copying dependency: $libname"
                    cp "$libpath" "$ROOTFS_DIR/lib/"
                fi
            fi
        done
    fi
done

echo ""
echo "Copying terminal information for nano/vi..."

# Copy terminfo for proper terminal support
if [ -d "/usr/share/terminfo" ]; then
    echo "Copying terminfo database..."
    mkdir -p "$ROOTFS_DIR/usr/share"
    cp -r "/usr/share/terminfo" "$ROOTFS_DIR/usr/share/"
fi

echo ""
echo "Setting up shell links..."

# Make sure sh points to a real shell
if [ -f "$ROOTFS_DIR/bin/bash" ]; then
    ln -sf bash "$ROOTFS_DIR/bin/sh"
elif [ -f "/bin/dash" ]; then
    cp "/bin/dash" "$ROOTFS_DIR/bin/"
    ln -sf dash "$ROOTFS_DIR/bin/sh"
else
    echo "Warning: No suitable shell found for /bin/sh"
fi

echo ""
echo "Making all binaries executable..."
chmod +x "$ROOTFS_DIR/bin"/*
find "$ROOTFS_DIR/usr/lib/gcc" -type f -exec chmod +x {} \; 2>/dev/null || true

echo ""
echo "Creating test programs..."

# Create a simple test program
cat > "$ROOTFS_DIR/test.c" << 'EOF'
#include <stdio.h>

int main() {
    printf("Hello from GCC on your custom OS!\n");
    printf("Compilation successful!\n");
    return 0;
}
EOF

# Create a more complex test program
cat > "$ROOTFS_DIR/test-advanced.c" << 'EOF'
#include <stdio.h>
#include <stdlib.h>
#include <string.h>

int main() {
    char *buffer = malloc(100);
    strcpy(buffer, "Advanced C test successful!");
    printf("%s\n", buffer);
    free(buffer);
    return 0;
}
EOF

echo ""
echo "=== SUMMARY ==="
echo "Binaries copied: $(ls "$ROOTFS_DIR/bin/" | wc -l)"
echo "Libraries copied: $(ls "$ROOTFS_DIR/lib/" | wc -l)"

echo ""
echo "GCC toolchain status:"
if [ -f "$ROOTFS_DIR/bin/gcc" ]; then
    echo "✓ GCC binary copied"
else
    echo "✗ GCC binary missing"
fi

if [ -d "$ROOTFS_DIR/usr/lib/gcc" ]; then
    echo "✓ GCC internal tools copied"
    CC1_COUNT=$(find "$ROOTFS_DIR/usr/lib/gcc" -name "cc1" | wc -l)
    echo "  Found $CC1_COUNT cc1 executables"
else
    echo "✗ GCC internal tools missing"
fi

if [ -f "$ROOTFS_DIR/usr/include/stdio.h" ]; then
    echo "✓ System headers copied"
else
    echo "✗ System headers missing"
fi

if [ -f "$ROOTFS_DIR/lib/libisl.so.23" ]; then
    echo "✓ GCC mathematical libraries copied"
else
    echo "✗ GCC mathematical libraries missing"
fi

echo ""
echo "✓ Complete binary copying finished!"
echo ""
echo "Your rootfs now contains:"
echo "- Complete Linux command set"
echo "- Full GCC toolchain with all dependencies"
echo "- System headers and libraries"
echo "- Terminal support files"
echo "- Test programs (test.c and test-advanced.c)"
echo ""
echo "Total rootfs size: $(du -sh $ROOTFS_DIR | cut -f1)"
echo ""
echo "Rebuild your OS with: ./test-my-os.sh"
echo "Then try: gcc test.c -o test && ./test"