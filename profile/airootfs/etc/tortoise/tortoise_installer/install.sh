#!/usr/bin/env bash
#========================{HEADER}========================|
#AUTHOR: wellyton 'welly' <welly.tohn@gmail.com>
#PROGRAM: install.sh 
#DESCRIPTION: Instalador do tortoise
#LICENSE: MIT
#========================{ END }=========================|

set -ex

source /etc/tortoise/tortoise_installer/lib.sh
source /etc/tortoise/tortoise_installer/logs/progress

[[ -v INSTALLFILE ]] || INSTALLFILE="/$HOME/install.conf"

source "$INSTALLFILE"

HOME=""

set_keyboard "$KEYBOARD"

make_ext4 "$ROOT"

make_swap "$SWAP"

make_efi "$EFI"

print "mounting filesystem"

mount_root "$ROOT"

mount_efi "$EFI"

mount_swap "$SWAP"

install_packages || error "Error when installing packages"

gen_fstab

copy_config_files || error "Error when trying to copy config files" 

print "join into system with arch-chroot"
post_install || error "Error when running post install commands"
