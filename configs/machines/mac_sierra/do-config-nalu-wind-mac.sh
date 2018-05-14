#!/bin/bash

# A Nalu-Wind do-config script for OSX that uses Spack-built TPLs.

set -e

cmd() {
  echo "+ $@"
  eval "$@"
}

COMPILER=gcc
SPACK_EXE=${HOME}/spack/bin/spack
CXX_COMPILER=mpicxx
C_COMPILER=mpicc
FORTRAN_COMPILER=mpifort

cmd "export PATH=$(${SPACK_EXE} location -i cmake %${COMPILER})/bin:${PATH}"
cmd "export PATH=$(${SPACK_EXE} location -i openmpi %${COMPILER})/bin:${PATH}"

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
  -DMPI_CXX_COMPILER:STRING=${CXX_COMPILER} \
  -DMPI_C_COMPILER:STRING=${C_COMPILER} \
  -DMPI_Fortran_COMPILER:STRING=${FORTRAN_COMPILER} \
  -DTrilinos_DIR:PATH=$(${SPACK_EXE} location -i trilinos %${COMPILER}) \
  -DYAML_DIR:PATH=$(${SPACK_EXE} location -i yaml-cpp %${COMPILER}) \
  -DCMAKE_BUILD_TYPE:STRING=RELEASE \
  -DENABLE_DOCUMENTATION:BOOL=OFF \
  -DENABLE_TESTS:BOOL=ON \
  .. && make -j 8)
