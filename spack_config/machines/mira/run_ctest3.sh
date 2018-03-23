#!/bin/bash

# Script for running Nalu job on Mira
#qsub -A ExaWindFarm -t 60 -n 1 --mode script run_ctest.sh

set -ex

COMPILER=gcc
SPACK_ROOT=/projects/ExaWindFarm/spack
SPACK_EXE=${SPACK_ROOT}/bin/spack

export PATH=$(${SPACK_EXE} location -i cmake %${COMPILER})/bin:${PATH}
export PATH=$(${SPACK_EXE} location -i mpich %${COMPILER})/bin:${PATH}

(set -x; which cmake)
(set -x; which mpicc)

#3
ctest -VV -R edgeHybridFluids
ctest -VV -R edgePipeCHT
ctest -VV -R ekmanSpiral
ctest -VV -R ekmanSpiralConsolidated
ctest -VV -R elemBackStepLRSST
ctest -VV -R elemClosedDomain
ctest -VV -R elemHybridFluids
ctest -VV -R elemHybridFluidsShift
ctest -VV -R elemPipeCHT
ctest -VV -R femHC
