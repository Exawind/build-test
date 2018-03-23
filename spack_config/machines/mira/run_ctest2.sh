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

#2
ctest -VV -R dgNonConformal3dFluidsHexTet
ctest -VV -R dgNonConformal3dFluidsP1P2
ctest -VV -R dgNonConformalEdge
ctest -VV -R dgNonConformalEdgeCylinder
ctest -VV -R dgNonConformalElemCylinder
ctest -VV -R dgNonConformalFluids
ctest -VV -R dgNonConformalFluidsEdge
ctest -VV -R dgNonConformalThreeBlade
ctest -VV -R ductElemWedge
ctest -VV -R ductWedge
