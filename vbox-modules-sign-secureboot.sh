#!/bin/sh

# This script is used to fix startup issues with VirtualBox on Fedora with Secure Boot enabled.
#
# Remember to check SELinux context for the script and the modules.
# sudo semanage fcontext -a -t bin_t '/[user]/.MOK/vbox-modules-sign-secureboot.sh'
# sudo restorecon -v /[user]/.MOK/vbox-modules-sign-secureboot.sh
#
# Configure the service in user's systemd (user must be sudoer NOPASSWD)
# /home/[user]/.config/systemd/user/vbox-modules-sign-secureboot.service
#
# [Unit]
# Description=Sign VirtualBox Modules
# After=network.target
# Before=vboxdrv.service
#
# [Service]
# ProtectHome=false
# ProtectSystem=false
# NoNewPrivileges=false
# Type=oneshot
# USER_HOME=$(eval echo ~${SUDO_USER})
# ExecStart=${USER_HOME}/.config/zsh/scripts/vbox-modules-sign-secureboot.sh
#
# [Install]
# WantedBy=default.target

for module in "vboxdrv" "vboxnetflt" "vboxnetadp"; do
  echo "Signing and loading module $module"
  sudo "/usr/src/kernels/$(uname -r)/scripts/sign-file" sha256 "${HOME}/.MOK/MOK.priv" "${HOME}/.MOK/MOK.der" "$(modinfo -n $module)" &&
    sudo modprobe "$module"
done
