#!/bin/bash -l

#PBS -N nalu_build_gcc
#PBS -l nodes=1:ppn=24,walltime=4:00:00
#PBS -A windFlowModeling
#PBS -q batch
#PBS -j oe
#PBS -W umask=002

#Script for installing Nalu on Merlin using Spack with GCC compiler

set -e

module purge
module load GCC/4.8.5

NALUSPACK_ROOT=`pwd`

# Get general preferred Nalu constraints from a single location
source ${NALUSPACK_ROOT}/../spack_config/general_preferred_nalu_constraints.sh

MACHINE_SPECIFIC_CONSTRAINTS="^openmpi@1.10.3 fabrics=psm2 schedulers=tm ^cmake@3.6.1 ^netlib-lapack"

ALL_CONSTRAINTS="${GENERAL_CONSTRAINTS} ${MACHINE_SPECIFIC_CONSTRAINTS}"

(set -x; spack install nalu %gcc@4.8.5 ^${TRILINOS}@develop ${ALL_CONSTRAINTS})
