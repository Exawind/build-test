#!/bin/bash

set -ex

COMPILER=gcc
SPACK_ROOT=${HOME}/spack
SPACK_EXE=${SPACK_ROOT}/bin/spack
NALU_DIR=${HOME}/Nalu
NALUSPACK_ROOT=${HOME}/NaluSpack

# Need to apply patch for this thing to build on Mira
if (cd ${NALU_DIR} && ! patch -Rsfp1 --dry-run < ${NALUSPACK_ROOT}/spack_config/machines/mira/nalu/mira.patch); then
  (cd ${NALU_DIR} && patch -fp1 < ${NALUSPACK_ROOT}/spack_config/machines/mira/nalu/mira.patch)
fi

export PATH=$(${SPACK_EXE} location -i cmake %${COMPILER})/bin:${PATH}
export PATH=$(${SPACK_EXE} location -i mpich %${COMPILER})/bin:${PATH}

set +e
rm -rf CMakeFiles
rm -f CMakeCache.txt
set -e

(set -x; which cmake)
(set -x; which mpicc)

# Extra TPLs that can be included in the cmake configure:
#  -DENABLE_OPENFAST:BOOL=ON \
#  -DOpenFAST_DIR:PATH=$(${SPACK_EXE} location -i openfast %${COMPILER}) \
#  -DENABLE_TIOGA:BOOL=ON \
#  -DTIOGA_DIR:PATH=$(${SPACK_EXE} location -i tioga %${COMPILER}) \
#  -DENABLE_PARAVIEW_CATALYST:BOOL=ON \
#  -DPARAVIEW_CATALYST_INSTALL_PATH:PATH=$(${SPACK_EXE} location -i catalyst-ioss-adapter %${COMPILER}) \

cmake \
  -DTrilinos_DIR:PATH=$(${SPACK_EXE} location -i trilinos@develop build_type=Release %${COMPILER}) \
  -DYAML_DIR:PATH=$(${SPACK_EXE} location -i yaml-cpp %${COMPILER}) \
  -DCMAKE_BUILD_TYPE:STRING=RELEASE \
  -DENABLE_DOCUMENTATION:BOOL=OFF \
  -DENABLE_TESTS:BOOL=ON \
  -DENABLE_HYPRE:BOOL=ON \
  -DHYPRE_DIR:PATH=$(${SPACK_EXE} location -i hypre %${COMPILER}) \
  ..

make -j 4
