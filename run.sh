#!/usr/bin/env bash

# Improved run.sh with automatic preset selection, CLI flags, and non-interactive mode.

green='\033[0;32m'
red='\033[0;31m'
reset='\033[0m'

MK_TOOLCHAIN_DIR="/u/sw/toolchains/gcc-glibc/11.2.0"
PRESET=""
YES=0
EXAMPLE=""
LIST=0
PRESETS_LIST=0

# Directory where this script lives (used for discovering labs)
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

PRESET_FILE="$SCRIPT_DIR/CMakePresets.json"

# Discover available examples by scanning the repository's lab-* folders (early so --list works)
examples=()
for d in "$SCRIPT_DIR"/lab-*; do
    [ -d "$d" ] || continue
    # Only add if it contains a CMakeLists.txt (valid lab)
    if [ -f "$d/CMakeLists.txt" ]; then
        examples+=("$(basename "$d")")
    fi
    # fallback: add all directories if no CMakeLists.txt found
    if [ ${#examples[@]} -eq 0 ]; then
        examples+=("$(basename "$d")")
    fi
done
# Fallback to a conservative built-in list if discovery finds nothing
if [ ${#examples[@]} -eq 0 ]; then
    examples=("lab-1" "lab-2" "lab-2-ext")
fi

list_presets() {
    if [ ! -f "$PRESET_FILE" ]; then
        echo "CMakePresets.json not found at $PRESET_FILE"
        return 1
    fi

    if command -v python3 >/dev/null 2>&1; then
        python3 - <<PY
import json,sys
p=r"$PRESET_FILE"
try:
    data=json.load(open(p))
except Exception as e:
    sys.stderr.write(f"Failed to parse {p}: {e}\n")
    sys.exit(2)
for c in data.get('configurePresets', []):
    name=c.get('name')
    if name:
        print(name)
PY
        return $?
    elif command -v python >/dev/null 2>&1; then
        python - <<PY
import json,sys
p=r"$PRESET_FILE"
try:
    data=json.load(open(p))
except Exception as e:
    sys.stderr.write(f"Failed to parse {p}: {e}\n")
    sys.exit(2)
for c in data.get('configurePresets', []):
    name=c.get('name')
    if name:
        print(name)
PY
        return $?
    else
        # fallback: simple grep/sed approach (best-effort)
        grep -o '"name"[[:space:]]*:[[:space:]]*"[^"]\+"' "$PRESET_FILE" | sed -E 's/"name"[[:space:]]*:[[:space:]]*"([^"]+)"/\1/'
        return 0
    fi
}

print_help() {
    cat <<'EOF'
Usage: ./run.sh [--preset NAME] [--example NAME] [--list] [--presets] [-y|--yes] [--help]

Options:
  --preset NAME   Use given CMake preset (examples: nm4pde-lab, local-debug)
  --example NAME  Build and run the given example (non-interactive)
  --list          Print available examples and exit
  --presets       Print available CMake configure preset names from CMakePresets.json and exit
  -y, --yes       Non-interactive: assume "yes" at prompts
  -h, --help      Show this help message

Behavior:
  - If --preset is provided, it will be used.
  - Else, an environment variable NM4PDE_PRESET is checked.
  - Else, if the mk-toolchain path ($MK_TOOLCHAIN_DIR) exists, preset defaults to "nm4pde-lab".
  - Else, if system compilers `g++` and `mpicxx` are available, preset falls back to "local-debug".
  - If no valid preset can be determined, the script aborts with instructions to build manually.

Examples:
  ./run.sh                 # auto-detect preset, interactive example selection
  ./run.sh --list          # print available examples
  ./run.sh --presets       # print available CMake presets
  ./run.sh --example lab-1 -y   # non-interactive: build & run lab-1 with auto-selected preset
  ./run.sh --preset local-debug --example lab-2
EOF
}

# Parse arguments
while [[ $# -gt 0 ]]; do
    case "$1" in
        --preset)
            PRESET="$2"
            shift 2
            ;;
        --example)
            if [ -z "$2" ] || [[ "$2" == --* ]]; then
                echo -e "${red}\u00D7${reset} Error: --example requires a non-empty NAME argument."
                print_help
                exit 1
            fi
            EXAMPLE="$2"
            shift 2
            ;;
        --list)
            LIST=1
            shift
            ;;
        --presets)
            PRESETS_LIST=1
            shift
            ;;
        -y|--yes)
            YES=1
            shift
            ;;
        -h|--help|--usage)
            print_help && exit 0
            ;;
        *)
            echo "Unknown argument: $1"
            print_help
            exit 1
            ;;
    esac
