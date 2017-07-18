#!/bin/bash

set -e

# A Nalu do-config script for OSX that uses Spack-built TPLs.

COMPILER=gcc
SPACK_EXE=${HOME}/spack/bin/spack
TRILINOS_ROOT=$(${SPACK_EXE} location -i trilinos %${COMPILER})
export PATH=$(spack location -i cmake %${COMPILER_NAME})/bin:${PATH}
export PATH=$(spack location -i openmpi %${COMPILER_NAME})/bin:${PATH}
export LD_LIBRARY_PATH=$(spack location -i openmpi %${COMPILER_NAME})/lib:${PATH}

# Clean before cmake configure
set +e
rm -rf CMakeFiles
rm -f CMakeCache.txt
set -e

(set -x; cmake \
  -DTrilinos_DIR:PATH=${TRILINOS_ROOT} \
  -DYAML_DIR:PATH=$(${SPACK_EXE} location -i yaml-cpp %${COMPILER}) \
  -DCMAKE_BUILD_TYPE:STRING=RELEASE \
  -DBUILD_DOCUMENTATION:BOOL=OFF \
  -DENABLE_TESTS:BOOL=ON \
  .. && make -j 4)
