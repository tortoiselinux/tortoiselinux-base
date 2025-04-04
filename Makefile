build:
	sudo ./mkiso.sh

prepare: 
	[ -d "./install" ] && rm -rf ./install
	echo "clone git repo"
	git clone --depth=1 https://github.com/tortoiselinux/install.git
	cd install/ && make bootstrap
	echo "done!"

.PHONY: build prepare
