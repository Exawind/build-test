#!/bin/bash

#Script for installing Nalu-Wind on Peregrine using Spack
#Make sure you have set SPACK_ROOT and run setup-spack.sh in this repo to obtain the recommended Spack preferences:x

# Function for printing and executing commands
cmd() {
  echo "+ $@"
  eval "$@"
}

set -e

COMPILER=gcc

MODULES=modules
cmd "module purge"
cmd "module unuse ${MODULEPATH}"
cmd "module use /nopt/nrel/ecom/hpacf/compilers/${MODULES}"
cmd "module use /nopt/nrel/ecom/hpacf/utilities/${MODULES}"
if [ "${COMPILER}" == 'gcc' ]; then
  cmd "module use /nopt/nrel/ecom/hpacf/software/${MODULES}/gcc-7.3.0"
elif [ "${COMPILER}" == 'intel' ]; then
  cmd "module use /nopt/nrel/ecom/hpacf/software/${MODULES}/intel-18.0.4"
fi
cmd "module load gcc"
cmd "module load python"
cmd "module load git"
cmd "module load binutils"
cmd "module list"

# Get general preferred Nalu constraints from a single location
cmd "source ../configs/shared-constraints.sh"

# Sometimes /tmp runs out of space for some reason so set TMPDIR to /scratch
cmd "mkdir -p /scratch/${USER}/.tmp"
cmd "export TMPDIR=/scratch/${USER}/.tmp"

cmd "nice spack install nalu-wind %${COMPILER} ^${TRILINOS}@develop"
