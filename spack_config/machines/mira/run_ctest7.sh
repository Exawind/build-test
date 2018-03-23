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

#7
ctest -VV -R nrel5MWactuatorLine
ctest -VV -R dgncThreeBladeHypre
ctest -VV -R BoussinesqNonIso
ctest -VV -R cvfemHexHC_P3
ctest -VV -R hoVortex_P2
ctest -VV -R steadyTaylorVortex_P4
ctest -VV -R unitTest1
ctest -VV -R unitTest2
ctest -VV -R oversetHybrid
ctest -VV -R uqSlidingMeshDG
