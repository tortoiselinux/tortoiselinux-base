#!/usr/bin/env bash

get_installer(){
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
    cp -r configure.sh env files install.sh lib.sh LICENSE logs packages welly.conf ../profile/airootfs/etc/tortoise/tortoise_installer/
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
