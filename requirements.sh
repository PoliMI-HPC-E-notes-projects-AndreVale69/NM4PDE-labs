#!/bin/bash
# Description: Install required packages for building the project

green='\033[0;32m'
red='\033[0;31m'
reset='\033[0m'

printf "%b\n" "${green}~ Requirements check:"

# Check if cmake is installed
if command -v cmake &> /dev/null
then
    printf "%b %s\n" "${green}\u2714${reset}" "cmake is already installed"
else
    printf "%b %s\n" "${red}\u00D7${reset}" "CMake is not installed. Do you want to install it? (y/n)"
    read -r answer
    if [ "$answer" != "${answer#[Yy]}" ] ;then
        echo "Installing cmake..."
        sudo apt update -qq
        sudo apt install cmake -qq -y
    else
        echo "CMake is required to build the project. Exiting..."
        exit 1
    fi
fi

# Check if ninja-build is installed
if command -v ninja &> /dev/null
then
    printf "%b %s\n" "${green}\u2714${reset}" "ninja-build is already installed"
else
    printf "%b %s\n" "${red}\u00D7${reset}" "ninja-build is not installed. Do you want to install it? (y/n)"
    read -r answer
    if [ "$answer" != "${answer#[Yy]}" ] ;then
        echo "Installing ninja-build..."
        sudo apt update -qq
        sudo apt install ninja-build -qq -y
    else
        echo "ninja-build is required to build the project. Exiting..."
        exit 1
    fi
fi
