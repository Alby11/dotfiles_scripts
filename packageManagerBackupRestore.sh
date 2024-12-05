#!/bin/bash
# Backup and restore script for Fedora, Ubuntu, and Arch Linux

# Set the backup directory
BACKUP_DIR=~/.local/share/backup/$(basename $0 .sh)

# Detect the Linux distribution
if [ -f /etc/os-release ]; then
    . /etc/os-release
    OS=${NAME% Linux}
else
    OS=$(uname -s)
fi

# Create the backup directory
mkdir -p $BACKUP_DIR

# Spinning cursor animation
function spinner {
    local pid=$1
    local delay=0.1
    local spinstr='|/-\'
    while [ "$(ps a | awk '{print $1}' | grep $pid)" ]; do
        local temp=${spinstr#?}
        printf " [%c]  " "$spinstr"
        local spinstr=$temp${spinstr%"$temp"}
        sleep $delay
        printf "\b\b\b\b\b\b"
    done
    printf "    \b\b\b\b"
}

# Backup function for Fedora-like distributions
function fedora_backup {
    # Check if a previous backup is already present
    if [ -f "${BACKUP_DIR}/installed_packages.log" ]; then
        # Prompt the user to confirm whether they want to continue and overwrite the previous backup
        read -p "A previous backup is already present. Do you want to continue and overwrite it? (y/n) " -n 1 -r
        echo
        if [[ ! $REPLY =~ ^[Yy]$ ]]; then
            # Exit the script if the user does not want to continue
            exit 1
        fi
    fi

    # Start the spinning cursor animation in the background
    (spinner $BASHPID) &

    # Save the list of installed packages
    dnf list installed >$BACKUP_DIR/installed_packages.log

    # Save the list of enabled repositories
    dnf repolist >$BACKUP_DIR/enabled_repos.log

    # Export all trusted keys
    rpm -qa gpg-pubkey --qf '%{name}-%{version}-%{release} --> %{summary}\n' >$BACKUP_DIR/trusted_keys.log

    # Stop spinning cursor animation
    kill "$!"
}

# Restore function for Fedora-like distributions
function fedora_restore {
    # Start spinning cursor animation in background
    (spinner $BASHPID) &

    # Restore the list of enabled repositories
    dnf config-manager --set-enabled $(cat $BACKUP_DIR/enabled_repos.log | awk '{print $1}')

    # Import all trusted keys
    rpm --import $BACKUP_DIR/trusted_keys.log

    # Restore the list of installed packages
    dnf install $(cat $BACKUP_DIR/installed_packages.log | awk '{print $1}')

    # Stop spinning cursor animation
    kill "$!"
}

# Backup function for Ubuntu-like distributions
function ubuntu_backup {
    # Check if a previous backup is already present
    if [ -f "${BACKUP_DIR}/installed_packages.log" ]; then
        # Prompt the user to confirm whether they want to continue and overwrite the previous backup
        read -p "A previous backup is already present. Do you want to continue and overwrite it? (y/n) " -n 1 -r
        echo
        if [[ ! $REPLY =~ ^[Yy]$ ]]; then
            # Exit the script if the user does not want to continue
            exit 1
        fi
    fi

    # Start the spinning cursor animation in the background
    (spinner $BASHPID) &

    # Save the currently installed packages list
    dpkg --get-selections >$BACKUP_DIR/installed_packages.log

    # Make a backup of your apt sources file
    sudo cp /etc/apt/sources.list $BACKUP_DIR/sources.bak

    # Make a copy of your apt's list of trusted keys
    sudo apt-key exportall >$BACKUP_DIR/repositories.keys

    # Stop spinning cursor animation
    kill "$!"
}

# Restore function for Ubuntu-like distributions
function ubuntu_restore {
    # Start spinning cursor animation in background
    (spinner $BASHPID) &

    # Restore your apt sources file
    sudo cp $BACKUP_DIR/sources.bak /etc/apt/sources.list

    # Restore your apt's list of trusted keys
    sudo apt-key add $BACKUP_DIR/repositories.keys

    # Restore the list of installed packages
    sudo dpkg --set-selections <$BACKUP_DIR/installed_packages.log

    # Stop spinning cursor animation
    kill "$!"
}

# Backup function for Arch Linux-like distributions
function arch_backup {
    # Check if a previous backup is already present
    if [ -f "${BACKUP_DIR}/pkglist.txt" ]; then
        # Prompt the user to confirm whether they want to continue and overwrite the previous backup
        read -p "A previous backup is already present. Do you want to continue and overwrite it? (y/n) " -n 1 -r
        echo
        if [[ ! $REPLY =~ ^[Yy]$ ]]; then
            # Exit the script if the user does not want to continue
            exit 1
        fi
    fi

    # Start the spinning cursor animation in the background
    (spinner $BASHPID) &

    # Save the list of explicitly installed packages from the repositories and from the AUR
    pacman -Qqen >$BACKUP_DIR/pkglist.txt
    pacman -Qqem >$BACKUP_DIR/pkglist_aur.txt

    # Save the list of enabled repositories
    cp /etc/pacman.conf $BACKUP_DIR/pacman.conf.bak

    # Stop spinning cursor animation
    kill "$!"
}

# Restore function for Arch Linux-like distributions
function arch_restore {
    # Start spinning cursor animation in background
    (spinner $BASHPID) &

    # Restore the list of enabled repositories
    cp $BACKUP_DIR/pacman.conf.bak /etc/pacman.conf

    # Restore the list of explicitly installed packages from the repositories and from the AUR
    pacman -S --needed $(cat $BACKUP_DIR/pkglist.txt)

    # Stop spinning cursor animation
    kill "$!"
}

# Check command line arguments and perform backup or restore operation accordingly.
if [ "$1" == "backup" ]; then
    if [[ "$OS" == *"Fedora"* ]]; then fedora_backup; fi
    if [[ "$OS" == *"Ubuntu"* ]]; then ubuntu_backup; fi
    if [[ "$OS" == *"Arch"* ]]; then arch_backup; fi
elif [ "$1" == "restore" ]; then
    if [[ "$OS" == *"Fedora"* ]]; then fedora_restore; fi
    if [[ "$OS" == *"Ubuntu"* ]]; then ubuntu_restore; fi
    if [[ "$OS" == *"Arch"* ]]; then arch_restore; fi
else
    echo "Usage: $0 [backup|restore]"
fi

echo "Operation complete!"
