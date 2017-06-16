#!/bin/bash -l

# This script is pretty far out-of-date at the moment

# Set nightly directory and Nalu checkout directory
NALU_TESTING_DIR=${HOME}/TestNalu
NALU_DIR=${NALU_TESTING_DIR}/Nalu

# Set host name to pass to CDash
HOST_NAME="mymac_name"

# Set spack location
export SPACK_ROOT=${NALU_TESTING_DIR}/spack

# Set TMPDIR for openmpi on the Mac
export TMPDIR=/tmp

# Uncomment this if statement to create and set up
# a testing directory if it doesn't exist
#if [ ! -d "${NALU_TESTING_DIR}" ]; then
#  mkdir -p ${NALU_TESTING_DIR}
#
#  # Create and set up nightly directory with Spack installation
#  printf "\n\nCloning Spack repo...\n\n"
#  git clone https://github.com/LLNL/spack.git ${SPACK_ROOT}
#
#  # Configure Spack for Nalu
#  printf "\n\nConfiguring Spack...\n\n"
#  cd ${NALU_TESTING_DIR} && git clone https://github.com/NaluCFD/NaluSpack.git
#  cd ${NALU_TESTING_DIR}/NaluSpack/spack_config
#  ./copy_config.sh
#
#  # Checkout Nalu and meshes submodule outside of Spack so ctest can build it itself
#  printf "\n\nCloning Nalu repo...\n\n"
#  git clone --recursive https://github.com/NaluCFD/Nalu.git ${NALU_DIR}
#
#  # Create a jobs directory
#  printf "\n\nMaking job output directory...\n\n"
#  mkdir -p ${NALU_TESTING_DIR}/jobs
#fi

# Load Spack
. ${SPACK_ROOT}/share/spack/setup-env.sh

# Make sure compilers are already loaded into Spack (this searches for all compilers in your path)
spack compilers &> /dev/null

# Test Nalu for trilinos master, develop
for TRILINOS_BRANCH in master #develop
do
  # Test Nalu for gcc, clang
  for COMPILER_NAME in gcc #clang
  do
    printf "\n\nTesting Nalu with ${COMPILER_NAME}@${COMPILER_VERSION} and Trilinos ${TRILINOS_BRANCH}.\n\n"

    # Set explicit compiler version (make sure it matches your Homebrew version)
    if [ ${COMPILER_NAME} == 'gcc' ]; then
      COMPILER_VERSION=6.3.0
    elif [ ${COMPILER_NAME} == 'clang' ]; then
      COMPILER_VERSION=8.0.0-apple
    fi

    # Change to Nalu testing directory
    cd ${NALU_TESTING_DIR}

    # Uninstall Nalu and Trilinos; it's an error if they don't exist yet, but we skip it
    printf "\n\nUninstalling Nalu and Trilinos...\n\n"
    spack uninstall -y nalu %${COMPILER_NAME}@${COMPILER_VERSION} ^nalu-trilinos@${TRILINOS_BRANCH}
    spack uninstall -y nalu-trilinos@${TRILINOS_BRANCH} %${COMPILER_NAME}@${COMPILER_VERSION}

    # Update Nalu and Trilinos
    printf "\n\nPulling Nalu and Trilinos updates...\n\n"
    spack cd nalu %${COMPILER_NAME}@${COMPILER_VERSION} ^nalu-trilinos@${TRILINOS_BRANCH} ^openmpi@1.10.3 ^boost@1.60.0 ^hdf5@1.8.16 ^parallel-netcdf@1.6.1 ^netcdf@4.3.3.1 && pwd && git pull
    spack cd nalu-trilinos@${TRILINOS_BRANCH} %${COMPILER_NAME}@${COMPILER_VERSION} ^openmpi@1.10.3 ^boost@1.60.0 ^hdf5@1.8.16 ^parallel-netcdf@1.6.1 ^netcdf@4.3.3.1 && pwd && git pull

    # Install Nalu and Trilinos
    printf "\n\nInstalling Nalu using ${COMPILER_NAME}...\n\n"
    spack install --keep-stage nalu %${COMPILER_NAME}@${COMPILER_VERSION} ^nalu-trilinos@${TRILINOS_BRANCH} ^openmpi@1.10.3 ^boost@1.60.0 ^hdf5@1.8.16 ^parallel-netcdf@1.6.1 ^netcdf@4.3.3.1

    # Load spack built cmake and openmpi into path
    printf "\n\nLoading Spack modules into environment...\n\n"
    # Manually adding cmake and openmpi to path; would prefer to use 'spack load', but
    # spack will not allow this until some time in the future on machines without environment modules
    export PATH=`spack location -i cmake %${COMPILER_NAME}@${COMPILER_VERSION}`/bin:${PATH}
    export PATH=`spack location -i openmpi %${COMPILER_NAME}@${COMPILER_VERSION}`/bin:${PATH}

    # Set the Trilinos and Yaml directories to pass to ctest
    printf "\n\nSetting variables to pass to CTest...\n\n"
    TRILINOS_DIR=`spack location -i nalu-trilinos@${TRILINOS_BRANCH} %${COMPILER_NAME}@${COMPILER_VERSION}`
    YAML_DIR=`spack location -i yaml-cpp %${COMPILER_NAME}@${COMPILER_VERSION}`

    # Set the extra identifiers for CDash build description
    EXTRA_BUILD_NAME="-${COMPILER_NAME}-trlns_${TRILINOS_BRANCH}"

    # Change to Nalu build directory
    cd ${NALU_DIR}/build

    # Clean build directory; checkout if NALU_DIR is not blank first
    if [ ! -z "${NALU_DIR}" ]; then
      printf "\n\nCleaning build directory...\n\n"
      rm -rf ${NALU_DIR}/build/*
    fi

    # Run ctest
    printf "\n\nRunning CTest...\n\n"
    ctest \
      -DNIGHTLY_DIR=${NALU_TESTING_DIR} \
      -DYAML_DIR=${YAML_DIR} \
      -DTRILINOS_DIR=${TRILINOS_DIR} \
      -DHOST_NAME=${HOST_NAME} \
      -DEXTRA_BUILD_NAME=${EXTRA_BUILD_NAME} \
      -VV -S ${NALU_DIR}/reg_tests/CTestNightlyScript.cmake
    printf "\n\nReturned from CTest...\n\n"

    printf "\n\nDone testing Nalu with ${COMPILER_NAME} and Trilinos ${TRILINOS_BRANCH}.\n\n"
  done
done

