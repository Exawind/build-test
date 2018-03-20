#!/bin/bash

set -ex

COMPILER=gcc
SPACK_ROOT=/projects/ExaWindFarm/spack
SPACK_EXE=${SPACK_ROOT}/bin/spack
NALUSPACK_ROOT=/projects/ExaWindFarm/NaluSpack
NALU_DIR=${HOME}/Nalu

# Need to apply patch for this thing to build on Mira
if (cd ${NALU_DIR} && ! patch -Rsfp1 --dry-run < ${NALUSPACK_ROOT}/spack_config/machines/mira/nalu/mira.patch); then
  (cd ${NALU_DIR} && patch -fp1 < ${NALUSPACK_ROOT}/spack_config/machines/mira/nalu/mira.patch)
fi

# Apply patch to ctest to use runjob instead of mpiexec
(cd ${NALU_DIR} && git apply ${NALUSPACK_ROOT}/spack_config/machines/mira/nalu/ctest.patch || true)

export PATH=$(${SPACK_EXE} location -i cmake %${COMPILER})/bin:${PATH}
export PATH=$(${SPACK_EXE} location -i mpich %${COMPILER})/bin:${PATH}

set +e
rm -rf CMakeFiles
rm -f CMakeCache.txt
set -e

(set -x; which cmake)
(set -x; which mpicc)

cmake \
  -DTrilinos_DIR:PATH=$(${SPACK_EXE} location -i trilinos@develop build_type=Release %${COMPILER}) \
  -DYAML_DIR:PATH=$(${SPACK_EXE} location -i yaml-cpp %${COMPILER}) \
  -DCMAKE_BUILD_TYPE:STRING=RELEASE \
  -DENABLE_DOCUMENTATION:BOOL=OFF \
  -DENABLE_TESTS:BOOL=ON \
  -DENABLE_HYPRE:BOOL=ON \
  -DHYPRE_DIR:PATH=$(${SPACK_EXE} location -i hypre %${COMPILER}) \
  ..

nice make -j 8
