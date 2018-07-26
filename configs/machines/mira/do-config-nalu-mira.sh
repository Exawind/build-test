#!/bin/bash

set -e

COMPILER=gcc
SPACK_ROOT=/projects/ExaWindFarm/software/spack
SPACK_EXE=${SPACK_ROOT}/bin/spack
BUILD_TEST_ROOT=/projects/ExaWindFarm/software/build-test
NALU_DIR=${HOME}/exawind/nalu-wind

# Matching Nalu commit for current dependencies installed on mira
#(set -x; cd ${NALU_DIR} && git checkout 7c12601dd7fe77e399c9cbad294aec0ddd3a257b)
#(set -x; cd ${NALU_DIR} && git checkout tpetraInitMarksChanges)

# Need to apply a patch for this thing to build on Mira
(set -x; cd ${NALU_DIR} && git apply ${BUILD_TEST_ROOT}/configs/machines/mira/nalu-wind/mira.patch || true)

export PATH=$(${SPACK_EXE} location -i cmake %${COMPILER})/bin:${PATH}
export PATH=$(${SPACK_EXE} location -i mpich %${COMPILER})/bin:${PATH}

CXX_COMPILER=mpicxx
C_COMPILER=mpicc
FORTRAN_COMPILER=mpifort

set +e
rm -rf CMakeFiles
rm -f CMakeCache.txt
set -e

(set -x; which cmake)
(set -x; which mpicc)

(set -x; cmake \
  -DCMAKE_CXX_COMPILER:STRING=${CXX_COMPILER} \
  -DCMAKE_C_COMPILER:STRING=${C_COMPILER} \
  -DCMAKE_Fortran_COMPILER:STRING=${FORTRAN_COMPILER} \
  -DMPI_CXX_COMPILER:STRING=${CXX_COMPILER} \
  -DMPI_C_COMPILER:STRING=${C_COMPILER} \
  -DMPI_Fortran_COMPILER:STRING=${FORTRAN_COMPILER} \
  -DTrilinos_DIR:PATH=$(${SPACK_EXE} location -i trilinos@develop build_type=Release %${COMPILER}) \
  -DYAML_DIR:PATH=$(${SPACK_EXE} location -i yaml-cpp %${COMPILER}) \
  -DENABLE_HYPRE:BOOL=ON \
  -DHYPRE_DIR:PATH=$(${SPACK_EXE} location -i hypre %${COMPILER}) \
  -DCMAKE_BUILD_TYPE:STRING=RELEASE \
  -DENABLE_DOCUMENTATION:BOOL=OFF \
  -DENABLE_TESTS:BOOL=ON \
  -DTEST_TOLERANCE=0.000001 \
  -DCMAKE_BUILD_WITH_INSTALL_RPATH:BOOL=TRUE \
  ..)

(set -x; nice make -j 8)
