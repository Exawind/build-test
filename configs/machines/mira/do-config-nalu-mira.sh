#!/bin/bash

set -e

COMPILER=gcc
SPACK_ROOT=/projects/ExaWindFarm/software/spack
SPACK_EXE=${SPACK_ROOT}/bin/spack
BUILD_TEST_ROOT=/projects/ExaWindFarm/software/build-test
NALU_DIR=${HOME}/Nalu

# Need to apply patch for this thing to build on Mira
if (cd ${NALU_DIR} && ! patch -Rsfp1 --dry-run < ${BUILD_TEST_ROOT}/configs/machines/mira/nalu/mira.patch); then
  (set -x; cd ${NALU_DIR} && patch -fp1 < ${BUILD_TEST_ROOT}/configs/machines/mira/nalu/mira.patch)
fi

# Apply patch to ctest to use runjob instead of mpiexec
(set -x; cd ${NALU_DIR} && git apply ${BUILD_TEST_ROOT}/configs/machines/mira/nalu/ctest.patch || true)

export PATH=$(${SPACK_EXE} location -i cmake %${COMPILER})/bin:${PATH}
export PATH=$(${SPACK_EXE} location -i mpich %${COMPILER})/bin:${PATH}

set +e
rm -rf CMakeFiles
rm -f CMakeCache.txt
set -e

(set -x; which cmake)
(set -x; which mpicc)

(set -x; cmake \
  -DTrilinos_DIR:PATH=$(${SPACK_EXE} location -i trilinos@develop build_type=Release %${COMPILER}) \
  -DYAML_DIR:PATH=$(${SPACK_EXE} location -i yaml-cpp %${COMPILER}) \
  -DCMAKE_BUILD_TYPE:STRING=RELEASE \
  -DENABLE_DOCUMENTATION:BOOL=OFF \
  -DENABLE_TESTS:BOOL=ON \
  -DENABLE_HYPRE:BOOL=ON \
  -DHYPRE_DIR:PATH=$(${SPACK_EXE} location -i hypre %${COMPILER}) \
  ..)

(set -x; nice make -j 8)
