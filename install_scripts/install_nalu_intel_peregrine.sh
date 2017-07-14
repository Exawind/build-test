#!/bin/bash -l

#PBS -N nalu_build_intel
#PBS -l nodes=1:ppn=24,walltime=4:00:00
#PBS -A windFlowModeling
#PBS -q short
#PBS -o $PBS_JOBNAME.log
#PBS -j oe
#PBS -W umask=002

#Script for installing Nalu on Peregrine using Spack with Intel compiler

set -e

{
module purge
module load gcc/5.2.0
module load python/2.7.8
} &> /dev/null

# Get TPL preferences from a single location
NALUSPACK_ROOT=`pwd`
source ${NALUSPACK_ROOT}/../spack_config/tpls.sh
TPLS="${TPLS} ^openmpi@1.10.3 fabrics=verbs schedulers=tm ^cmake@3.6.1 ^m4@1.4.17"

# For temporary intel compiler files
mkdir -p /scratch/${USER}/.tmp
export TMPDIR=/scratch/${USER}/.tmp
spack install nalu %intel@16.0.2 ^${TRILINOS}@develop ${TPLS}
