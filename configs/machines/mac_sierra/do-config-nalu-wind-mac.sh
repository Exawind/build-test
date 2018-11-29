#!/bin/bash

# A Nalu-Wind do-config script for OSX that uses Spack-built TPLs.

set -e

cmd() {
  echo "+ $@"
  eval "$@"
}

COMPILER=clang #or gcc
SPACK_EXE=${HOME}/spack/bin/spack
CXX_COMPILER=mpicxx
C_COMPILER=mpicc
FORTRAN_COMPILER=mpifort
OVERSUBSCRIBE_FLAGS="--use-hwthread-cpus --oversubscribe"

set +e
cmd "rm -rf CMakeFiles"
cmd "rm -f CMakeCache.txt"
set -e

cmd "export PATH=$(${SPACK_EXE} location -i cmake %${COMPILER})/bin:${PATH}"
cmd "export PATH=$(${SPACK_EXE} location -i openmpi %${COMPILER})/bin:${PATH}"
cmd "which cmake"
cmd "which mpiexec"

YAML_ROOT_DIR=$(${SPACK_EXE} location -i yaml-cpp %${COMPILER})
TRILINOS_ROOT_DIR=$(${SPACK_EXE} location -i trilinos %${COMPILER})
#OPENFAST_ROOT_DIR=$(${SPACK_EXE} location -i openfast %${COMPILER})
#TIOGA_ROOT_DIR=$(${SPACK_EXE} location -i tioga %${COMPILER})
#HYPRE_ROOT_DIR=$(${SPACK_EXE} location -i hypre %${COMPILER})

  #-DENABLE_OPENFAST:BOOL=ON \
  #-DOpenFAST_DIR:PATH=${OPENFAST_ROOT_DIR} \
  #-DENABLE_HYPRE:BOOL=ON \
  #-DHYPRE_DIR:PATH=${HYPRE_ROOT_DIR} \
  #-DENABLE_TIOGA:BOOL=ON \
  #-DTIOGA_DIR:PATH=${TIOGA_ROOT_DIR} \

(set -x; cmake \
  -DCMAKE_CXX_COMPILER:STRING=${CXX_COMPILER} \
  -DCMAKE_C_COMPILER:STRING=${C_COMPILER} \
  -DCMAKE_Fortran_COMPILER:STRING=${FORTRAN_COMPILER} \
  -DMPI_CXX_COMPILER:STRING=${CXX_COMPILER} \
  -DMPI_C_COMPILER:STRING=${C_COMPILER} \
  -DMPI_Fortran_COMPILER:STRING=${FORTRAN_COMPILER} \
  -DMPIEXEC_PREFLAGS:STRING=${OVERSUBSCRIBE_FLAGS} \
  -DTrilinos_DIR:PATH=${TRILINOS_ROOT_DIR} \
  -DYAML_DIR:PATH=${YAML_ROOT_DIR} \
  -DCMAKE_BUILD_TYPE:STRING=Release \
  -DENABLE_DOCUMENTATION:BOOL=OFF \
  -DENABLE_TESTS:BOOL=ON \
  -DCMAKE_FIND_FRAMEWORK:STRING=LAST \
  -DCMAKE_FIND_APPBUNDLE:STRING=LAST \
  -DCMAKE_INSTALL_RPATH_USE_LINK_PATH:BOOL=FALSE \
  -DCMAKE_INSTALL_RPATH:STRING="${YAML_ROOT_DIR}/lib;${TRILINOS_ROOT_DIR}/lib;$(pwd)" \
  .. && make -j 8)
