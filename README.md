# LicoriceOS
An "Operating System*" i made in half a week.

*it's basically just Linux with a custom init program but hey it boots and runs GCC

## what is this
I built this on my Steam Deck for a bit, then used WSL Ubuntu because yes. It's a minimal Linux-based OS that can:
- Boot in QEMU (or real hardware if you're brave)
- Compile and run C programs with GCC
- Save files that survive reboots
- Run all the normal Linux commands you'd expect

## what you get
- Custom init program (i'm PID 1!)
- Real Linux commands (ls, cat, nano, etc.)  
- Full GCC toolchain for development
- Persistent storage via disk image
- Built-in shell that actually works
- The ability to compile and run programs like a real OS

## getting started

### requirements
- Any Linux distro (WSL Ubuntu, Arch, Debian, etc.)
- A computer that can run QEMU
- Some patience for the initial setup

### dependencies to install

**Arch Linux:**
```bash
sudo pacman -S base-devel qemu-system-x86 grub xorriso cdrtools wget cpio gzip
```

**Ubuntu/Debian/WSL:**
```bash
sudo apt install build-essential gcc g++ libc6-dev qemu-system-x86 grub-mkrescue grub2-common xorriso mtools wget cpio gzip
```

**Other distros:** Install equivalent packages for build tools, QEMU, and GRUB.

### setup
```bash
git clone https://github.com/mkead1232/LicoriceOS
cd LicoriceOS
chmod +x scripts/*.sh test-my-os.sh
./scripts/copy-binaries.sh
./scripts/create-disk.sh
./scripts/expand-disk.sh
```

This copies Linux binaries from your system and sets up the development environment. Takes a few minutes because it's copying like half of your distro into your OS.

### running your os
```bash
./test-my-os.sh
```

Your OS boots in a QEMU window. You get a shell prompt where you can:
```bash
devos:/mnt# gcc hello.c -o hello
devos:/mnt# ./hello
devos:/mnt# nano myfile.txt
devos:/mnt# ls -la
```

Files you create in `/mnt/` survive reboots because they're stored on a virtual disk.

### making an iso
```bash
./scripts/create-iso.sh
```

Creates `build/devos.iso` that you can boot in VirtualBox or burn to a USB stick.

## how it works
- `init.c` - The main program that starts everything (PID 1)
- `scripts/copy-binaries.sh` - Copies Linux commands from your host system
- `scripts/create-disk.sh` - Creates persistent storage disk image
- `test-my-os.sh` - Builds everything and boots in QEMU

The "OS" is really just a Linux kernel with a custom initramfs containing your init program and copied system binaries. The init program mounts filesystems, sets up the environment, and gives you a shell.

## stuff you can do
- Write and compile C programs
- Use nano/vi to edit files  
- Create files that survive reboots
- Basically anything you'd do in a terminal
- Pretend you're a real OS developer

## warnings
- Don't run on real hardware unless you know what you're doing
- The disk image gets pretty big (500MB+) because it includes GCC
- I built this in like 4 days so expect weird bugs
- It's not actually a "real" OS but it's close enough

## distro-specific notes

**Arch Linux:** Your system probably has newer versions of everything, which is good. GCC might be in a different version directory.

**WSL Ubuntu:** Works great, just make sure you have WSL 2 for proper virtualization support.

**Other distros:** The copy script adapts to your system's layout automatically. If something breaks, it's probably a path issue - check where your distro puts GCC.

## troubleshooting

**"gcc: cannot execute 'cc1'"**
Run `./scripts/copy-binaries.sh` again, cc1 didn't get copied properly.

**"command not found" for everything**  
Your rootfs got wiped. Run `./scripts/copy-binaries.sh` to rebuild it.

**QEMU won't start**
Make sure you have at least 1GB free RAM and your CPU supports virtualization.

**"No persistent disk found"**
Run `./scripts/create-disk.sh` to create the disk image.

## why
- my friend joel thought it would be cool to make an os

## what i learned
- PID 1 is special and you have to handle it carefully
- Copying an entire Linux userland is harder than it looks
- GCC has a lot of dependencies you don't think about
- Custom operating systems are actually pretty cool
- The Steam Deck makes a surprisingly good development machine
