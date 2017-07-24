#!/bin/bash -l

#PBS -N nalu_build_intel
#PBS -l nodes=1:ppn=24,walltime=4:00:00
#PBS -A windFlowModeling
#PBS -q batch
#PBS -j oe
#PBS -W umask=002

#Script for installing Nalu on Merlin using Spack with Intel compiler

set -e

module purge
module load GCC/4.8.5

export INTEL_LICENSE_FILE=28518@hpc-admin1.hpc.nrel.gov

for i in ICCCFG ICPCCFG IFORTCFG
do
  export $i=${SPACK_ROOT}/etc/spack/intel.cfg
done

NALUSPACK_ROOT=`pwd`

# Get general preferred Nalu constraints from a single location
source ${NALUSPACK_ROOT}/../spack_config/general_preferred_nalu_constraints.sh

MACHINE_SPECIFIC_CONSTRAINTS="^openmpi@1.10.3 fabrics=psm2 ^cmake@3.6.1 ^netlib-lapack"

ALL_CONSTRAINTS="${GENERAL_CONSTRAINTS} ${MACHINE_SPECIFIC_CONSTRAINTS}"

# Merlin has enough RAM to set TMPDIR to use a RAM disk
export TMPDIR=/dev/shm

(set -x; spack install nalu %intel@17.0.2 ^${TRILINOS}@develop ${ALL_CONSTRAINTS})
