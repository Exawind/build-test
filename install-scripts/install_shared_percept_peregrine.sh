#!/bin/bash -l

#PBS -N install-shared-percept-peregrine
#PBS -l nodes=1:ppn=24,walltime=12:00:00
#PBS -A windsim
#PBS -q batch-h
#PBS -j oe
#PBS -W umask=002

# Script for shared installation of Percept on Peregrine using Spack

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
if [ ! -z "${PBS_JOBID}" ]; then
  printf "PBS: Qsub is running on ${PBS_O_HOST}\n"
  printf "PBS: Originating queue is ${PBS_O_QUEUE}\n"
  printf "PBS: Executing queue is ${PBS_QUEUE}\n"
  printf "PBS: Working directory is ${PBS_O_WORKDIR}\n"
  printf "PBS: Execution mode is ${PBS_ENVIRONMENT}\n"
  printf "PBS: Job identifier is ${PBS_JOBID}\n"
  printf "PBS: Job name is ${PBS_JOBNAME}\n"
  printf "PBS: Node file is ${PBS_NODEFILE}\n"
  printf "PBS: Current home directory is ${PBS_O_HOME}\n"
  printf "PBS: PATH = ${PBS_O_PATH}\n"
  printf "============================================================\n"
fi

# Set some version numbers
COMPILER_NAME=gcc
GCC_COMPILER_VERSION="6.2.0"

# Set installation directory
#INSTALL_DIR=/projects/windsim/exawind/software/percept
INSTALL_DIR=${HOME}/software/percept
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
cmd "source ${INSTALL_DIR}/build-test/configs/shared-constraints.sh"

COMPILER_VERSION="${GCC_COMPILER_VERSION}"
printf "\nInstalling base software with ${COMPILER_NAME}@${COMPILER_VERSION} at $(date).\n"

# Load necessary modules
printf "\nLoading modules...\n"
cmd "module purge"
cmd "module use /nopt/nrel/ecom/ecp/base/c/spack/share/spack/modules/linux-centos7-x86_64/gcc-6.2.0"
cmd "module load gcc/6.2.0"
cmd "module load git/2.17.0"
cmd "module load python/2.7.14"
cmd "module load curl/7.59.0"
cmd "module load binutils/2.29.1"
cmd "module load texinfo/6.5"
cmd "module load texlive/live"

# Set the TMPDIR to disk so it doesn't run out of space
printf "\nMaking and setting TMPDIR to disk...\n"
cmd "mkdir -p /scratch/${USER}/.tmp"
cmd "export TMPDIR=/scratch/${USER}/.tmp"

printf "\nInstalling Percept using ${COMPILER_NAME}@${COMPILER_VERSION}...\n"
cmd "nice spack install -j 8 percept %${COMPILER_NAME}@${COMPILER_VERSION} ^${TRILINOS_PERCEPT}@12.12.1 ^netcdf@4.3.3.1 ^hdf5@1.8.16 ^boost@1.60.0 ^parallel-netcdf@1.6.1 ^libxml2@2.9.4"

cmd "unset TMPDIR"

printf "\nDone installing shared software with ${COMPILER_NAME}@${COMPILER_VERSION} at $(date).\n"

#printf "\nSetting permissions...\n"
#cmd "chmod -R a+rX,o-w,g+w ${INSTALL_DIR}"
printf "\n$(date)\n"
printf "\nDone!\n"