done

# If user asked for presets, print and exit
if [ $PRESETS_LIST -eq 1 ]; then
    list_presets || exit 1
    exit 0
fi

# If user asked for list, print and exit
if [ $LIST -eq 1 ]; then
    echo "Available examples:"
    for e in "${examples[@]}"; do
        echo "  - $e"
    done
    exit 0
fi

# Honor environment override
if [ -z "$PRESET" ] && [ -n "$NM4PDE_PRESET" ]; then
    PRESET="$NM4PDE_PRESET"
fi

# Auto-select preset if not provided
if [ -z "$PRESET" ]; then
    if [ -d "$MK_TOOLCHAIN_DIR" ]; then
        PRESET="nm4pde-lab"
        echo "Using preset: $PRESET (found mk toolchain at $MK_TOOLCHAIN_DIR)"
    else
        # try to detect local toolchain
        if command -v mpicxx >/dev/null 2>&1 && command -v g++ >/dev/null 2>&1; then
            PRESET="local-debug"
            echo "mk toolchain not found; falling back to preset: $PRESET (found mpicxx and g++)"
        else
            echo -e "${red}\u26A0${reset} mk toolchain not found at $MK_TOOLCHAIN_DIR and required local compilers are missing."
            echo "Install g++ and mpicxx or run cmake manually. Example:"
            echo "  mkdir -p build && cd build"
            echo "  cmake .. -G Ninja -DCMAKE_BUILD_TYPE=Debug -DCMAKE_CXX_COMPILER=g++"
            echo "  cmake --build . -- -j"
            exit 1
        fi
    fi
fi

# If user asked for nm4pde-lab but mk-toolchain is missing, prompt (unless -y)
if [ "$PRESET" = "nm4pde-lab" ] && [ ! -d "$MK_TOOLCHAIN_DIR" ]; then
    echo -e "${red}\u26A0${reset} Preset 'nm4pde-lab' expects the mk toolchain at $MK_TOOLCHAIN_DIR but it was not found."
    if [ $YES -eq 1 ]; then
        echo "Non-interactive mode: continuing with 'nm4pde-lab' as requested. Expect failures if toolchain is absent."
    else
        read -r -p "Do you want to continue anyway with 'nm4pde-lab'? (y/N) " answer
        if [[ "$answer" != "${answer#[Yy]}" ]]; then
            echo "Continuing as requested..."
        else
            # Offer to switch to local-debug if available
            if command -v mpicxx >/dev/null 2>&1 && command -v g++ >/dev/null 2>&1; then
                read -r -p "Switch to 'local-debug' preset instead? (Y/n) " answer2
                if [[ -z "$answer2" || "$answer2" != "${answer2#[Nn]}" ]]; then
                    PRESET="local-debug"
                    echo "Switching to preset: $PRESET"
                else
                    echo "Aborting as requested. To build locally, run:"
                    echo "  mkdir -p build && cd build"
                    echo "  cmake .. --preset local-debug"
                    echo "  cmake --build build/local-debug -- -j"
                    exit 1
                fi
            else
                echo "Aborting as requested. To build locally, install mpicxx/g++ or adapt CMakePresets.json."
                exit 1
            fi
        fi
    fi
fi

# Finally show selected preset
echo "Selected preset: $PRESET"

# Install dependencies (same behavior as before)
if ! ./requirements.sh; then
    echo -e "${red}\u00D7${reset} Failed to install requirements. Exiting..."
    exit 1
fi

# Build using the chosen preset
printf "\n%b\n" "${green}~ Building project with preset: $PRESET${reset}"

mkdir -p "build" && cd "build" || exit 1
cmake .. --preset "$PRESET" --log-level=WARNING || exit 1
cd "$PRESET" || exit 1

