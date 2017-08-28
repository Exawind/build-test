#!/bin/bash -l

#PBS -N nalu_build_intel
#PBS -l nodes=1:ppn=24,walltime=4:00:00
#PBS -A windFlowModeling
#PBS -q short
#PBS -j oe
#PBS -W umask=002

#Script for installing Nalu on Peregrine using Spack with Intel compiler

set -e

{
module purge
module load gcc/5.2.0
module load python/2.7.8
} &> /dev/null

NALUSPACK_ROOT=`pwd`

# Get general preferred Nalu constraints from a single location
source ${NALUSPACK_ROOT}/../spack_config/general_preferred_nalu_constraints.sh

# Using a disk instead of RAM for the tmp directory for intermediate Intel compiler files
mkdir -p /scratch/${USER}/.tmp
export TMPDIR=/scratch/${USER}/.tmp

(set -x; spack install nalu %intel@16.0.2 ^${TRILINOS}@develop ${GENERAL_CONSTRAINTS})
