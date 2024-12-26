#!/usr/bin/env bash
#========================{HEADER}========================|
#AUTHOR: wellyton 'welly' <welly.tohn@gmail.com>
#PROGRAM: install.sh 
#DESCRIPTION: Instalador do tortoise
#LICENSE: MIT
#========================{ END }========================|

# bug: há um bug na hora de escolher a linguagem do sistema.
# bug: .config do skel não copiado e install.sh continua no sistem instalado (resolvido)

#TODO: melhorar debbug e teste
set -ex

source .tegglib/lib.sh
source .logs/progress

#TODO: melhorar o sistema de particionamento

# dialog --title "MODELO DE INSTALAÇÃO" --menu "Escolha que tipo de instalação deseja fazer:" \
#        10 50 10 \
#        Default 'Todos os pacotes e configuração padrão' \
#        Custom 'escolha quais pacotes e configurações incluir no sistema final'

[[ $PARTITIONS == true ]] || make_partitions && write_progress "PARTITIONS=true" "./.logs/progress"

EFI=$(dialog --stdout --title "PARTICIONAMENTO" --menu "Selecione a partição EFI" 0 0 0 \
	     $(lsblk -ln -o NAME,TYPE,SIZE | awk '$2=="part" {print "/dev/" $1 " " $3}'))

SWAP=$(dialog --stdout --title "PARTICIONAMENTO" --menu "Selecione a partição SWAP" 0 0 0  \
	      $(lsblk -ln -o NAME,TYPE,SIZE | awk '$2=="part" {print "/dev/" $1 " " $3}'))

ROOT=$(dialog --stdout --title "PARTICIONAMENTO" --menu "Selecione a partição de ROOT " 0 0 0 \
	      $(lsblk -ln -o NAME,TYPE,SIZE | awk '$2=="part" {print "/dev/" $1 " " $3}'))

# HOME=$(dialog --stdout --title "PARTICIONAMENTO" --menu "Selecione a partição HOME" 0 0 0 \
# 	      $(lsblk -ln -o NAME,TYPE,SIZE | awk '$2=="part" {print "/dev/" $1 " " $3}'))


#TODO: dados de instalação em arquivo
# {
#     echo "EFI=$EFI"
#     echo "ROOT=$ROOT"
#     echo "SWAP=$SWAP"
#     echo "HOME=$HOME"
# } > ./data/partitions




ESSENTIAL_INSTALLATION_DATA="base linux linux-firmware grub efibootmgr sudo git curl wget dialog reflector i3 i3-wm i3blocks i3status rofi dmenu nemo lxappearance nitrogen lightdm lightdm-gtk-greeter lightdm-gtk-greeter-settings xfce4-terminal networkmanager"

# TODO: mais logs em todas as etapas
# TODO: guardar valores em um arquivo
# se a instalação falhar, o arquivo de processo é escrito, mas as variáveis se perdem.
# o script executará novamente como se tivesse tudo dado certo, mas os dados antes inseridos foram todos perdidos.
# a solução para isso será persistir esses dados em arquivo.
[[ $KEYMAPS == true ]] || get_keymaps && write_progress "KEYMAPS=true" "./.logs/progress"
[[ $LANGUAGE == true ]] || get_language && write_progress "LANGUAGE=true" "./.logs/progress"
[[ $ZONEINFO == true ]] || get_zoneinfo && write_progress "ZONEINFO=true" "./.logs/progress"
[[ $HOSTNAME == true ]] || get_hostname && write_progress "HOSTNAME=true" "./.logs/progress"
[[ $ROOTPASSWD == true ]] || get_rootpasswd && write_progress "ROOTPASSWD=true" "./.logs/progress"
[[ $USERNAME == true ]] || get_username && write_progress "USERNAME=true" "./.logs/progress"
[[ $USERPASSWD == true ]] || get_userpasswd && write_progress "USERPASSWD=true" "./.logs/progress"

INTERFACE=$(dialog --stdout --title "AMBIENTE GRÁFICO (DE/WM)" \
		   --checklist 'Escolha um Window manager ou Desktop Enviroment' 0 0 0 \
		   i3-wm 'light weight window manager' on \
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

{
    echo "$INTERFACE" | tr ' ' '\n'
    echo "$DEVTOOLS" | tr ' ' '\n'
    echo "$INTERNET" | tr ' ' '\n'
    echo "$LANGUAGES" | tr ' ' '\n'
    echo "$ESSENTIAL_INSTALLATION_DATA" | tr ' ' '\n'
} > /home/turtle/.tortoise-essentials/packages/packages

clear

#TODO: fazer todos os comandos de instalação funções reutilizáveis.
install_sys
