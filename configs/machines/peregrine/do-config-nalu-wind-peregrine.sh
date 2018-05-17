#!/bin/bash

# Instructions:
# Make a directory in the Nalu-Wind directory for building,
# Copy this script to that directory and edit the
# options below to your own needs and run it.

COMPILER=gcc #or intel

if [ "${COMPILER}" == 'gcc' ]; then
  CXX_COMPILER=mpicxx
  C_COMPILER=mpicc
  FORTRAN_COMPILER=mpifort
elif [ "${COMPILER}" == 'intel' ]; then
  CXX_COMPILER=mpiicpc
  C_COMPILER=mpiicc
  FORTRAN_COMPILER=mpiifort
fi
  
set -e

cmd() {
  echo "+ $@"
  eval "$@"
}

# Set up environment on Peregrine
cmd "module purge"
if [ "${COMPILER}" == 'gcc' ]; then
  cmd "module use /nopt/nrel/ecom/ecp/base/c/spack/share/spack/modules/linux-centos7-x86_64/gcc-6.2.0"
  cmd "module load git/2.17.0"
  cmd "module load python/2.7.14"
  cmd "module load binutils/2.29.1"
  cmd "module load openmpi/1.10.4"
  cmd "module load netlib-lapack"
  cmd "module load catalyst-ioss-adapter"
elif [ "${COMPILER}" == 'intel' ]; then
  cmd "module use /nopt/nrel/ecom/ecp/base/c/spack/share/spack/modules/linux-centos7-x86_64/intel-18.1.163"
  cmd "module load /nopt/nrel/ecom/ecp/base/c/spack/share/spack/modules/linux-centos7-x86_64/gcc-6.2.0/intel-parallel-studio/cluster.2018.1"
  cmd "module load intel-mpi/2018.1.163"
  cmd "module load intel-mkl/2018.1.163"
fi
cmd "module load gcc/6.2.0"
cmd "module load openfast"
cmd "module load hypre"
cmd "module load tioga"
cmd "module load yaml-cpp"
cmd "module load cmake/3.9.4"
cmd "module load trilinos/develop"
cmd "module list"

# Set tmpdir to the scratch filesystem so it doesn't run out of space
cmd "mkdir -p /scratch/${USER}/.tmp"
cmd "export TMPDIR=/scratch/${USER}/.tmp"

# Clean before cmake configure
set +e
cmd "rm -rf CMakeFiles"
cmd "rm -f CMakeCache.txt"
set -e

cmd "which cmake"
cmd "which mpirun"

# Extra TPLs that can be included in the cmake configure:
#  -DENABLE_PARAVIEW_CATALYST:BOOL=ON \
#  -DPARAVIEW_CATALYST_INSTALL_PATH:PATH=${CATALYST_IOSS_ADAPTER_ROOT_DIR} \

(set -x; cmake \
  -DCMAKE_CXX_COMPILER:STRING=${CXX_COMPILER} \
  -DCMAKE_C_COMPILER:STRING=${C_COMPILER} \
  -DCMAKE_Fortran_COMPILER:STRING=${FORTRAN_COMPILER} \
  -DMPI_CXX_COMPILER:STRING=${CXX_COMPILER} \
  -DMPI_C_COMPILER:STRING=${C_COMPILER} \
  -DMPI_Fortran_COMPILER:STRING=${FORTRAN_COMPILER} \
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
  ..)

cmd "nice make -j 8"
