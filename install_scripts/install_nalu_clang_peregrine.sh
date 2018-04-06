#!/bin/bash

#PBS -N nalu_build_clang
#PBS -l nodes=1:ppn=24,walltime=4:00:00
#PBS -A windsim
#PBS -q short
#PBS -j oe
#PBS -W umask=002

#Script for installing Nalu on Peregrine using Spack with the LLVM compiler

# Function for printing and executing commands
cmd() {
  echo "+ $@"
  eval "$@"
}

set -e

cmd "module purge"
cmd "module use /projects/windsim/exawind/BaseSoftware/spack/share/spack/modules/linux-centos6-x86_64"
cmd "module load gcc/5.2.0"
cmd "module load llvm/5.0.0"
cmd "module load python/2.7.14"
cmd "module load git/2.14.1"
cmd "module load binutils/2.28"
cmd "module list"

# Get general preferred Nalu constraints from a single location
cmd "source ../spack_config/shared_constraints.sh"

# Sometimes /tmp runs out of space for some reason so set TMPDIR to /scratch
cmd "mkdir -p /scratch/${USER}/.tmp"
cmd "export TMPDIR=/scratch/${USER}/.tmp"

# Disable openmp
TRILINOS=$(sed 's/+openmp/~openmp/g' <<<"${TRILINOS}")

cmd "spack install nalu %clang@5.0.0 ^${TRILINOS}@develop"
