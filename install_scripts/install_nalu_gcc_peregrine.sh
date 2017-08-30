#!/bin/bash -l

#PBS -N nalu_build_gcc
#PBS -l nodes=1:ppn=24,walltime=4:00:00
#PBS -A windFlowModeling
#PBS -q short
#PBS -j oe
#PBS -W umask=002

#Script for installing Nalu on Peregrine using Spack with GCC compiler

set -e

{
module purge
module load gcc/5.2.0
module load python/2.7.8
} &> /dev/null

NALUSPACK_ROOT=`pwd`

# Get general preferred Nalu constraints from a single location
source ${NALUSPACK_ROOT}/../spack_config/general_preferred_nalu_constraints.sh

# Fix for Peregrine's broken linker
(set -x; spack install binutils %gcc@5.2.0)
. ${SPACK_ROOT}/share/spack/setup-env.sh
spack load binutils

# Sometimes /tmp runs out of space for some reason so set TMPDIR to /scratch
mkdir -p /scratch/${USER}/.tmp
export TMPDIR=/scratch/${USER}/.tmp

(set -x; spack install nalu %gcc@5.2.0 ^${TRILINOS}@develop ${GENERAL_CONSTRAINTS})
