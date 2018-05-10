#!/bin/bash

# Instructions:
# A Nalu do-config script that uses Spack-built TPLs on Peregrine.
# Make a directory in the Nalu directory for building,
# Copy this script to that directory and edit the
# options below to your own needs.
# Uncomment the last line and then run this script.

# Note Spack uses rpath so we don't need to worry so much
# about setting our environment when running, but when we 
# build manually we will then need to have some TPLs loaded in 
# the environment, namely binutils, cmake, and openmpi.

# Also note this script won't work on OSX.
# Mostly due to your OSX machine not having
# environment modules so the 'module load'
# won't add to your PATH (and LD_LIBRARY_PATH).

COMPILER=gcc #or intel

set -e

cmd() {
  echo "+ $@"
  eval "$@"
}

# Set up environment on Peregrine
cmd "module purge"
if [ "${COMPILER}" == 'gcc' ]; then
  cmd "module use /nopt/nrel/ecom/ecp/base/c/spack/share/spack/modules/linux-centos7-x86_64/gcc-6.2.0"
  #cmd "module use /nopt/nrel/ecom/ecp/base/modules/gcc-6.2.0"
elif [ "${COMPILER}" == 'intel' ]; then
  cmd "module use /nopt/nrel/ecom/ecp/base/c/spack/share/spack/modules/linux-centos7-x86_64/intel-18.1.163"
  #cmd "module use /nopt/nrel/ecom/ecp/base/modules/intel-18.1.163"
fi

cmd "module load gcc/6.2.0"
cmd "module load git/2.15.1"
cmd "module load python/2.7.14"
cmd "module load binutils/2.29.1"
cmd "module load openfast/master"
cmd "module load hypre/2.14.0"
cmd "module load tioga/develop"
cmd "module load yaml-cpp/develop-shared"

if [ "${COMPILER}" == 'gcc' ]; then
  # Load correct modules for GCC
  cmd "module load cmake/3.9.4"
  cmd "module load openmpi/1.10.4"
  cmd "module load catalyst-ioss-adapter/develop"
  cmd "module load trilinos/develop"
  #cmd "module load trilinos/develop-omp"
  #cmd "module load trilinos/develop-dbg"
  #cmd "module load trilinos/develop-omp-dbg"
elif [ "${COMPILER}" == 'intel' ]; then
  # Load correct modules for Intel"
  cmd "module load /nopt/nrel/ecom/ecp/base/c/spack/share/spack/modules/linux-centos7-x86_64/gcc-6.2.0/intel-parallel-studio/cluster.2018.1"
  cmd "module load intel-mpi/2018.1.163"
  cmd "module load intel-mkl/2018.1.163"
  cmd "module load cmake/3.9.4"
  cmd "module load trilinos/develop-omp"
fi

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
#  -DENABLE_OPENFAST:BOOL=ON \
#  -DOpenFAST_DIR:PATH=${OPENFAST_ROOT_DIR} \
#  -DENABLE_HYPRE:BOOL=ON \
#  -DHYPRE_DIR:PATH=${HYPRE_ROOT_DIR} \
#  -DENABLE_TIOGA:BOOL=ON \
#  -DTIOGA_DIR:PATH=${TIOGA_ROOT_DIR} \
#  -DENABLE_PARAVIEW_CATALYST:BOOL=ON \
#  -DPARAVIEW_CATALYST_INSTALL_PATH:PATH=${CATALYST_IOSS_ADAPTER_ROOT_DIR} \

(set -x; cmake \
  -DTrilinos_DIR:PATH=${TRILINOS_ROOT_DIR} \
  -DYAML_DIR:PATH=${YAML_CPP_ROOT_DIR} \
  -DCMAKE_BUILD_TYPE:STRING=RELEASE \
  -DENABLE_DOCUMENTATION:BOOL=OFF \
  -DENABLE_TESTS:BOOL=ON \
  ..)

# Uncomment the next line after you make sure you are not on a login node
# and run this script to configure and build Nalu
#cmd "make -j 24"
