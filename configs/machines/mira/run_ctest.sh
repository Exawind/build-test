#!/bin/bash

# Script for running Nalu-Wind job on Mira
#qsub -A ExaWindFarm -t 60 -n 1 -env INDEX1=i:INDEX2=j --mode script run_ctest.sh

set -ex

COMPILER=gcc
SPACK_ROOT=/projects/ExaWindFarm/software/spack
SPACK_EXE=${SPACK_ROOT}/bin/spack

export PATH=$(${SPACK_EXE} location -i cmake %${COMPILER})/bin:${PATH}
export PATH=$(${SPACK_EXE} location -i mpich %${COMPILER})/bin:${PATH}

(set -x; which cmake)
(set -x; which mpicc)

ctest -VV -j 16 -I ${INDEX1},${INDEX2}
