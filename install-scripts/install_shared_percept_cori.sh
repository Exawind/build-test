#!/bin/bash -l

# Script for install percept in a shared location on Cori

# Control over printing and executing commands
print_cmds=true
execute_cmds=true

# Function for printing and executing commands
cmd() {
  if ${print_cmds}; then echo "+ $@"; fi
  if ${execute_cmds}; then eval "$@"; fi
}

printf "============================================================\n"
printf "$(date)\n"
printf "============================================================\n"
printf "Job is running on ${HOSTNAME}\n"
printf "============================================================\n"

# Set some version numbers
GCC_COMPILER_VERSION="7.1.0"
INTEL_COMPILER_VERSION="18.0.1"

# Set installation directory
INSTALL_DIR=${SCRATCH}/percept
BUILD_TEST_DIR=${INSTALL_DIR}/build-test
TRILINOS_BRANCH=12.12.1
COMPILER_NAME=gcc

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
cmd "spack compiler find"

if [ ${COMPILER_NAME} == 'gcc' ]; then
  COMPILER_VERSION="${GCC_COMPILER_VERSION}"
elif [ ${COMPILER_NAME} == 'intel' ]; then
  COMPILER_VERSION="${INTEL_COMPILER_VERSION}"
fi
printf "\nInstalling software with ${COMPILER_NAME}@${COMPILER_VERSION} at $(date).\n"

cmd "source ${INSTALL_DIR}/build-test/configs/shared-constraints.sh"

cd ${INSTALL_DIR}

printf "\nInstalling Percept using ${COMPILER_NAME}@${COMPILER_VERSION}...\n"
if [ ${COMPILER_NAME} == 'gcc' ]; then
  cmd "nice spack install -j 8 percept %${COMPILER_NAME}@${COMPILER_VERSION} ^${TRILINOS_PERCEPT}@${TRILINOS_BRANCH}"
fi

printf "\nDone installing shared software with ${COMPILER_NAME}@${COMPILER_VERSION} at $(date).\n"

printf "\nSetting permissions...\n"
#cmd "chgrp -R m2593 ${INSTALL_DIR}"
#cmd "chmod -R ug+wrX,o-w ${INSTALL_DIR}"
printf "\n$(date)\n"
printf "\nDone!\n"
