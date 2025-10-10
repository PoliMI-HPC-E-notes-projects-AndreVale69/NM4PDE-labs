#!/bin/bash

green='\033[0;32m'
red='\033[0;31m'
reset='\033[0m'

# Install dependencies, but if requirements.sh returns a non-zero exit code, stop the script
if ! ./requirements.sh; then
    # print error message in red
    printf "%b %s\n" "${red}\u00D7${reset}" "Failed to install requirements. Exiting..."
    exit 1
fi

printf "\n%b\n" "${green}~ Building project:${reset}"

mkdir -p "build" && cd "build" || exit 1
cmake .. --preset nm4pde-lab --log-level=WARNING || exit 1
cd nm4pde-lab || exit 1

# ask the user which example to run
printf "\n%b\n" "${green}~ Available labs:${reset}"
examples=("lab-1")
select example in "${examples[@]}"; do
    if [[ " ${examples[*]} " == *" $example "* ]]; then
        printf "\n%b %s\n" "${green}\u2714${reset}" "Running example: $example"
        ninja "$example" || exit 1
        cd ../.. || exit 1
        # set LD_LIBRARY_PATH to include arpack and hdf5 libraries, then run the example
        LD_LIBRARY_PATH=/u/sw/toolchains/gcc-glibc/11.2.0/pkgs/arpack/3.8.0/lib:/u/sw/toolchains/gcc-glibc/11.2.0/base/lib:/u/sw/toolchains/gcc-glibc/11.2.0/pkgs/hdf5/1.12.0/lib:$LD_LIBRARY_PATH ./build/nm4pde-lab/"$example"/"$example" || exit 1
        break
    else
        printf "%b %s\n" "${red}\u00D7${reset}" "Invalid option. Please try again."
    fi
done