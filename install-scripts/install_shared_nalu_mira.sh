#!/bin/bash

#Script for installing Nalu-Wind on Mira using Spack with GCC compiler

# Function for printing and executing commands
cmd() {
  echo "+ $@"
  eval "$@"
}

set -e

INSTALL_DIR=/projects/ExaWindFarm/software
BUILD_TEST_DIR=${INSTALL_DIR}/build-test

# Set spack location
export SPACK_ROOT=${INSTALL_DIR}/spack

if [ ! -d "${INSTALL_DIR}" ]; then
  printf "============================================================\n"
  printf "Install directory doesn't exist.\n"
  printf "Creating everything from scratch...\n"
  printf "============================================================\n"

  printf "Creating top level install directory...\n"
  cmd "mkdir -p ${INSTALL_DIR}"

  printf "\nCloning Spack repo...\n"
  cmd "git clone https://github.com/spack/spack.git ${SPACK_ROOT}"

  printf "\nConfiguring Spack...\n"
  cmd "git clone https://github.com/exawind/build-test.git ${BUILD_TEST_DIR}"
  cmd "cd ${BUILD_TEST_DIR}/configs && ./setup-spack.sh"

  printf "============================================================\n"
  printf "Done setting up install directory.\n"
  printf "============================================================\n"
fi

printf "\nLoading Spack...\n"
cmd "source ${SPACK_ROOT}/share/spack/setup-env.sh"

# Get general preferred Nalu-Wind constraints from a single location
cmd "source ${INSTALL_DIR}/build-test/configs/shared-constraints.sh"

# Disable openmp on Mira
TRILINOS=$(sed 's/+openmp/~openmp/g' <<<"${TRILINOS}")

cmd "nice spack install -j 8 nalu-wind+hypre %gcc@4.8.4 ^${TRILINOS}@develop"

#cmd "chmod -R ug+rX,go-w ${INSTALL_DIR}"
