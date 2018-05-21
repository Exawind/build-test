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
cmd "module use /nopt/nrel/ecom/ecp/base/modules/intel-18.1.163"
cmd "module load gcc/6.2.0"
cmd "module list"

# The intel.cfg sets up the -xlinker rpath for the intel compiler's own libraries
for i in ICCCFG ICPCCFG IFORTCFG
do
  cmd "export $i=${SPACK_ROOT}/etc/spack/intel.cfg"
done

# Get general preferred Nalu constraints from a single location
cmd "source ../configs/shared-constraints.sh"

# Using a disk instead of RAM for the tmp directory for intermediate Intel compiler files
cmd "mkdir -p /scratch/${USER}/.tmp"
cmd "export TMPDIR=/scratch/${USER}/.tmp"

# Fix Peregrine's broken linker
cmd "spack install binutils %intel@18.1.163"		
cmd "source ${SPACK_ROOT}/share/spack/setup-env.sh"		
cmd "spack load binutils"

cmd "spack install nalu-wind %intel@18.1.163 ^${TRILINOS}@develop ^intel-mkl ^intel-mpi"
