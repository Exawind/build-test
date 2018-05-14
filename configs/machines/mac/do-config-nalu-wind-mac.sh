#!/bin/bash

# A Nalu-Wind do-config script for OSX that uses Spack-built TPLs.

set -e

cmd() {
  echo "+ $@"
  eval "$@"
}

SPACK_COMPILER=gcc
SPACK_EXE=${HOME}/spack/bin/spack
CXX_COMPILER=g++
C_COMPILER=gcc
FORTRAN_COMPILER=gfortran-7

cmd "export PATH=$(${SPACK_EXE} location -i cmake %${SPACK_COMPILER})/bin:${PATH}"
cmd "export PATH=$(${SPACK_EXE} location -i openmpi %${SPACK_COMPILER})/bin:${PATH}"

set +e
cmd "rm -rf CMakeFiles"
cmd "rm -f CMakeCache.txt"
set -e

cmd "which cmake"
cmd "which mpiexec"

(set -x; cmake \
  -DCMAKE_CXX_COMPILER:STRING=${CXX_COMPILER} \
  -DCMAKE_C_COMPILER:STRING=${C_COMPILER} \
  -DCMAKE_Fortran_COMPILER:STRING=${FORTRAN_COMPILER} \
  -DTrilinos_DIR:PATH=$(${SPACK_EXE} location -i trilinos %${SPACK_COMPILER}) \
  -DYAML_DIR:PATH=$(${SPACK_EXE} location -i yaml-cpp %${SPACK_COMPILER}) \
  -DCMAKE_BUILD_TYPE:STRING=RELEASE \
  -DENABLE_DOCUMENTATION:BOOL=OFF \
  -DENABLE_TESTS:BOOL=ON \
  .. && make -j 8)
