#!/usr/bin/env bash


# bug: há um bug na hora de escolher a linguagem do sistema.
# bug: failed to run command: installation_commands, no such file or directory 

set -e

print(){
	printf '%s\n' "$1"
}

download_latest(){
    curl https://raw.githubusercontent.com/wellyton-xs/archiso_installer/refs/heads/main/install.sh -o "$1"
}

# PERIGO! executar isso sem ter o código atualizado no github pode ocasionar perdas.
check-updates(){
    print "checking for updates"
    download_latest /tmp/install.sh
    diff install.sh /tmp/install.sh
    if [["$?" == 1]]; then
	download_latest .
    elif [["$?" == 0]]; then
	print "everything is up to date! have a good installation"
    fi
}

#check-updates

EFI="/dev/vda1"
SWAP="/dev/vda2"
ROOT="/dev/vda3"

print "please wait 5s and create your partitions:"
sleep 5
cfdisk

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
    items=$(timedatectl list-timezones)
    menu_options=()
    for item in $items; do
	menu_options+=("$item" "")
    done
    
    selected_hostname=$(dialog --clear --title "Escolha um hostname" \
			       --inputbox "Escolha o seu hostname:" 0 0  3>&1 1>&2 2>&3)
}

get_rootpasswd(){
    items=$(timedatectl list-timezones)
    menu_options=()
    for item in $items; do
	menu_options+=("$item" "")
    done
    
    selected_rootpasswd=$(dialog --clear --title "Senha de root" \
			       --passwordbox "Digite a senha de root:" 0 0  3>&1 1>&2 2>&3)    
}

# run_command() {
#     local cmd="$1"   # O comando a ser executado
#     dialog --title "Log de Instalação" --programbox 500 500 < <(stdbuf -oL $cmd)
# }

installation_commands(){
    
    KEYBOARD="$selected_keymap"
    ENCODING="$seleted_encoding"
    ZONEINFO="$selected_zoneinfo"
    HOSTNAME="$selected_hostname"
    ROOTPASSWD="$selected_rootpasswd"

    print "setting keyboard"
    loadkeys "$KEYBOARD"

    print "formating root"
    mkfs.ext4 "$ROOT"

    print "formating swap"
    mkswap "$SWAP"

    print "formating EFI"
    mkfs.fat -F 32 "$EFI"

    print "mounting filesystem"

    print "mount $ROOT to /mnt"
    mount "$ROOT" /mnt

    print "mount $EFI to /mnt/boot"
    mount --mkdir "$EFI" /mnt/boot

    print "mount $SWAP"
    swapon "$SWAP"

    print "installing base system packages"
    pacstrap -K /mnt base linux linux-firmware grub efibootmgr

    print "generate fstab"
    genfstab -U /mnt >> /mnt/etc/fstab

    print "join into system with arch-chroot"
    arch-chroot /mnt /bin/bash <<EOF
printf  "%s\n" "set zoneinfo to localtime file"
ln -sf $ZONEINFO /etc/localtime
hwclock --systohc

printf "%s\n" "creating locale.gen"
#sed -i '/^#en_US.UTF-8/s/^#//' /etc/locale.gen
sed -i "/^#$ENCODING/s/^#//" /etc/locale.gen
locale-gen

printf "%s\n" "generate locale.conf"
echo "LANG=$ENCODING" > /etc/locale.conf

printf "%s\n" "setting up keyboard"
echo "KEYMAP=$KEYBOARD" > /etc/vconsole.conf

printf "%s\n" "create user"
echo "$HOSTNAME" > /etc/hostname

printf "%s\n" "running mkinitcpio"
mkinitcpio -P

printf "%s\n" "choose your password"
echo "root:$ROOTPASSWD" | chpasswd

printf "%s\n" "installing bootloader"
grub-install --target=x86_64-efi --efi-directory=/boot --bootloader-id=GRUB
grub-mkconfig -o /boot/grub/grub.cfg

printf "%s\n" "installation complete!"

EOF

}

get_keymaps
get_language
get_zoneinfo
get_hostname
get_rootpasswd
installation_commands
