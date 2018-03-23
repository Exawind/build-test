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

#6
ctest -VV -R nonIsoNonUniformEdgeOpenJet
ctest -VV -R nonIsoNonUniformElemOpenJet
ctest -VV -R overset
ctest -VV -R oversetFluids
ctest -VV -R oversetFluidsEdge
ctest -VV -R quad9HC
ctest -VV -R steadyTaylorVortex
ctest -VV -R variableDensNonIso
ctest -VV -R variableDensNonUniform
ctest -VV -R variableDensNonUniform_P5
