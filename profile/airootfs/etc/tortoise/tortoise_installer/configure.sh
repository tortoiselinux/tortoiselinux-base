#!/usr/bin/env bash
#========================{HEADER}========================|
#AUTHOR: wellyton 'welly' <welly.tohn@gmail.com>
#PROGRAM: configure.sh 
#DESCRIPTION: script para gerar informações que serão
#             utilizadas pelo installador do tortoise
#LICENSE: MIT
#========================{ END }=========================|

set -ex

INSTALLFILE="$HOME/install.conf"

source ./lib.sh
source ./logs/progress

case $1 in
    h | -h | help | --help)
	HELP
	;;
    
    f | -f | file | --file)
	INSTALLFILE="$2"
	;;

u | -u | update | --update)
    echo "UPDATE INSTALLER"
    
    mkdir -p /tmp/tortoise
    if ! git clone --depth=1 https://github.com/tortoiselinux/install.git /tmp/tortoise; then
        echo "Erro: Falha ao clonar o repositório." >&2
        exit 1
    fi

    if ! cd /tmp/tortoise/install; then
        echo "Erro: Falha ao entrar no diretório /tmp/tortoise/install." >&2
        exit 1
    fi

    if ! make; then
        echo "Erro: Falha ao executar make." >&2
        exit 1
    fi

    exit 0
    ;;
esac

source_or_create "$INSTALLFILE"

[[ $PARTITIONS == true ]] || (make_partitions && write_progress "PARTITIONS=true")

[[ -v EFI ]] || (get_efi && write_env_var "EFI" "$EFI" "$INSTALLFILE")
[[ -v SWAP ]] || (get_swap && write_env_var "SWAP" "$SWAP" "$INSTALLFILE")
[[ -v ROOT ]] || (get_root && write_env_var "ROOT" "$ROOT" "$INSTALLFILE")
[[ -v USERHOME ]] || write_env_var "USERHOME" "$USERHOME" "$INSTALLFILE"
[[ -v KEYBOARD ]] || (get_keymaps && write_env_var "KEYBOARD" "$KEYBOARD" "$INSTALLFILE")
[[ -v ENCODING ]] || (get_language && write_env_var "ENCODING" "$ENCODING" "$INSTALLFILE")
[[ -v ZONEINFO ]] || (get_zoneinfo && write_env_var "ZONEINFO" "$ZONEINFO" "$INSTALLFILE")
[[ -v USERHOSTNAME ]] || (get_hostname && write_env_var "USERHOSTNAME" "$USERHOSTNAME" "$INSTALLFILE")
[[ -v ROOTPASSWD ]] || (get_rootpasswd && write_env_var "ROOTPASSWD" "$ROOTPASSWD" "$INSTALLFILE")
[[ -v USERNAME ]] || (get_username && write_env_var "USERNAME" "$USERNAME" "$INSTALLFILE")
[[ -v USERPASSWD ]] || (get_userpasswd && write_env_var "USERPASSWD" "$USERPASSWD" "$INSTALLFILE")

get_packages

source "$INSTALLFILE"

{
    #echo "$INTERFACE" | tr ' ' '\n'
    echo "$DEVTOOLS" | tr ' ' '\n'
    echo "$INTERNET" | tr ' ' '\n'
    echo "$LANGUAGES" | tr ' ' '\n'
    cat /etc/tortoise/tortoise_installer/packages/essential-packages && echo ""
    cat /etc/tortoise/tortoise_installer/packages/i3wm-edition-essential-packages
} > /etc/tortoise/tortoise_installer/packages/packages
