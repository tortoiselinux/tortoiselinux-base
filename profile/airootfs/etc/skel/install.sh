#!/usr/bin/env bash
#========================{HEADER}========================|
#AUTHOR: wellyton 'welly' <welly.tohn@gmail.com>
#PROGRAM: install.sh 
#DESCRIPTION: Instalador do tortoise
#LICENSE: MIT
#========================{ END }=========================|

set -ex

source tortoise_installer/lib.sh
source tortoise_installer/logs/progress
source_or_create ./tortoise_installer/install.conf

ESSENTIAL_INSTALLATION_DATA="base linux linux-firmware grub efibootmgr sudo git curl wget dialog reflector i3 i3-wm i3blocks i3status rofi dmenu nemo lxappearance nitrogen lightdm lightdm-gtk-greeter lightdm-gtk-greeter-settings xfce4-terminal networkmanager"

HOME=""

[[ $PARTITIONS == true ]] || (make_partitions && write_progress "PARTITIONS=true" "tortoise_installer/logs/progress")

[[ -v EFI ]] || (get_efi && write_env_var "EFI" "$EFI")
[[ -v SWAP ]] || (get_swap && write_env_var "SWAP" "$SWAP")
[[ -v ROOT ]] || (get_root && write_env_var "ROOT" "$ROOT")
[[ -v USERHOME ]] || write_env_var "USERHOME" "$USERHOME"
[[ -v KEYBOARD ]] || (get_keymaps && write_env_var "KEYBOARD" "$KEYBOARD")
[[ -v ENCODING ]] || (get_language && write_env_var "ENCODING" "$ENCODING")
[[ -v ZONEINFO ]] || (get_zoneinfo && write_env_var "ZONEINFO" "$ZONEINFO")
[[ -v USERHOSTNAME ]] || (get_hostname && write_env_var "USERHOSTNAME" "$USERHOSTNAME")
[[ -v ROOTPASSWD ]] || (get_rootpasswd && write_env_var "ROOTPASSWD" "$ROOTPASSWD")
[[ -v USERNAME ]] || (get_username && write_env_var "USERNAME" "$USERNAME")
[[ -v USERPASSWD ]] || (get_userpasswd && write_env_var "USERPASSWD" "$USERPASSWD")

get_packages

source tortoise_installer/install.conf

{
    #echo "$INTERFACE" | tr ' ' '\n'
    echo "$DEVTOOLS" | tr ' ' '\n'
    echo "$INTERNET" | tr ' ' '\n'
    echo "$LANGUAGES" | tr ' ' '\n'
    cat /home/turtle/tortoise_installer/packages/essential-packages && echo ""
    cat /home/turtle/tortoise_installer/packages/i3wm-edition-essential-packages
} > /home/turtle/tortoise_installer/packages/packages

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
