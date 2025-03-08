#!/usr/bin/env bash
set -xe
get_installer(){
    SCRIPTS="configure.sh install.sh"
    FILES="env lib.sh welly.conf LICENSE"
    DIRS="files logs packages"

    echo "verify files"
    [ -d install/ ] && rm -r install/
    echo "..."
    [ -d profile/airootfs/etc/tortoise/tortoise_installer/ ] && \
	rm -r profile/airootfs/etc/tortoise/tortoise_installer/
    echo "..."
    [ -d profile/airootfs/etc/tortoise/tortoise_installer/ ] || \
	mkdir profile/airootfs/etc/tortoise/tortoise_installer/
    echo "..."
    echo "done!"

    echo "clone git repo"
    git clone --depth=1 https://github.com/tortoiselinux/install.git
    cd install/
    
    echo "copy files to profile"

    install -m 755 -C $SCRIPTS ../profile/airootfs/etc/tortoise/tortoise_installer/

    echo "Copying Files..."
    install -m 644 -C $FILES ../profile/airootfs/etc/tortoise/tortoise_installer/

    echo "Copying directories..."
    for dir in $DIRS; do cp -r $dir ../profile/airootfs/etc/tortoise/tortoise_installer/; done
    echo "done!"
}

case $1 in
    installer)
	get_installer
	;;
    profile)
	#TODO: GET LATEST PROFILE AND MOVE TORTOISE FILES TO IT
	;;
    
esac
