#!/bin/bash

# Instructions:
# Make a directory in the Nalu-Wind directory for building,
# Copy this script to that directory and edit the
# options below to your own needs and run it.

COMPILER=gcc

if [ "${COMPILER}" == 'gcc' ]; then
  CXX_COMPILER=mpicxx
  C_COMPILER=mpicc
  FORTRAN_COMPILER=mpifort
  FLAGS="-O2 -march=native -mtune=native"
  OVERSUBSCRIBE_FLAGS="--use-hwthread-cpus --oversubscribe"
fi
  
set -e

cmd() {
  echo "+ $@"
  eval "$@"
}

# Set up environment on Eagle
cmd "module purge"
if [ "${COMPILER}" == 'gcc' ]; then
  cmd "module use /nopt/nrel/ecom/hpacf/2018-11-09/spack/share/spack/modules/linux-centos7-x86_64/gcc-7.3.0"
  cmd "module load git"
  cmd "module load python"
  cmd "module load openmpi"
  cmd "module load netlib-lapack"
fi
cmd "module load gcc/7.3.0"
cmd "module load openfast"
cmd "module load hypre"
cmd "module load tioga"
cmd "module load yaml-cpp"
cmd "module load cmake"
cmd "module load trilinos"
cmd "module list"

# Set tmpdir to the scratch filesystem so it doesn't run out of space
cmd "mkdir -p ${HOME}/.tmp"
cmd "export TMPDIR=${HOME}/.tmp"

# Clean before cmake configure
set +e
cmd "rm -rf CMakeFiles"
cmd "rm -f CMakeCache.txt"
set -e

cmd "which cmake"
cmd "which mpirun"

(set -x; cmake \
  -DCMAKE_CXX_COMPILER:STRING=${CXX_COMPILER} \
  -DCMAKE_CXX_FLAGS:STRING=${FLAGS} \
  -DCMAKE_C_COMPILER:STRING=${C_COMPILER} \
  -DCMAKE_C_FLAGS:STRING=${FLAGS} \
  -DCMAKE_Fortran_COMPILER:STRING=${FORTRAN_COMPILER} \
  -DCMAKE_Fortran_FLAGS:STRING=${FLAGS} \
  -DMPI_CXX_COMPILER:STRING=${CXX_COMPILER} \
  -DMPI_C_COMPILER:STRING=${C_COMPILER} \
  -DMPI_Fortran_COMPILER:STRING=${FORTRAN_COMPILER} \
  -DMPIEXEC_PREFLAGS:STRING=${OVERSUBSCRIBE_FLAGS} \
  -DTrilinos_DIR:PATH=${TRILINOS_ROOT_DIR} \
  -DYAML_DIR:PATH=${YAML_CPP_ROOT_DIR} \
  -DENABLE_OPENFAST:BOOL=ON \
  -DOpenFAST_DIR:PATH=${OPENFAST_ROOT_DIR} \
  -DENABLE_HYPRE:BOOL=ON \
  -DHYPRE_DIR:PATH=${HYPRE_ROOT_DIR} \
  -DENABLE_TIOGA:BOOL=ON \
  -DTIOGA_DIR:PATH=${TIOGA_ROOT_DIR} \
  -DCMAKE_BUILD_TYPE:STRING=RELEASE \
  -DENABLE_DOCUMENTATION:BOOL=OFF \
  -DENABLE_TESTS:BOOL=ON \
  -DCMAKE_SKIP_BUILD_RPATH:BOOL=FALSE \
  -DCMAKE_BUILD_WITH_INSTALL_RPATH:BOOL=FALSE \
  -DCMAKE_INSTALL_RPATH_USE_LINK_PATH:BOOL=TRUE \
  -DCMAKE_BUILD_RPATH:STRING="${NETLIB_LAPACK_ROOT_DIR}/lib64;${TIOGA_ROOT_DIR}/lib;${HYPRE_ROOT_DIR}/lib;${OPENFAST_ROOT_DIR}/lib;${YAML_ROOT_DIR}/lib;${TRILINOS_ROOT_DIR}/lib;$(pwd)" \
  ..)

cmd "nice make -j 20"
