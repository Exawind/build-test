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
module load GCCcore/4.9.2

NALUSPACK_ROOT=`pwd`

# Get general preferred Nalu constraints from a single location
source ${NALUSPACK_ROOT}/../spack_config/general_preferred_nalu_constraints.sh

(set -x; spack install nalu %gcc@4.9.2 ^${TRILINOS}@develop ${GENERAL_CONSTRAINTS})
