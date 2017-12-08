#!/bin/bash

#PBS -N percept_build_gcc
#PBS -l nodes=1:ppn=24,walltime=4:00:00
#PBS -A windsim
#PBS -q short
#PBS -j oe
#PBS -W umask=002

#Script for installing Percept on Peregrine using Spack with GCC compiler

# Function for printing and executing commands
cmd() {
  echo "+ $@"
  eval "$@"
}

set -e

cmd "module purge"
cmd "module load gcc/5.2.0"
cmd "module load python/2.7.8 &> /dev/null"
cmd "module unload mkl"

# Get general preferred Percept constraints from a single location
cmd "source ../spack_config/shared_constraints.sh"

# Fix for Peregrine's broken linker
cmd "spack install binutils %gcc@5.2.0"
cmd "source ${SPACK_ROOT}/share/spack/setup-env.sh"
cmd "spack load binutils"

# Sometimes /tmp runs out of space for some reason so set TMPDIR to /scratch
cmd "mkdir -p /scratch/${USER}/.tmp"
cmd "export TMPDIR=/scratch/${USER}/.tmp"

cmd "spack install percept %gcc@5.2.0 ^${TRILINOS_PERCEPT}@12.12.1 ${GENERAL_CONSTRAINTS}"
# Might need to force cmake 3.7.2 because cmake 3.6.1 had problems knowing if HDF5 was parallel
#cmd "spack install percept %gcc@5.2.0 ^${TRILINOS_PERCEPT}@12.12.1 ^cmake@3.7.2 ${GENERAL_CONSTRAINTS}"
