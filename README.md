# Laboratory - Numerical Methods for Partial Differential Equations

**Important:** The helper script `run.sh` and the `nm4pde-lab` configure preset are intended for HPC systems (like PC's of Politecnico di Milano students) that provide compilers and libraries via [mk-style module stacks](https://github.com/pcafrica/mk)
(the preset uses fixed toolchain paths under `/u/sw/toolchains/...`).
If you are not on such a system, do not use `./run.sh` — instead follow the "Manual build" instructions below or adapt `CMakePresets.json` to your local toolchain.

## Overview

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

---

## Key points
- Two example labs are included: `lab-1` and `lab-2`.
- Build system: CMake (with CMake presets) + Ninja.
- The provided `CMakePresets.json` and `run.sh` are configured for an HPC toolchain (GCC, OpenMPI, deal.II, etc.)
  commonly exposed via mk-style module stacks. See the "mk modules / HPC note" below.

---

## mk modules / HPC note
- The included `run.sh` and the default `nm4pde-lab` configure preset assume an HPC environment where compilers and libraries
  are provided in fixed paths (as used by an mk-module setup). In this repository those paths appear under `/u/sw/toolchains/...`.
- If you are on that target system (or you have the same toolchain paths),
  `run.sh` will attempt to build and run the examples using the preset.
- If you do **NOT** use mk modules or you don't have the exact toolchain installed,
  use the Manual Build instructions below or adapt `CMakePresets.json` to point to your local compiler, MPI, and library locations.

---

## Prerequisites
- CMake >= 3.12
- Ninja build (or another generator supported by CMake)
- A C++ compiler (the presets target GCC 11 and MPI C++ wrappers)
- (Optional) On the HPC target: the toolchain and libraries referenced in the presets (deal.II, Boost, ARPACK, HDF5, etc.)

Quickstart (recommended on the target HPC system with mk modules)
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
- Ask which example to build and run (select `lab-1` or `lab-2`)
- Build the selected example and run the produced executable with the appropriate LD_LIBRARY_PATH values from the preset environment.

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

## Running the built examples
- After a successful build the executables are in `build/nm4pde-lab/` (or the equivalent binary dir you configured). Example:

```bash
./build/nm4pde-lab/lab-1/lab-1
```

Adapting `CMakePresets.json`
- If you want to keep the preset workflow but target a different toolchain, edit `CMakePresets.json` and update the paths for `CMAKE_CXX_COMPILER`, `MPI_CXX_COMPILER`, `DEAL_II_DIR`, `Boost_DIR`, and `CMAKE_PREFIX_PATH` to match your installation.

Project layout
- `lab-1/` and `lab-2/`: each lab contains a `CMakeLists.txt` and example source files (`main.cpp`, `Poisson1D.cpp`, `Poisson1D.hpp`).
- `CMakePresets.json`: convenience presets for the target HPC toolchain.
- `run.sh`: helper that uses the preset to configure, build and run examples (see mk-modules note above).
- `requirements.sh`: small helper to check for CMake and Ninja and optionally install them using apt (interactive).

---

## Adding new labs (template)

- Create a new directory `lab-N` where `N` is the lab number or short name.
- Add a `CMakeLists.txt` for the executable target. Keep the target name the same as the directory (for example, `lab-3` in `lab-3/`).
- Include source files (`main.cpp`, problem-specific sources like `Poisson1D.cpp`, and headers like `Poisson1D.hpp`).
- Keep examples self-contained: prefer to add small helper functions inside the lab directory rather than changing global CMake logic.

A minimal `CMakeLists.txt` template:

```cmake
# lab-N/CMakeLists.txt
add_executable(lab-N main.cpp Poisson1D.cpp)
# For simple projects no extra linking is required; add link_directories or target_link_libraries if needed.
```

---

## Future work
This repository is new and will grow. Possible future improvements:
- Add more labs covering time-dependent PDEs, finite-volume methods, and mesh adaptivity.
- Add tests that validate small numerical properties (convergence rates for manufactured solutions).
- Provide a `local` CMake preset (already included) and CI integration for automatic builds on push.
- Add a LICENSE file and contribution guidelines (CONTRIBUTING.md) once the set of exercises stabilizes.

---

## `run.sh` usage
The `run.sh` helper script has improved UX and supports automatic preset selection and a small CLI. The script now supports:

- `--preset NAME` — explicitly choose a CMake preset (for example `nm4pde-lab` or `local-debug`).
- `--presets` — print all available configure preset names from `CMakePresets.json` and exit (handy to know which presets you can pass to `--preset`).
- `--example NAME` — build and run the chosen example non-interactively. IMPORTANT: `--example` requires a non-empty NAME argument; calling `./run.sh --example` without a name will now print an error and exit instead of entering the interactive prompt loop.
- `-y` or `--yes` — non-interactive mode: assume "yes" at prompts.
- `NM4PDE_PRESET` environment variable — if set, it is used when `--preset` is not provided.

Auto-selection logic (default behavior)
- If `--preset` is provided, the script uses that preset.
- Else if `NM4PDE_PRESET` is set, it uses that value.
- Else if the mk toolchain path (`/u/sw/toolchains/gcc-glibc/11.2.0`) exists, the script defaults to `nm4pde-lab`.
- Else, if `mpicxx` and `g++` are available on the system, the script falls back to `local-debug`.
- If none of the above applies the script aborts with a short set of manual build instructions.

Examples

- List presets:

```bash
./run.sh --presets
```

- Build & run a specific example (non-interactive):

```bash
./run.sh --example lab-1 -y
```

- Requesting an example without a name now fails fast:

```bash
./run.sh --example
# prints error and usage, exit code != 0
```

Notes
- When `nm4pde-lab` is used the script sets an appropriate LD_LIBRARY_PATH to include ARPACK/HDF5 libraries found in the mk toolchain; when `local-debug` is used the script runs the executable directly.
- The `local-debug` preset targets `/usr/bin/g++` and `/usr/bin/mpicxx` and is intended for local laptop/desktop development.
