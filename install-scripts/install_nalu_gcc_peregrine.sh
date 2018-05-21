#!/bin/bash

#PBS -N nalu_build_gcc
#PBS -l nodes=1:ppn=24,walltime=4:00:00
#PBS -A windsim
#PBS -q short
#PBS -j oe
#PBS -W umask=002

#Script for installing Nalu on Peregrine using Spack with GCC compiler

# Function for printing and executing commands
cmd() {
  echo "+ $@"
  eval "$@"
}

set -e

cmd "module purge"
cmd "module use /nopt/nrel/ecom/ecp/base/modules/gcc-6.2.0"
cmd "module load gcc/6.2.0"
cmd "module load python/2.7.14"
cmd "module load git/2.17.0"
cmd "module list"

# Get general preferred Nalu constraints from a single location
cmd "source ../configs/shared-constraints.sh"

# Sometimes /tmp runs out of space for some reason so set TMPDIR to /scratch
cmd "mkdir -p /scratch/${USER}/.tmp"
cmd "export TMPDIR=/scratch/${USER}/.tmp"

# Fix Peregrine's broken linker
cmd "spack install binutils %gcc@6.2.0"		
cmd "source ${SPACK_ROOT}/share/spack/setup-env.sh"		
cmd "spack load binutils"

cmd "spack install nalu-wind %gcc@6.2.0 ^${TRILINOS}@develop"