# Verify EXAMPLE if provided
if [ -n "$EXAMPLE" ]; then
    found=0
    for e in "${examples[@]}"; do
        if [ "$e" = "$EXAMPLE" ]; then
            found=1
            break
        fi
    done
    if [ $found -eq 0 ]; then
        echo -e "${red}\u00D7${reset} Example '$EXAMPLE' not found. Available examples: ${examples[*]}"
        exit 1
    fi
fi

# Non-interactive: pick the first example automatically or use provided EXAMPLE
if [ $YES -eq 1 ]; then
    if [ -n "$EXAMPLE" ]; then
        example="$EXAMPLE"
    else
        example="${examples[0]}"
    fi
    echo "Non-interactive mode: selected example: $example"
    printf "\n%b %s\n" "${green}\u2714${reset}" "Running example: $example"
    ninja "$example" || exit 1
    cd ../.. || exit 1
    if [ "$PRESET" = "nm4pde-lab" ]; then
        LD_LIBRARY_PATH=/u/sw/toolchains/gcc-glibc/11.2.0/pkgs/arpack/3.8.0/lib:/u/sw/toolchains/gcc-glibc/11.2.0/base/lib:/u/sw/toolchains/gcc-glibc/11.2.0/pkgs/hdf5/1.12.0/lib:$LD_LIBRARY_PATH ./build/"$PRESET"/"$example"/"$example" || exit 1
    else
        ./build/"$PRESET"/"$example"/"$example" || exit 1
    fi
    exit 0
fi

# If EXAMPLE provided and not non-interactive, run it directly
if [ -n "$EXAMPLE" ]; then
    example="$EXAMPLE"
    echo "Selected example: $example"
    printf "\n%b %s\n" "${green}\u2714${reset}" "Running example: $example"
    ninja "$example" || exit 1
    cd ../.. || exit 1
    if [ "$PRESET" = "nm4pde-lab" ]; then
        LD_LIBRARY_PATH=/u/sw/toolchains/gcc-glibc/11.2.0/pkgs/arpack/3.8.0/lib:/u/sw/toolchains/gcc-glibc/11.2.0/base/lib:/u/sw/toolchains/gcc-glibc/11.2.0/pkgs/hdf5/1.12.0/lib:$LD_LIBRARY_PATH ./build/"$PRESET"/"$example"/"$example" || exit 1
    else
        ./build/"$PRESET"/"$example"/"$example" || exit 1
    fi
    exit 0
fi

# Interactive selection using fzf if available, else fallback to select
choose_example() {
    local choice
    if command -v fzf >/dev/null 2>&1; then
        choice=$(printf '%s\n' "${examples[@]}" | fzf --prompt="Select lab: ")
        echo "$choice"
    else
        echo "(Tip: install 'fzf' for a better interactive menu with arrow keys)"
        select choice in "${examples[@]}"; do
            if [[ -n "$choice" ]]; then
                echo "$choice"
                break
            else
                echo "Invalid option. Please try again."
            fi
        done
    fi
}

# ask the user which example to run (interactive)
printf "\n%b\n" "${green}~ Available labs:${reset}"
example=$(choose_example)
if [[ -z "$example" ]]; then
    echo -e "${red}\u00D7${reset} No lab selected. Exiting."
    exit 1
fi
printf "\n%b %s\n" "${green}\u2714${reset}" "Running example: $example"
ninja "$example" || exit 1
cd ../.. || exit 1
# Run with special LD_LIBRARY_PATH only for nm4pde-lab preset
if [ "$PRESET" = "nm4pde-lab" ]; then
    LD_LIBRARY_PATH=/u/sw/toolchains/gcc-glibc/11.2.0/pkgs/arpack/3.8.0/lib:/u/sw/toolchains/gcc-glibc/11.2.0/base/lib:/u/sw/toolchains/gcc-glibc/11.2.0/pkgs/hdf5/1.12.0/lib:$LD_LIBRARY_PATH ./build/"$PRESET"/"$example"/"$example" || exit 1
else
    ./build/"$PRESET"/"$example"/"$example" || exit 1
fi
