#!/bin/bash
# Backup and restore script for home directory using rsync and tar

# Set the backup/restore directory
BACKUP_DIR=~/.local/share/backup/$(basename $0 .sh)

# Create the backup/restore directory
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

# Backup function
function backup_home {
    # Check if a previous backup is already present
    if [ -d "$BACKUP_DIR" ] && [ "$(ls -A $BACKUP_DIR)" ]; then
        # Prompt the user to confirm whether they want to continue and overwrite the previous backup
        read -p "A previous backup is already present. Do you want to continue and overwrite it? (y/n) " -n 1 -r
        echo
        if [[ ! $REPLY =~ ^[Yy]$ ]]; then
            # Exit the script if the user does not want to continue
            exit 1
        fi
    fi

    # Set the directories to exclude
    local EXCLUDE_DIRS=(".cache" ".cargo/registry" ".go" ".local/share" ".mozilla" ".var" "chrome" "edge" "Downloads" "mnt" "onedrive" "onedriveFratelliCarli" "Pictures" "tmp" "Videos")

    # Add the backup directory to the list of excluded directories
    EXCLUDE_DIRS+=("$(realpath --relative-to=$HOME $BACKUP_DIR)")

    # Create the exclude options for the rsync command
    local EXCLUDE_OPTS=()
    for dir in "${EXCLUDE_DIRS[@]}"; do
        EXCLUDE_OPTS+=("--exclude=${dir}")
    done

    # Check if tar option is specified
    if [ "$2" == "tar" ]; then
        # Create the exclude options for the tar command
        local TAR_EXCLUDE_OPTS=()
        for dir in "${EXCLUDE_DIRS[@]}"; do
            TAR_EXCLUDE_OPTS+=("--exclude=${dir}")
        done

        # Start the spinning cursor animation in the background
        (spinner $BASHPID) &

        # Create the backup as a tar file with best compression
        echo "Starting backup..."
        tar "${TAR_EXCLUDE_OPTS[@]}" -czf ${BACKUP_DIR}/home_backup.tar.gz ~/
        echo "Backup complete!"

        # Stop the spinning cursor animation
        kill "$!"
    else
        # Start the spinning cursor animation in the background
        (spinner $BASHPID) &

        # Create the backup using rsync
        echo "Starting backup..."
        rsync -aP "${EXCLUDE_OPTS[@]}" ~/ $BACKUP_DIR/
        echo "Backup complete!"

        # Stop the spinning cursor animation
        kill "$!"
    fi

    # Calculate the size of the backup in bytes
    local BACKUP_SIZE=$(du -sb $BACKUP_DIR | awk '{print $1}')

    # Check if the size of the backup is below 1 GB
    if [ $BACKUP_SIZE -lt 1073741824 ]; then
        # Display the size of the backup in MB
        echo "Size of backup: $(($BACKUP_SIZE / 1048576)) MB"
    else
        # Display the size of the backup in GB
        echo "Size of backup: $(($BACKUP_SIZE / 1073741824)) GB"
    fi
}

# Restore function
function restore_home {
    # Check if tar option is specified
    if [ "$2" == "tar" ]; then

        # Start the spinning cursor animation in the background
        (spinner $BASHPID) &

        # Extract the backup from tar file
        echo "Starting restore..."
        tar -xzf ${BACKUP_DIR}/home_backup.tar.gz -C /
        echo "Restore complete!"

        # Stop spinning cursor animation
        kill "$!"

    else
        # Start spinning cursor animation in background
        (spinner $BASHPID) &

        # Restore using rsync
        echo "Starting restore..."
        rsync -aP $BACKUP_DIR/ ~/
        echo "Restore complete!"

        # Stop spinning cursor animation
        kill "$!"
    fi
}

# Display usage message
function display_usage {
    echo "Usage: $0 [backup|restore] [tar]"
    echo ""
    echo "This script performs backup and restore operations for your home directory."
    echo ""
    echo "Options:"
    echo "  backup       Perform a backup operation"
    echo "  restore      Perform a restore operation"
    echo "  tar          Use tar to create a compressed backup file (optional)"
}

# Check command line arguments and perform backup or restore operation accordingly.
if [ "$1" == "--help" ]; then
    display_usage
elif [ "$1" == "backup" ]; then
    backup_home $1 $2
elif [ "$1" == "restore" ]; then
    restore_home $1 $2
else
    display_usage
fi
