#!/bin/bash

#PBS -N nalu_build_intel
#PBS -l nodes=1:ppn=24,walltime=4:00:00
#PBS -A windsim
#PBS -q short
#PBS -j oe
#PBS -W umask=002

#Script for installing Nalu on Peregrine using Spack with Intel compiler

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

# The intel.cfg sets up the -xlinker rpath for the intel compiler's own libraries
for i in ICCCFG ICPCCFG IFORTCFG
do
  cmd "export $i=${SPACK_ROOT}/etc/spack/intel.cfg"
done

# Get general preferred Nalu constraints from a single location
cmd "source ../spack_config/shared_constraints.sh"

# Using a disk instead of RAM for the tmp directory for intermediate Intel compiler files
cmd "mkdir -p /scratch/${USER}/.tmp"
cmd "export TMPDIR=/scratch/${USER}/.tmp"

# Fix Peregrine's broken linker
cmd "spack install binutils %intel@17.0.2"		
cmd "source ${SPACK_ROOT}/share/spack/setup-env.sh"		
cmd "spack load binutils"

cmd "spack install nalu %intel@17.0.2 ^${TRILINOS}@develop ^intel-mkl ^intel-mpi"
