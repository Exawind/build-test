#!/bin/bash

#PBS -N nalu_build_intel
#PBS -l nodes=1:ppn=24,walltime=4:00:00
#PBS -A windsim
#PBS -q batch
#PBS -j oe
#PBS -W umask=002

#Script for installing Nalu on Merlin using Spack with Intel compiler

# Function for printing and executing commands
cmd() {
  echo "+ $@"
  eval "$@"
}

set -e

cmd "module purge"
cmd "module load GCCcore/4.9.2"

cmd "export TMPDIR=/dev/shm"

# The intel.cfg sets up the -xlinker rpath for the intel compiler's own libraries
for i in ICCCFG ICPCCFG IFORTCFG
do
  cmd "export $i=${SPACK_ROOT}/etc/spack/intel.cfg"
done

# Get general preferred Nalu constraints from a single location
cmd "source ../configs/shared-constraints.sh"

cmd "spack install nalu-wind %intel@17.0.2 ^${TRILINOS}@develop"

cmd "rm -rf /dev/shm/*"
