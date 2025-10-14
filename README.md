[![Conventional Commits](https://img.shields.io/badge/Conventional%20Commits-1.0.0-%23FE5196?logo=conventionalcommits&logoColor=white)](https://conventionalcommits.org)
![Website](https://img.shields.io/website?url=https%3A%2F%2Fpolimi-hpc-e-notes-projects-andrevale69.github.io%2FHPC-E-PoliMI-university-notes%2F&up_message=online&up_color=green&down_message=offline&down_color=red&logo=githubpages&label=Notes%20Website%20status)

# Lab - Numerical Methods for Partial Differential Equations

## Table of Contents

- [Overview](#overview)
- [Prerequisites](#prerequisites)
- [`run.sh` usage](#runsh-usage)
- [Usage Examples](#usage-examples)
  - [Interactive Example Selection](#interactive-example-selection)
  - [Non-Interactive Usage](#non-interactive-usage)
- [Notes](#notes)
- [Troubleshooting](#troubleshooting)

> [!IMPORTANT]  
> The helper script `run.sh` and the `nm4pde-lab` configure preset are intended for HPC systems (like PC's of Politecnico di Milano students) that provide compilers and libraries via [mk-style module stacks](https://github.com/pcafrica/mk)
> (the preset uses fixed toolchain paths under `/u/sw/toolchains/...`). 
> If you are not on such a system, do not use `./run.sh`, instead follow the "Manual build" instructions below or adapt `CMakePresets.json` to your local toolchain.
>  
> **Why use mk modules? Why configure a `CMakeLists.txt` file with `mk` modules?**
> 
> - **_Why use `mk` modules?_** The purpose of this repository is to provide a learning environment for numerical methods for PDEs, not to build a complex C++ project.
>   Since the courses are held at PoliMI, where students have access to HPC systems that use mk modules to manage software environments, the provided `run.sh` script and `CMakePresets.json` are tailored for that context.
> 
>- **_Why configure a `CMakeLists.txt` file with `mk` modules?_** I know that you could just load the mk modules in your shell and then run CMake.
>  However, I use IDEs like CLion or VSCode that invoke CMake in a clean environment without the mk modules loaded.
>  By configuring the `CMakeLists.txt` with the appropriate paths, I can ensure that the project builds correctly within these IDEs without needing to manually load mk modules each time.

### Overview

This repository was created to learn and practice PDE programming techniques taught in the
"Numerical Methods for Partial Differential Equations" course at Politecnico di Milano (PoliMI).
The materials and labs were adapted from the course exercises. For reference:

- Original labs repository: [michelebucelli/nmpde-labs-aa-24-25](https://github.com/michelebucelli/nmpde-labs-aa-24-25)
- Notes and explanations for these codes (provided by the repository creator): [HPC-E-PoliMI-university-notes](https://github.com/PoliMI-HPC-E-notes-projects-AndreVale69/HPC-E-PoliMI-university-notes)
- PDF notes site with full lecture/materials: [PoliMI Notes website](https://polimi-hpc-e-notes-projects-andrevale69.github.io/HPC-E-PoliMI-university-notes/)

This repository contains small labs and examples used in the Numerical Methods for Partial Differential Equations course.
The code demonstrates practical implementations for simple PDE problems
(Poisson 1D examples are provided in `lab-1` and `lab-2`).
It is intended as a learning reference and starting point for experiments.

> [!NOTE]
> You can download the `mk` tool from [pcafrica/mk](https://github.com/pcafrica/mk) github repository. Specifically, we use the version tagged [`v2024.0` in the release section](https://github.com/pcafrica/mk/releases/tag/v2024.0) (full version).

---

### Prerequisites
- CMake `>= 3.12`
- Ninja build (or another generator supported by CMake)
- A C++ compiler (the presets target GCC 11 and MPI C++ wrappers)
- `fzf` (required for interactive example selection with the keyboard)
- (Optional) On the HPC target: the toolchain and libraries referenced in the presets (deal.II, Boost, ARPACK, HDF5, etc.)

Quickstart (recommended on the target HPC system with `mk` modules)
1. Make the helper scripts executable (if not already):

   ```bash
   chmod +x requirements.sh run.sh
   ```

2. Run the helper to install/check requirements and build+run the examples:

   ```bash
   ./run.sh
   ```

The `run.sh` script will:
- Check/install local packages (via `requirements.sh`)
- Configure the project using the `nm4pde-lab` preset from `CMakePresets.json`
- Ask which example to build and run (select `lab-1` or `lab-2` for now)
- Build the selected example and run the produced executable with the appropriate `LD_LIBRARY_PATH` values from the preset environment.

Manual build (if not using `run.sh` or you need to adapt to a local machine)
- Using the preset (if your environment matches the preset paths):

```bash
mkdir -p build && cd build
cmake .. --preset nm4pde-lab
cmake --build build/nm4pde-lab -- -j
# or use ninja directly in the preset binary dir
```

- Manual configure (recommended if you don't have the HPC toolchain):

```bash
mkdir -p build && cd build
cmake .. -G Ninja -DCMAKE_BUILD_TYPE=Debug -DCMAKE_CXX_COMPILER=g++
cmake --build . -- -j
```

If your system uses MPI wrappers, set `MPI_CXX_COMPILER` accordingly, or configure `CMAKE_CXX_COMPILER` to the MPI C++ wrapper (`mpicxx`).

---

### `run.sh` usage
The `run.sh` helper script has improved UX and supports automatic preset selection and a small CLI. The script supports:

- `--preset NAME`: explicitly choose a CMake preset (for example `nm4pde-lab` or `local-debug`).
- `--presets`: print all available configure preset names from `CMakePresets.json` and exit (handy to know which presets you can pass to `--preset`).
- `--example NAME`: build and run the chosen example non-interactively. IMPORTANT: `--example` requires a non-empty NAME argument; calling `./run.sh --example` without a name will now print an error and exit instead of entering the interactive prompt loop.
- `-y` or `--yes`: non-interactive mode: assume "yes" at prompts.
- `NM4PDE_PRESET` environment variable: if set, it is used when `--preset` is not provided.

Auto-selection logic (default behavior)
- If `--preset` is provided, the script uses that preset.
- Else if `NM4PDE_PRESET` is set, it uses that value.
- Else if the mk toolchain path (`/u/sw/toolchains/gcc-glibc/11.2.0`) exists, the script defaults to `nm4pde-lab`.
- Else, if `mpicxx` and `g++` are available on the system, the script falls back to `local-debug`.
- If none of the above applies the script aborts with a short set of manual build instructions.

---

## Usage Examples

### Interactive Example Selection

To build and run any available lab, simply run:

```bash
./run.sh
```

You will be presented with an interactive menu (powered by `fzf`) to select which example to build and run. Use your keyboard to navigate and select the desired lab.

### Non-Interactive Usage

You can also build and run a specific example directly:

```bash
./run.sh --example lab-1
```

Or list all available labs:

```bash
./run.sh --list
```

Or list all available CMake presets:

```bash
./run.sh --presets
```

### Notes

- When using the `nm4pde-lab` preset, the script sets `LD_LIBRARY_PATH` to include ARPACK/HDF5 libraries from the mk toolchain.
- The `local-debug` preset uses `/usr/bin/g++` and `/usr/bin/mpicxx` for local development.
- If you add a new lab (e.g., `lab-3`), it will automatically appear in the interactive menu.

### Troubleshooting

- If you see errors about missing tools (e.g., `fzf`, `cmake`, `ninja`), run `./requirements.sh` to install them.
- If a build fails, check that your environment matches the requirements and that you have the correct toolchain or preset selected.
