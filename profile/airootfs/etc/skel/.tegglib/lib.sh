#========================{HEADER}========================|
#AUTHOR: wellyton 'welly' <welly.tohn@gmail.com> 
#DESCRIPTION: programa para automatizar a criação
#             de arquivos vazios.
#LICENSE: MIT
#========================{ END }========================|

print(){
    printf '%s\n' "$1"
}

error(){
    print "$1"
    return 1
}

force_error(){
    return 1
}

success(){
    return 0
}

# TODO: make this shit works and progress save
# make this function dont duplicate progress key
write_progress(){
    PROGRESSKEY="$1"
    progress_file="$2"

    print "$1" >> "$2"

    if [[ $? -ne 0  ]]; then
	echo "Failed to write log"
	exit 1
    fi
}

make_partitions(){
    dialog --msgbox "Bem vindo ao instalador do tortoise! Para iniciar a instalação, crie suas partições no cfdisk." 0 0
    cfdisk
}

get_keymaps(){
    items=$(localectl list-keymaps)
    menu_options=()
    for item in $items; do
	menu_options+=("$item" "")
    done

    selected_keymap=$(dialog --clear --title "Seleção de Keymap" \
			     --menu "Escolha o seu keymap:" 0 0 0 "${menu_options[@]}" 3>&1 1>&2 2>&3)
}

get_language(){
    items=$(localectl list-locales)
    menu_options=()
    for item in $items; do
	menu_options+=("$item" "")
    done

    selected_encoding=$(dialog --clear --title "Seleção de linguagem" \
			     --menu "Escolha a sua linguagem:" 0 0 0 "${menu_options[@]}" 3>&1 1>&2 2>&3)
}

get_zoneinfo(){
    items=$(timedatectl list-timezones)
    menu_options=()
    for item in $items; do
	menu_options+=("$item" "")
    done
    
    selected_zoneinfo=$(dialog --clear --title "Seleção de timezone" \
			       --menu "Escolha o seu timezone:" 0 0 0 "${menu_options[@]}" 3>&1 1>&2 2>&3)
}

get_hostname(){
    selected_hostname=$(dialog --clear --title "Escolha um hostname" \
			       --inputbox "Escolha o seu hostname:" 0 0  3>&1 1>&2 2>&3)
}

get_username(){
    selected_username=$(dialog --clear --title "Escolha um hostname" \
			       --inputbox "Escolha o seu nome de usuário:" 0 0  3>&1 1>&2 2>&3)
}

get_userpasswd(){
    selected_userpasswd=$(dialog --clear --title "Senha de root" \
			       --passwordbox "Digite a senha de usuário:" 0 0  3>&1 1>&2 2>&3)    
}

get_rootpasswd(){
    selected_rootpasswd=$(dialog --clear --title "Senha de root" \
			       --passwordbox "Digite a senha de root:" 0 0  3>&1 1>&2 2>&3)    
}

copy_config_files(){
    
    print "Copy skel to new system"
    mkdir -p /mnt/etc/skel || echo "failed to create skel" 
    cp -vr /etc/skel/.config /mnt/etc/skel/ || echo "failed to copy .config to new root" 
    cp -v /etc/skel/.bashrc /mnt/etc/skel/ || echo "failed to copy .bashrc to new root" 
    cp -v /etc/skel/.bash_aliases /mnt/etc/skel/ || echo "failed to copy .bash_aliases to new root" 
    chmod -R u=rwX,g=rX,o= /mnt/etc/skel/ || echo "failed to take right permissions" 
    
    print "Copy display-manager config"
    if [ -f /home/turtle/.tortoise-essentials/display-manager.service ]; then
	cp -v /home/turtle/.tortoise-essentials/display-manager.service /mnt/etc/systemd/system/ || echo "Failed to copy display-manager.service" 
	chmod 644 /mnt/etc/systemd/system/display-manager.service || echo "Failed to give permissions" 
	print "display-manager.service copied successfully."
    else
	print "Error: display-manager.service not found."
	exit 1
    fi

}

