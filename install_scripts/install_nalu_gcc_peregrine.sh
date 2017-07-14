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

# Get TPL preferences from a single location
NALUSPACK_ROOT=`pwd`
source ${NALUSPACK_ROOT}/../spack_config/tpls.sh
TPLS="${TPLS} ^openmpi@1.10.3 fabrics=verbs,mxm schedulers=tm ^cmake@3.6.1"

spack install binutils %gcc
. ${SPACK_ROOT}/share/spack/setup-env.sh
spack load binutils
spack install nalu %gcc@5.2.0 ^${TRILINOS}@develop ${TPLS}
