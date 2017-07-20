#!/bin/bash

set -e

# A Nalu do-config script for OSX that uses Spack-built TPLs.

COMPILER=gcc
SPACK_EXE=${HOME}/spack/bin/spack
TRILINOS_ROOT=$(${SPACK_EXE} location -i trilinos %${COMPILER})
export PATH=$(${SPACK_EXE} location -i cmake %${COMPILER})/bin:${PATH}
export PATH=$(${SPACK_EXE} location -i openmpi %${COMPILER})/bin:${PATH}
export LD_LIBRARY_PATH=$(${SPACK_EXE} location -i openmpi %${COMPILER})/lib:${PATH}

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
