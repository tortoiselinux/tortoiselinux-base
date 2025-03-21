#!/usr/bin/env bash
set -xe
get_installer(){
	[[ -d "./install" ]] && rm -rf ./install
    echo "clone git repo"
    git clone --depth=1 https://github.com/tortoiselinux/install.git
    cd install/
    make prepare
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
