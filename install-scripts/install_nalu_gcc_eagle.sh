#!/bin/bash

#Script for installing Nalu on Eagle using Spack with GCC compiler

# Function for printing and executing commands
cmd() {
  echo "+ $@"
  eval "$@"
}

set -e

MODULES=modules
cmd "module purge"
cmd "module unuse ${MODULEPATH}"
cmd "module use /nopt/nrel/ecom/hpacf/compilers/${MODULES}"
cmd "module use /nopt/nrel/ecom/hpacf/utilities/${MODULES}"
cmd "module use /nopt/nrel/ecom/hpacf/software/${MODULES}/gcc-7.3.0"
cmd "module load gcc"
cmd "module load python"
cmd "module load git"
cmd "module list"

# Get general preferred Nalu constraints from a single location
cmd "source ../configs/shared-constraints.sh"

# Sometimes /tmp runs out of space for some reason so set TMPDIR to /scratch
cmd "mkdir -p /scratch/${USER}/.tmp"
cmd "export TMPDIR=/scratch/${USER}/.tmp"

cmd "spack install nalu-wind %gcc@7.3.0 ^${TRILINOS}@develop"
