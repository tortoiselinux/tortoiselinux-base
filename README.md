# Tortoise Linux Base

This is the base profile for building the Tortoise ISO. 
All more complex ISO builds must be based on this repository.

## building the ISO

To build the ISO, make sure the following dependencies are installed

* base devel
* archiso

Now, run

    make

After that, if the build process completes successfully, you will have a fresh ISO in the iso/ folder

## How to bootstrap Installer

bootstrap tortoise installer is as simple as making an ISO

    sudo make prepare

## How to Install Tortoise

You can get information about how to install on: https://tortoiselinux.github.io/tortoiselinux/installation_guide
