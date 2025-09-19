# LicoriceOS
An "Operating System*" i made in half a week.

*it's basically just Linux with a custom init program but hey it boots and runs GCC

## what is this
I built this on my Steam Deck using WSL Ubuntu because why not. It's a minimal Linux-based OS that can:
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
- WSL Ubuntu (or any Linux really)
- A computer that can run QEMU
- Some patience for the initial setup

### setup
```bash
git clone <this-repo>
cd licoriceOS
chmod +x setup.sh
./setup.sh
```

This will install dependencies, copy Linux binaries, and set up your development environment. It takes a few minutes because it's copying like half of Ubuntu into your OS.

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

## dependencies that get installed
- build-essential (GCC, make, etc.)
- qemu-system-x86 (to run your OS)
- grub-mkrescue (to make ISOs)
- A bunch of other stuff the setup script handles

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

built with white monster, stubbornness, and way too much time spent debugging why GCC couldn't find its own files
