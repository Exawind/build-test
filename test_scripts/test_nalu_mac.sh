#!/bin/bash -l

# Script for running regression tests on a Mac using Spack and submitting results to CDash

# Set host name to pass to CDash
HOST_NAME="nalu-dev-osx.hpc.nrel.gov"

# Set some version numbers
GCC_COMPILER_VERSION="7.2.0"
CLANG_COMPILER_VERSION="5.0.0"
YAML_VERSION="develop"

# Set nightly directory and Nalu checkout directory
NALU_TESTING_DIR=${HOME}/NaluNightlyTesting
NALU_DIR=${NALU_TESTING_DIR}/Nalu
NALUSPACK_DIR=${NALU_TESTING_DIR}/NaluSpack

printf $(date)
printf "\n\n"

# Set spack location
export SPACK_ROOT=${NALU_TESTING_DIR}/spack

# Create and set up the entire testing directory if it doesn't exist
if [ ! -d "${NALU_TESTING_DIR}" ]; then
  printf "\n\nTop level testing directory doesn't exist. Creating everything from scratch...\n\n"

  # Make top level testing directory
  printf "\n\nCreating top level testing directory...\n\n"
  (set -x; mkdir -p ${NALU_TESTING_DIR})

  # Create and set up nightly directory with Spack installation
  printf "\n\nCloning Spack repo...\n\n"
  (set -x; git clone https://github.com/LLNL/spack.git ${SPACK_ROOT})

  # Configure Spack
  printf "\n\nConfiguring Spack...\n\n"
  (set -x; git clone https://github.com/NaluCFD/NaluSpack.git ${NALUSPACK_DIR})
  (set -x; cd ${NALUSPACK_DIR}/spack_config && ./setup_spack.sh)

  # Checkout Nalu and meshes submodule outside of Spack so ctest can build it itself
  printf "\n\nCloning Nalu repo...\n\n"
  (set -x; git clone --recursive https://github.com/NaluCFD/Nalu.git ${NALU_DIR})
fi

# Load Spack
printf "\n\nLoading Spack...\n\n"
. ${SPACK_ROOT}/share/spack/setup-env.sh

# Loop for trilinos branches
for TRILINOS_BRANCH in develop #master
do
  # Loop for compilers
  for COMPILER_NAME in gcc #clang
  do
    if [ ${COMPILER_NAME} == 'gcc' ]; then
      COMPILER_VERSION="${GCC_COMPILER_VERSION}"
    elif [ ${COMPILER_NAME} == 'clang' ]; then
      COMPILER_VERSION="${CLANG_COMPILER_VERSION}"
    fi
    printf "\n\nTesting Nalu with ${COMPILER_NAME}@${COMPILER_VERSION} and Trilinos ${TRILINOS_BRANCH} at $(date).\n\n"

    # Define TRILINOS and GENERAL_CONSTRAINTS from a single location for all scripts
    unset GENERAL_CONSTRAINTS
    source ${NALU_TESTING_DIR}/NaluSpack/spack_config/shared_constraints.sh
    printf "\n\nUsing constraints: ^yaml-cpp@${YAML_VERSION} ${GENERAL_CONSTRAINTS}\n\n"

    # Change to Nalu testing directory
    cd ${NALU_TESTING_DIR}

    # Load necessary modules
    #printf "\n\nLoading modules...\n\n"
    #module purge
    #module load gcc/5.2.0
    #module load python/2.7.8
 
    # Uninstall Nalu and Trilinos; it's an error if they don't exist yet, but we skip it
    printf "\n\nUninstalling Trilinos...\n\n"
    (set -x; spack uninstall -y ${TRILINOS}@${TRILINOS_BRANCH} %${COMPILER_NAME}@${COMPILER_VERSION} ${GENERAL_CONSTRAINTS})

    # Set the TMPDIR to disk so it doesn't run out of space
    #printf "\n\nMaking and setting TMPDIR to disk...\n\n"
    #mkdir -p /scratch/${USER}/.tmp
    #export TMPDIR=/scratch/${USER}/.tmp

    # Update Trilinos
    printf "\n\nUpdating Trilinos...\n\n"
    (set -x; spack cd ${TRILINOS}@${TRILINOS_BRANCH} %${COMPILER_NAME}@${COMPILER_VERSION} ${GENERAL_CONSTRAINTS} && pwd && git fetch --all && git reset --hard origin/${TRILINOS_BRANCH} && git clean -df && git status -uno)

    # Install Nalu and Trilinos
    printf "\n\nInstalling Nalu dependencies using ${COMPILER_NAME}@${COMPILER_VERSION}...\n\n"
    (set -x; spack install --keep-stage --only dependencies nalu %${COMPILER_NAME}@${COMPILER_VERSION} ^yaml-cpp@${YAML_VERSION} ^${TRILINOS}@${TRILINOS_BRANCH} ${GENERAL_CONSTRAINTS})

    # Load spack built cmake and openmpi into path
    printf "\n\nLoading Spack modules into environment...\n\n"
    # Refresh available modules (this is only really necessary on the first run of this script
    # because cmake and openmpi will already have been built and module files registered in subsequent runs)
    . ${SPACK_ROOT}/share/spack/setup-env.sh
    spack load cmake %${COMPILER_NAME}@${COMPILER_VERSION}
    spack load openmpi %${COMPILER_NAME}@${COMPILER_VERSION}

    # Set the Trilinos and Yaml directories to pass to ctest
    printf "\n\nSetting variables to pass to CTest...\n\n"
    TRILINOS_DIR=$(spack location -i ${TRILINOS}@${TRILINOS_BRANCH} %${COMPILER_NAME}@${COMPILER_VERSION} ${GENERAL_CONSTRAINTS})
    YAML_DIR=$(spack location -i yaml-cpp@${YAML_VERSION} %${COMPILER_NAME}@${COMPILER_VERSION})

    # Set the extra identifiers for CDash build description
    EXTRA_BUILD_NAME="-${COMPILER_NAME}-${COMPILER_VERSION}-trlns_${TRILINOS_BRANCH}"

    for RELEASE_OR_DEBUG in RELEASE #DEBUG
    do
      #if [[ ! (${COMPILER_NAME} == 'intel' && ${RELEASE_OR_DEBUG} == 'DEBUG') ]]; then
      # Make build type lowercase
      #BUILD_TYPE="$(tr [A-Z] [a-z] <<< "${RELEASE_OR_DEBUG}")"

      # Clean build directory; check if NALU_DIR is blank first
      if [ ! -z "${NALU_DIR}" ]; then
        printf "\n\nCleaning build directory...\n\n"
        (set -x; rm -rf ${NALU_DIR}/build/*)
      fi

      # Set warning flags for build
      WARNINGS="-Wall"
      export CXXFLAGS="${WARNINGS}"
      export CFLAGS="${WARNINGS}"
      export FFLAGS="${WARNINGS}"

      # Run ctest
      printf "\n\nRunning CTest at $(date)...\n\n"
      # Change to Nalu build directory
      cd ${NALU_DIR}/build
      (set -x; \
        export OMP_NUM_THREADS=1; \
        export OMP_PROC_BIND=false; \
        ctest \
        -DNIGHTLY_DIR=${NALU_TESTING_DIR} \
        -DYAML_DIR=${YAML_DIR} \
        -DTRILINOS_DIR=${TRILINOS_DIR} \
        -DHOST_NAME=${HOST_NAME} \
        -DRELEASE_OR_DEBUG=${RELEASE_OR_DEBUG} \
        -DEXTRA_BUILD_NAME=${EXTRA_BUILD_NAME} \
        -VV -S ${NALU_DIR}/reg_tests/CTestNightlyScript.cmake)
      printf "\n\nReturned from CTest at $(date)...\n\n"
      #fi
    done

    # Remove spack built cmake and openmpi from path
    printf "\n\nUnloading Spack modules from environment...\n\n"
    spack unload cmake %${COMPILER_NAME}@${COMPILER_VERSION}
    spack unload openmpi %${COMPILER_NAME}@${COMPILER_VERSION}

    #unset TMPDIR

    printf "\n\nDone testing Nalu with ${COMPILER_NAME}@${COMPILER_VERSION} and Trilinos ${TRILINOS_BRANCH} at $(date).\n\n"
  done
done

printf "\n\nDone!\n\n"
printf $(date)
