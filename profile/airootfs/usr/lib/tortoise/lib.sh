#========================{HEADER}========================|
#AUTHOR: wellyton 'welly' <welly.tohn@gmail.com> 
#DESCRIPTION: biblioteca para criar scripts de instalação
#             do archiso.
#LIBNAME: LIBINSTALL.SH
#LICENSE: MIT
#========================{ END }========================|

red='\e[31m'
reset='\e[0m'

source /etc/tortoise/egginstall.conf

print(){
    local MSG="$1"
    printf '%s\n' "$MSG"
}

TODO(){
    print "THIS FEATURE IS NOT IMPLEMENTED YET"
}

error() {
  local MSG="$1"
  local EXIT_CODE="${2:-1}"
  local LOG_FILE="$LOGDIR/track.log"
  
  [[ -f "/etc/tortoise/egginstall.conf" ]] && \
      source "/etc/tortoise/egginstall.conf"

  mkdir -p "$(dirname "$LOG_FILE")"

  printf "\e[31m[ERRO] %s (Código: %d)\e[0m\n" "$MSG" "$EXIT_CODE" >&2
  printf "[%s] [ERRO] %s (Código: %d)\n" "$(date +"%Y-%m-%d %H:%M:%S")" \
	 "$MSG" "$EXIT_CODE" | tee -a "$LOG_FILE" >&2

  printf "Stack trace:\n" | tee -a "$LOG_FILE" >&2
  for i in $(seq 1 $((${#FUNCNAME[@]} - 1))); do
    local trace_msg="  -> ${FUNCNAME[$i]} (linha ${BASH_LINENO[$((i-1))]})"
    printf "%s\n" "$TRACE_MSG" | tee -a "$LOG_FILE" >&2
  done

  if [[ "$DEBUG" != "true" ]]; then
    exit "$EXIT_CODE"
  fi
}

non_fatal_error(){
    printf "${red}[ERROR]: %s ${reset}\\n" "${*}" 1>&2
    return 1
}

force_error(){
    return 1
}

success(){
    return 0
}

verify_and_source(){
    local FILEPATH="$1"
    [[ -f "$FILEPATH" ]] || error "$1 does't exist."
    source "$FILEPATH"
}

source_or_create(){
    local FILEPATH="$1"
    [[ -f "$FILEPATH" ]] || echo "" >> "$FILEPATH"
    source "$FILEPATH"
}

write_progress(){
    PROGRESSKEY="$1"
    PROGRESSFILE="$CHACHEDIR/progress"
    mkdir -m 0755 -p "$CACHEDIR"
    print "$PROGRESSKEY" >> "$PROGRESSFILE" || error "Failed to write log"
}

write_env_var(){
    KEY="$1"
    FILE="$2"
    touch "$FILE"
    sed -i "/^$(echo "$KEY" | cut -d= -f1)=/d" "$FILE"
    printf "\n%s\n" "$KEY" >> "$FILE"
}

make_partitions(){
    dialog --msgbox \
	   "Para iniciar a instalação, crie suas partições no cfdisk." 0 0
    cfdisk
}


get_efi(){
    EFI=$(dialog --stdout --title "PARTICIONAMENTO" --menu "Selecione a partição EFI" 0 0 0 \
		 $(lsblk -ln -o NAME,TYPE,SIZE | awk '$2=="part" {print "/dev/" $1 " " $3}'))
}

get_swap(){
    SWAP=$(dialog --stdout --title "PARTICIONAMENTO" --menu "Selecione a partição SWAP" 0 0 0  \
		  $(lsblk -ln -o NAME,TYPE,SIZE | awk '$2=="part" {print "/dev/" $1 " " $3}'))
}

get_root(){
    ROOT=$(dialog --stdout --title "PARTICIONAMENTO" --menu "Selecione a partição de ROOT " 0 0 0 \
		  $(lsblk -ln -o NAME,TYPE,SIZE | awk '$2=="part" {print "/dev/" $1 " " $3}'))   
}

get_keymaps(){
    items=$(localectl list-keymaps)
    menu_options=()
    for item in $items; do
	menu_options+=("$item" "")
    done

    KEYBOARD=$(dialog --clear --title "Seleção de Keymap" \
			     --menu "Escolha o seu keymap:" 0 0 0 \
			     "${menu_options[@]}" 3>&1 1>&2 2>&3)
}

get_language(){
    items=$(localectl list-locales)
    menu_options=()
    for item in $items; do
	menu_options+=("$item" "")
    done

    ENCODING=$(dialog --clear --title "Seleção de linguagem" \
			       --menu "Escolha a sua linguagem:" 0 0 0 \
			       "${menu_options[@]}" 3>&1 1>&2 2>&3)
}

get_zoneinfo(){
    items=$(timedatectl list-timezones)
    menu_options=()
    for item in $items; do
	menu_options+=("$item" "")
    done
    
    ZONEINFO=$(dialog --clear --title "Seleção de timezone" \
			       --menu "Escolha o seu timezone:" 0 0 0 \
			       "${menu_options[@]}" 3>&1 1>&2 2>&3)
}

get_hostname(){
    USERHOSTNAME=$(dialog --clear --title "Escolha um hostname" \
			       --inputbox "Escolha o seu hostname:" 0 0 \
			       3>&1 1>&2 2>&3)
}

get_username(){
    USERNAME=$(dialog --clear --title "Escolha um hostname" \
			       --inputbox "Escolha o seu nome de usuário:" \
			       0 0  3>&1 1>&2 2>&3)
}

get_userpasswd(){
    USERPASSWD=$(dialog --clear --title "Senha de root" \
				 --passwordbox "Digite a senha de usuário:" \
				 0 0  3>&1 1>&2 2>&3)    
}

get_rootpasswd(){
    ROOTPASSWD=$(dialog --clear --title "Senha de root" \
				 --passwordbox "Digite a senha de root:" \
				 0 0  3>&1 1>&2 2>&3)    
}

get_packages(){    
    INTERFACE=$(dialog --stdout --title "AMBIENTE GRÁFICO (DE/WM)" \
		       --checklist 'Escolha um Window manager ou Desktop Enviroment' 0 0 0 \
		       i3-wm 'light weight window manager' on 
		       # KDE '' off \
		       # gnome '' off \
		       # lxqt '' off \
		       # lxde '' off
	     )

    INTERNET=$(dialog --stdout --title "INTERNET" --checklist 'Softwares para navegar na rede' 0 0 0 \
		      firefox '' on \
		      qutebrowser '' off \
		      qbittorrent '' off \
		      chromium '' off \
		      thunderbird '' off \
		      discord '' off
	    )

    DEVTOOLS=$(dialog --stdout --title "DEVTOOLS" --checklist 'Ferramentas para desenvolvimento' 0 0 0 \
	              emacs '' on \
		      gnome-boxes '' off \
		      vim '' off \
		      neovim '' off \
		      micro '' on \
		      code '(Visual Studio Code)' off \
		      leafpad '' off \
		      nano '' off
	    )

    LANGUAGES=$(dialog --stdout --title "LINGUAGENS E COMPILADORES" \
		       --checklist 'Escolha quais linguagens devem ser instaladas' 0 0 0 \
		       lua '' on \
		       python '' off \
		       ruby '' off \
		       go '' off \
		       rustup '(rust installer)' off \
		       nodejs '(JavaScript)' off \
		       zig '' off \
		       php '' off
	     )
}

copy_config_files(){
    print "Copy skel to new system"
    mkdir -p /mnt/etc/skel ||  echo "Failed to create skel"
    mkdir -p /mnt/usr/share/backgrounds || echo "Failed to create backgrounds dir"
    
    # FILES
    cp -v $STATICDIR/files/.bashrc /mnt/etc/skel/ ||  \
	error "Failed to copy .bashrc to new root"
    cp -v $STATICDIR/files/.zshrc /mnt/etc/skel/ ||  \
	error "Failed to copy .zshrc to new root"
    cp -v $STATICDIR/files/.tortoise_aliases /mnt/etc/skel/ || \
	error "Failed to copy .tortoise_aliases to new root"
    cp -v $STATICDIR/files/picom.conf /mnt/etc/xdg/ || \
	error "Failed to copy picom.conf to new root"
    cp -v $STATICDIR/files/os-release /mnt/etc/ || \
	error "Failed to copy os-release to new root"
    
    # DIRECTORIES
    cp -vr $STATICDIR/files/backgrounds/* /mnt/usr/share/backgrounds || \
	error "Failed to copy backgrounds to new root"
    cp -vr $STATICDIR/files/.config /mnt/etc/skel/ || \
	error "Failed to copy .config to new root"
    cp -vr $STATICDIR/files/.oh-my-zsh /mnt/etc/skel/ || \
	error "Failed to copy .oh-my-zsh to new root"
    
    chmod -R u=rwX,g=rX,o= /mnt/etc/skel/ ||  echo "Failed to take right permissions" 

    print "Copy display-manager config"
    if [ -f $STATICDIR/files/lightdm.service ]; then
	rm /mnt/usr/lib/systemd/system/lightdm.service 
	cp -v $STATICDIR/files/lightdm.service /mnt/usr/lib/systemd/system/ || \
	     error "Failed to copy display-manager.service"
	chmod 644 /mnt/usr/lib/systemd/system/lightdm.service ||  echo "Failed to give permissions" 
	print "lightdm.service copied successfully."
    else
	print "Error: lightdm.service not found."
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
    local KEYBOARD="$1"
    loadkeys "$KEYBOARD" ||  error "Failed to load keyboards" 
}

make_ext4(){
    print "formating root"
    local PARTITION="$1"
    mkfs.ext4 "$PARTITION" ||  error "Failed to format root partition" 
}

make_swap(){
    print "formating swap"
    local PARTITION="$1"
    mkswap "$PARTITION" ||  error "Failed to format swap partition"
}

make_efi(){
    print "formating EFI"
    local PARTITION="$1"
    mkfs.fat -F 32 "$PARTITION" ||  error "Failed to format boot/EFI partition"
}

mount_root(){
    print "mount $1 to /mnt"
    local PARTITION="$1"
    mount "$PARTITION" /mnt ||  error "Failed to mount root partition"
}

mount_efi(){
    print "mount $1 to /mnt/boot"
    local PARTITION="$1"
    mount --mkdir "$PARTITION" /mnt/boot ||  error "Failed to mount boot/EFI partition" 
}

mount_swap(){
    print "mount $1"
    local PARTITION="$1"
    swapon "$PARTITION" ||  error "Failed to activate swap"
}

install_packages(){
    PGKLIST="$1"
    print "Installing base system packages"

    local attempts=5
    for ((i=1; i<=attempts; i++)); do
        pacstrap -K /mnt $(cat /home/turtle/packages) \
            --needed --overwrite '*' && return 0
        echo "Attempt $i/$attempts failed. Retrying..."
        sleep 5
    done
    error "Failed to install packages after $attempts attempts."
    return 1
}

enable_service(){
    local SERVICE="$1"
    arch-chroot /mnt /bin/bash -c "systemctl enable \"$SERVICE\""
}

set_timezone(){
    local ZONE="$1"
    arch-chroot /mnt /bin/bash -c "ln -sf \"$ZONE\" /etc/localtime"
}

update_hardware_clock(){
    arch-chroot /mnt /bin/bash -c 'hwclock --systohc'
}

generate_locale_gen(){
    LOCALE="$1"
    arch-chroot /mnt /bin/bash -c "sed -i \"/^#$LOCALE/s/^#//\" /etc/locale.gen"
    arch-chroot /mnt /bin/bash -c 'locale-gen' || error "Failed to generate locales"
}

generate_locale_conf(){
    ENCODE="$1"
    arch-chroot /mnt /bin/bash -c "echo \"LANG=$ENCODE\" > /etc/locale.conf"
}

write_vconsole(){
    BOARD="$1"
    arch-chroot /mnt /bin/bash -c "echo \"KEYMAP=$BOARD\" > /etc/vconsole.conf"
}

set_hostname(){
    local NAME="$1"
    arch-chroot /mnt /bin/bash -c "echo \"$NAME\" > /etc/hostname"
}

do_mkinitcpio(){
    arch-chroot /mnt /bin/bash -c 'mkinitcpio -P'
}

set_root_passwd(){
    local PASSWD="$1"
    arch-chroot /mnt /bin/bash -c "echo \"root:$PASSWD\" | chpasswd" 
}

create_user(){
    local NAME="$1"
    arch-chroot /mnt /bin/bash -c "useradd $NAME -m"
}

add_sudo_to_wheel(){
    arch-chroot /mnt /bin/bash -c "echo '%wheel ALL=(ALL:ALL) ALL' | EDITOR='tee -a' visudo && visudo -c"
}

give_root_perms(){
    NAME="$1"
    arch-chroot /mnt /bin/bash -c "usermod -aG wheel $NAME && id $NAME" 
}

set_user_passwd(){
    local NAME="$1"
    local PASSWD="$2"
    arch-chroot /mnt /bin/bash -c "echo \"$NAME:$PASSWD\" | chpasswd" 
}

install_x86_64_grub(){
    arch-chroot /mnt /bin/bash -c \
		'grub-install --target=x86_64-efi --efi-directory=/boot --bootloader-id=GRUB'
}

make_grub_config(){
    arch-chroot /mnt /bin/bash -c 'grub-mkconfig -o /boot/grub/grub.cfg'
}

update_fc_cache(){
    arch-chroot /mnt /bin/bash -c 'fc-cache -fv'
}

update_grub_default(){
    arch-chroot /mnt /bin/bash -c "echo 'GRUB_DISTRIBUTOR=\"Tortoise\"' >> /etc/default/grub"
}

change_shell(){
    SHELLPATH="$1"
    NAME="$2"
    arch-chroot /mnt /bin/bash -c "usermod --shell $SHELLPATH $NAME"
}

post_install(){
    print "Enable Systemd Services"
    enable_service lightdm.service || error "Failed to enable lightdm.service"
    enable_service NetworkManager || error "Failed to enable NetworkManager"

    print "Set zoneinfo to localtime file"
    set_timezone "$ZONEINFO" || error "Failed to set timezone"

    print "Update hardware Clock"
    update_hardware_clock || error "Failed to update hardware clock"

    print "Creating locale.gen"
    generate_locale_gen "$ENCODING" || error "Failed to modify locale.gen"
    
    print "Generate locale.conf"
    generate_locale_conf "$ENCODING" || error "Failed to write locale.conf" 
    
    print "Setting up keyboard"
    write_vconsole "$KEYBOARD" || error "Failed to wrife vconsole.conf" 

    print "Set hostname"
    set_hostname "$USERHOSTNAME" || error "Failed to set hostname" 

    print "Update font Cache"
    update_fc_cache || error "Failed to update font cache"
    
    print "Running mkinitcpio"
    do_mkinitcpio || error "Failed to run mkinitcpio"

    print "Set root password"
    set_root_passwd "$ROOTPASSWD"|| error "Failed to set root password" 

    print "Create user"
    create_user "$USERNAME" || error "Failed to create user" 

    print "Set user password"
    set_user_passwd "$USERNAME" "$USERPASSWD" || error "Failed to create user password" 

    print "Ensuring sudo permissions for wheel group"
    add_sudo_to_wheel || error "Failed to add sudo perms to wheel"

    print "Adding user to sudoers"
    give_root_perms "$USERNAME" || error "Failed to add user to sudoers"

    print "Switch to zsh"
    change_shell "/bin/zsh" "$USERNAME"
    
    print "Installing bootloader"
    install_x86_64_grub || error "Failed on grub installation"
    update_grub_default || error "Failed on update defaults"
    make_grub_config || error "Failed to write grub.cfg configuration file" 

    print "Installation complete!"

    dialog --title "Installation Complete! Rebooting in:" --pause "" 0 0 10
    if [[ $? -eq 1 ]]; then
	print "System will not reboot automatically"
    else
	print "Rebooting System properly"
	reboot
    fi
}
