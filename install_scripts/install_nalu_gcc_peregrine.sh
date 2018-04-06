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
cmd "module use /projects/windsim/exawind/BaseSoftware/spack/share/spack/modules/linux-centos6-x86_64"
cmd "module load gcc/5.2.0"
cmd "module load python/2.7.14"
cmd "module load git/2.14.1"
cmd "module list"

# Get general preferred Nalu constraints from a single location
cmd "source ../spack_config/shared_constraints.sh"

# Sometimes /tmp runs out of space for some reason so set TMPDIR to /scratch
cmd "mkdir -p /scratch/${USER}/.tmp"
cmd "export TMPDIR=/scratch/${USER}/.tmp"

# Fix Peregrine's broken linker
cmd "spack install binutils %gcc@5.2.0"		
cmd "source ${SPACK_ROOT}/share/spack/setup-env.sh"		
cmd "spack load binutils"

cmd "spack install nalu %gcc@5.2.0 ^${TRILINOS}@develop"
