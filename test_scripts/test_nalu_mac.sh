#!/bin/bash -l

#Script for running regression tests on a Mac using Spack and submitting results to CDash

set -e

# Set nightly directory where everything will go (will be created if it doesn't exist)
NALU_TESTING_DIR=${HOME}/TestNalu

# Set Nalu checkout directory and SPACK_ROOT
NALU_DIR=${NALU_TESTING_DIR}/Nalu
export SPACK_ROOT=${NALU_TESTING_DIR}/spack

# Set TMPDIR for openmpi on the Mac
export TMPDIR=/tmp

# Create and set up nightly directory with Spack if it doesn't exist
if [ ! -d "${NALU_TESTING_DIR}" ]; then
  mkdir -p ${NALU_TESTING_DIR}
  git clone https://github.com/LLNL/spack.git ${SPACK_ROOT}

  # Get some custom configurations for Spack and apply them
  git clone https://github.com/NaluCFD/NaluSpack.git ${NALU_TESTING_DIR}/NaluSpack
  cd ${NALU_TESTING_DIR}/NaluSpack/spack_config
  ./copy_config.sh

  # Checkout Nalu outside of Spack so ctest can build it itself
  git clone https://github.com/NaluCFD/Nalu.git ${NALU_DIR}
fi

# Load Spack
. ${SPACK_ROOT}/share/spack/setup-env.sh
# Make sure compilers are already loaded into Spack (this searches for all compilers in your path)
spack compilers &> /dev/null

# Test Nalu for gcc
for COMPILER_NAME in gcc
do
  # Set explicit compiler version (make sure it matches your Homebrew version)
  if [ ${COMPILER_NAME} == 'gcc' ]; then
    COMPILER_VERSION=6.3.0
  fi
  # Test Nalu for Trilinos master, develop
  for TRILINOS_BRANCH in master #develop
  do
    # Change to build directory
    cd ${NALU_DIR}/build
    # Uninstall Nalu and Trilinos; it's an error if they don't exist yet, but we skip it
    set +e
    spack uninstall -y nalu %${COMPILER_NAME}@${COMPILER_VERSION} ^nalu-trilinos@${TRILINOS_BRANCH}
    spack uninstall -y nalu-trilinos@${TRILINOS_BRANCH} %${COMPILER_NAME}@${COMPILER_VERSION}
    # Install Nalu and Trilinos
    spack install nalu %${COMPILER_NAME}@${COMPILER_VERSION} ^nalu-trilinos@${TRILINOS_BRANCH} ^openmpi@1.10.3 ^boost@1.60.0 ^hdf5@1.8.16 ^parallel-netcdf@1.6.1 ^netcdf@4.3.3.1
    # Manually adding cmake and openmpi to path; would prefer to use 'spack load', but
    # spack will not allow this until some time in the future on machines without environment modules
    export PATH=`spack location -i cmake %${COMPILER_NAME}@${COMPILER_VERSION}`/bin:${PATH}
    export PATH=`spack location -i openmpi %${COMPILER_NAME}@${COMPILER_VERSION}`/bin:${PATH}
    # Set the Trilinos and Yaml directories to pass to ctest
    TRILINOS_DIR=`spack location -i nalu-trilinos@${TRILINOS_BRANCH} %${COMPILER_NAME}@${COMPILER_VERSION}`
    YAML_DIR=`spack location -i yaml-cpp %${COMPILER_NAME}@${COMPILER_VERSION}`
    set -e
    # Clean the ctest build directory
    rm -r ${NALU_DIR}/build/*
    # Run ctest
    set +e
    ctest \
      -DNIGHTLY_DIR=${NALU_TESTING_DIR} \
      -DYAML_DIR=${YAML_DIR} \
      -DTRILINOS_DIR=${TRILINOS_DIR} \
      -DCOMPILER_NAME=${COMPILER_NAME} \
      -DTRILINOS_BRANCH=${TRILINOS_BRANCH} \
      -VV -S ${NALU_DIR}/reg_tests/CTestNightlyScript.cmake
    set -e
  done
done
