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

#5
ctest -VV -R kovasznay_P5
ctest -VV -R milestoneRun
ctest -VV -R milestoneRunConsolidated
ctest -VV -R mixedTetPipe
ctest -VV -R movingCylinder
ctest -VV -R nonConformalWithPeriodic
ctest -VV -R nonConformalWithPeriodicConsolidated
ctest -VV -R nonIsoEdgeOpenJet
ctest -VV -R nonIsoElemOpenJet
ctest -VV -R nonIsoElemOpenJetConsolidated
