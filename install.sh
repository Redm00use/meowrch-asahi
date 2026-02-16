#!/bin/bash

setfont cyr-sun16
clear

echo """
                          ▄▀▄     ▄▀▄           ▄▄▄▄▄
                         ▄█░░▀▀▀▀▀░░█▄         █░▄▄░░█
                     ▄▄  █░░░░░░░░░░░█  ▄▄    █░█  █▄█
                    █▄▄█ █░░▀░░┬░░▀░░█ █▄▄█  █░█   
███╗░░░███╗███████╗░█████╗░░██╗░░░░░░░██╗██████╗░░█████╗░██╗░░██╗
████╗░████║██╔════╝██╔══██╗░██║░░██╗░░██║██╔══██╗██╔══██╗██║░░██║
██╔████╔██║█████╗░░██║░░██║░╚██╗████╗██╔╝██████╔╝██║░░╚═╝███████║
██║╚██╔╝██║██╔══╝░░██║░░██║░░████╔═████║░██╔══██╗██║░░██╗██╔══██║
██║░╚═╝░██║███████╗╚█████╔╝░░╚██╔╝░╚██╔╝░██║░░██║╚█████╔╝██║░░██║
╚═╝░░░░░╚═╝╚══════╝░╚════╝░░░░╚═╝░░░╚═╝░░╚═╝░░╚═╝░╚════╝░╚═╝░░╚═╝
"""
echo
echo "Starting Asahi Linux (ARM64) pre-install..." && sleep 2

##==> Checking Architecture
#######################################################
ARCH=$(uname -m)
if [[ "$ARCH" != "aarch64" ]]; then
    echo "Error: This script is optimized for Asahi Linux (aarch64). Detected: $ARCH"
    exit 1
fi
#######################################################

##==> Initializing git submodules
#######################################################
if git rev-parse --is-inside-work-tree >/dev/null 2>&1; then
    echo "Initializing git submodules..."
    git submodule update --init --recursive
else
    echo "Error: This directory is not a git repository. Please clone the project using git clone."
    exit 1
fi
#######################################################


##==> Installing basic dependencies for pacman
#######################################################
# Removed base-devel/git here as they are usually pre-reqs, 
# but ensuring python/pip and rust (often needed for ARM builds)
dependencies=(python python-pip pkg-config)
for package in "${dependencies[@]}"; do
    if ! pacman -Q $package &> /dev/null; then
        sudo pacman -S --needed --noconfirm $package
    fi
done
#######################################################


##==> Installing python and dependencies for it
#######################################################
# REMOVED for Asahi: gputil, pyamdgpuinfo (x86/PCIe GPU specific, fail on ARM)
declare -a packages=(
	"inquirer"
	"loguru"
	"psutil"
	"colorama"
)

for package in "${packages[@]}"; do
    # Check if package is installed via pip
    if ! python -m pip show $package &> /dev/null; then
        echo "Installing $package..."
        # Using --break-system-packages as per Arch policy (or recommend venv)
        sudo python -m pip install $package --break-system-packages
    fi
done
#######################################################


##==> Building the system
#######################################################
python Builder/install.py
