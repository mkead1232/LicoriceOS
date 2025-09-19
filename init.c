#define _GNU_SOURCE
#include <sys/mount.h>
#include <sys/stat.h>
#include <sys/types.h>
#include <sys/wait.h>
#include <fcntl.h>
#include <unistd.h>
#include <string.h>
#include <stdio.h>
#include <stdlib.h>
#include <errno.h>
#include <dirent.h>
#include <linux/reboot.h>
#include <sys/reboot.h>

// Add support for more storage devices
const char *candidates[] = {
    "/dev/nvme0n1", "/dev/nvme0n1p1",  // NVMe drives
    "/dev/sda", "/dev/sda1",           // SATA drives  
    "/dev/hda", "/dev/hda1",           // IDE drives
    "/dev/mmcblk0p1"                   // SD cards/eMMC
};

// Wait for a disk to appear
void wait_for_disk(const char *disk) {
    int tries = 0;
    while (access(disk, F_OK) != 0) {
        if (++tries > 10) {
            printf("%s not found after 10s, giving up\n", disk);
            return;
        }
        sleep(1);
    }
}

// Try mounting candidates
void setup_filesystem(void) {
    mkdir("/mnt", 0755);
    
    for (int i = 0; i < 3; i++) {
        wait_for_disk(candidates[i]);
        if (mount(candidates[i], "/mnt", "ext4", MS_RELATIME, "") == 0) {
            printf("\033[32m[OK]\033[0m Mounted %s on /mnt\n", candidates[i]);
            return;
        }
    }
    printf("No persistent disk found. Using initramfs only.\n");
}

// Execute real Linux commands and handle executable files
int run_command(char *cmd_line) {
    if (strcmp(cmd_line, "exit") == 0) {
        printf("Shutting down.\n");
        sync();
        reboot(LINUX_REBOOT_CMD_POWER_OFF);
        return 1;
    }
    
    if (strcmp(cmd_line, "") == 0) {
        return 0;
    }
    
    // Parse command line into arguments
    char *args[64];
    int argc = 0;
    char *token = strtok(cmd_line, " \t");
    
    while (token && argc < 63) {
        args[argc++] = token;
        token = strtok(NULL, " \t");
    }
    args[argc] = NULL;
    
    if (argc == 0) return 0;
    
    if (strcmp(args[0], "cd") == 0) {
        // Handle cd builtin
        char *target = (argc > 1) ? args[1] : "/mnt";
        if (chdir(target) != 0) {
            perror("cd");
        }
        return 0;  // Don't fork for builtins
    }

    if (strcmp(args[0], "credits") == 0) {
        printf("ADEN KIRK - LEAD DEVELOPER\n");
        printf("ATTIKUS CORLISS - FEEDBACK & TESTING\n");

        printf("\n\n\n\n no copyright, this is open source :)\n");
        printf("Check out ");
        return 0;  // Don't fork for builtins
    }

    if (strcmp(args[0], "help") == 0) {
        printf("ls [args] : list directory contents\n");
        printf("cat [args] : concatenate and display files\n");
        printf("echo [args] : display a line of text\n");
        printf("touch [args] : create empty files or update timestamps\n");
        printf("mkdir [args] : create directories\n");
        printf("rm [args] : remove files or directories\n");
        printf("cp [args] : copy files and directories\n");
        printf("mv [args] : move or rename files and directories\n");
        printf("pwd [args] : print working directory\n");
        printf("cd [args] : change directory\n");
        printf("chmod [args] : change file permissions\n");
        printf("chown [args] : change file owner and group\n");
        printf("grep [args] : search text using patterns\n");
        printf("find [args] : search for files in a directory hierarchy\n");
        printf("ps [args] : report process status\n");
        printf("free [args] : display memory usage\n");
        printf("df [args] : report file system disk space usage\n");
        printf("mount [args] : mount a filesystem\n");
        printf("umount [args] : unmount a filesystem\n");
        printf("which [args] : locate a command\n");
        printf("wc [args] : count lines, words, and characters\n");
        printf("head [args] : display the first part of files\n");
        printf("tail [args] : display the last part of files\n");
        printf("sort [args] : sort lines of text files\n");
        printf("uniq [args] : report or omit repeated lines\n");
        printf("cut [args] : remove sections from each line of files\n");
        printf("awk [args] : pattern scanning and processing language\n");
        printf("sed [args] : stream editor for filtering and transforming text\n");
        printf("tar [args] : archive files\n");
        printf("gzip [args] : compress files\n");
        printf("gunzip [args] : decompress files\n");
        printf("vi [args] : text editor\n");
        printf("nano [args] : text editor\n");
        printf("less [args] : view file contents interactively\n");
        printf("more [args] : view file contents interactively\n");
        printf("gcc [args] : GNU C compiler\n");
        printf("g++ [args] : GNU C++ compiler\n");
        printf("make [args] : build automation tool\n");
        printf("ld [args] : linker\n");
        printf("as [args] : assembler\n");
        printf("ar [args] : create, modify, and extract from archives\n");
        printf("objdump [args] : display information about object files\n");
        printf("nm [args] : list symbols from object files\n");
        printf("strip [args] : discard symbols from object files\n");
        printf("cpp [args] : C preprocessor\n");
        printf("cc [args] : C compiler\n");
        printf("pkg-config [args] : return metadata for installed libraries\n");
        printf("objcopy [args] : copy and translate object files\n");
        printf("strings [args] : print readable strings in files\n");
        printf("readelf [args] : display information about ELF files\n");
        printf("file [args] : determine file type\n");
        printf("ldd [args] : print shared library dependencies\n");
        printf("strace [args] : trace system calls and signals\n");
        printf("basename [args] : strip directory and suffix from filenames\n");
        printf("dirname [args] : strip last component from file name\n");
        printf("realpath [args] : canonicalize file paths\n");
        printf("clear [args] : clear the terminal screen\n");
        printf("help : show this help menu");

    }

    // Fork and execute the real command
    pid_t pid = fork();
    if (pid == 0) {
        // Child process - execute the command
        
        // Check if the command contains a path (like ./main or /path/to/file)
        if (strchr(args[0], '/') != NULL) {
            // It's a path - use execv for direct execution
            execv(args[0], args);
        } else {
            // It's a command name - use execvp to search PATH
            execvp(args[0], args);
        }
        
        // If exec returns, command failed
        printf("%s: command not found\n", args[0]);
        exit(1);
    } else if (pid > 0) {
        // Parent process - wait for child
        int status;
        waitpid(pid, &status, 0);
        
        // Show exit status if non-zero
        if (WIFEXITED(status) && WEXITSTATUS(status) != 0) {
            printf("Command exited with status %d\n", WEXITSTATUS(status));
        }
        return 0;
    } else {
        perror("fork");
        return 0;
    }
}

