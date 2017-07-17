#!/bin/bash -l

#PBS -N nalu_build_gcc
#PBS -l nodes=1:ppn=24,walltime=4:00:00
#PBS -A windFlowModeling
#PBS -q short
#PBS -o $PBS_JOBNAME.log
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

MACHINE_SPECIFIC_CONSTRAINTS="^openmpi@1.10.3 fabrics=verbs,mxm schedulers=tm ^cmake@3.6.1"

ALL_CONSTRAINTS="${GENERAL_CONSTRAINTS} ${MACHINE_SPECIFIC_CONSTRAINTS}"

# Fix for Peregrine's broken linker
(set -x; spack install binutils %gcc@5.2.0)
. ${SPACK_ROOT}/share/spack/setup-env.sh
spack load binutils

(set -x; spack install nalu %gcc@5.2.0 ^${TRILINOS}@develop ${ALL_CONSTRAINTS})