gen_fstab(){
    print "Generate fstab"
    if genfstab -U /mnt > /mnt/etc/fstab; then
	print "fstab successfully generated."
    else
	print "Error generating fstab!"
	exit 1
    fi
}

set_keyboard(){
    print "setting keyboard"
    loadkeys "$1" || echo "Failed to load keyboards" 
}

make_ext4(){
    print "formating root"
    mkfs.ext4 "$1" || echo "Failed to format root partition" 
}

make_swap(){
    print "formating swap"
    mkswap "$1" || echo "Failed to format swap partition"
}

make_efi(){
    print "formating EFI"
    mkfs.fat -F 32 "$1" || echo "Failed to format boot/EFI partition"
}

mount_root(){
    print "mount $1 to /mnt"
    mount "$1" /mnt || echo "Failed to mount root partition"
}

mount_efi(){
    print "mount $1 to /mnt/boot"
    mount --mkdir "$1" /mnt/boot || echo "Failed to mount boot/EFI partition" 
}

mount_swap(){
    print "mount $1"
    swapon "$1" || echo "Failed to activate swap"
}

install_packages(){
    print "installing base system packages"
    pacstrap -K /mnt $(cat .tortoise-essentials/packages/packages) || echo "Failed to install packages to new root"

}

post_install(){
        arch-chroot /mnt /bin/bash <<EOF
printf  "%s\n" "enable display manager"
systemctl enable display-manager.service || echo "Failed to enable display-manager.service" 
systemctl enable NetworkManager || echo "Failed to enable NetworkManager" 

printf  "%s\n" "set zoneinfo to localtime file"
ln -sf $ZONEINFO /etc/localtime || echo "Failed to set timezone" 
hwclock --systohc || echo "Failed to update hardware clock" 

printf "%s\n" "creating locale.gen"
#sed -i '/^#en_US.UTF-8/s/^#//' /etc/locale.gen
sed -i "/^#$ENCODING/s/^#//" /etc/locale.gen || echo "Failed to modify locale.gen" 
locale-gen || echo "Failed to generate locales" 

printf "%s\n" "generate locale.conf"
echo "LANG=$ENCODING" > /etc/locale.conf || echo "Failed to write locale.conf" 

printf "%s\n" "setting up keyboard"
echo "KEYMAP=$KEYBOARD" > /etc/vconsole.conf || echo "Failed to wrife vconsole.conf" 

printf "%s\n" "set hostname"
echo "$HOSTNAME" > /etc/hostname || echo "Failed to set hostname" 

printf "%s\n" "running mkinitcpio"
mkinitcpio -P || echo "Failed to run mkinitcpio" 

printf "%s\n" "set root password"
echo "root:$ROOTPASSWD" | chpasswd || echo "Failed to set root password" 

printf "%s\n" "create user"
useradd "$USERNAME" -m || echo "Failed to create user" 

printf "%s\n" "set user password"
echo "$USERNAME:$USERPASSWD" | chpasswd || echo "Failed to create user password" 

printf "%s\n" "installing bootloader"
grub-install --target=x86_64-efi --efi-directory=/boot --bootloader-id=GRUB || echo "Failed on grub installation" 
grub-mkconfig -o /boot/grub/grub.cfg || echo "Failed to write grub.cfg configuration file" 

printf "%s\n" "installation complete!"

EOF
}

install_sys(){
    KEYBOARD="$selected_keymap"
    ENCODING="$seleted_encoding"
    ZONEINFO="$selected_zoneinfo"
    HOSTNAME="$selected_hostname"
    ROOTPASSWD="$selected_rootpasswd"
    USERNAME="$selected_username"
    USERPASSWD="$selected_userpasswd"

    set_keyboard "$KEYBOARD"

    make_ext4 "$ROOT"

    make_swap "$SWAP"

    make_efi "$EFI"

    print "mounting filesystem"

    mount_root "$ROOT"

    mount_efi "$EFI"

    mount_swap "$SWAP"

    install_packages

    gen_fstab

    copy_config_files || echo "Error when trying to copy config files" 

    print "join into system with arch-chroot"
    post_install || echo "Error when running post install commands"
}