// Shell with real Linux commands
void shell(void) {
    char cmd[256];
    
    // Set environment variables for command execution
    setenv("PATH", "/bin:/usr/bin:/sbin:/usr/sbin", 1);
    setenv("HOME", "/mnt", 1);
    setenv("USER", "root", 1);
    
    // Set up GCC environment
    setenv("LIBRARY_PATH", "/usr/lib/gcc/x86_64-linux-gnu/13:/usr/lib:/lib", 1);
    setenv("C_INCLUDE_PATH", "/usr/lib/gcc/x86_64-linux-gnu/13/include", 1);
    setenv("GCC_EXEC_PREFIX", "/usr/libexec/gcc/x86_64-linux-gnu/13/", 1);
    setenv("COMPILER_PATH", "/usr/libexec/gcc/x86_64-linux-gnu/13/", 1);
    setenv("LD_LIBRARY_PATH", "/lib:/usr/lib:/usr/lib/gcc/x86_64-linux-gnu/13", 1);
    
    // Change to persistent storage if available
    if (access("/mnt/lost+found", F_OK) == 0) {
        chdir("/mnt");
        printf("Working directory set to /mnt (persistent storage)\n");
    } else {
        printf("\033[31mNo persistent storage available - using initramfs\n");
    }
    
    printf("\033[32mLicoriceOS  (Sugar) Shell Ready! \033[0m- Type 'exit' to shutdown\n");
    
    while (1) {
        // Show current directory in prompt
        char cwd[256];
        getcwd(cwd, sizeof(cwd));
        printf("\033[31mlicorice\033[0mos:\033[34m%s\033[0m$ ", cwd);
        fflush(stdout);
        
        if (!fgets(cmd, sizeof(cmd), stdin)) break;
        cmd[strcspn(cmd, "\n")] = 0; // strip newline
        
        if (run_command(cmd)) break;
    }
}

int main(void) {
    printf("==================================\n");
    printf("||                              ||\n");
    printf("||          \033[31mLicorice\033[0m");
    printf("OS          ||\n"); 
    printf("||     Created by Aden Kirk     ||\n");
    printf("||                              ||\n");
    printf("==================================\n");
    
    // Set up terminal environment
    setenv("TERM", "linux", 1);
    setenv("TERMINFO", "/usr/share/terminfo", 1);
    
    // Set up /dev, /proc, /sys
    mkdir("/proc", 0555);
    mkdir("/sys", 0555);
    mkdir("/dev", 0555);
    mount("proc", "/proc", "proc", 0, "");
    mount("sysfs", "/sys", "sysfs", 0, "");
    mount("devtmpfs", "/dev", "devtmpfs", 0, "");
    
    // Mount persistent disk if available
    setup_filesystem();
    
    // Start shell
    shell();
    
    return 0;
}