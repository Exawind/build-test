#!/bin/bash

set -ex

# Instructions:
# A Nalu do-config script that uses Spack-built TPLs on Merlin.
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

# Set up environment on Merlin
module purge
unset LD_LIBRARY_PATH
unset MIC_LD_LIBRARY_PATH
unset LIBRARY_PATH
unset MIC_LIBRARY_PATH
source /opt/ohpc/pub/nrel/eb/software/ifort/2017.2.174-GCC-6.3.0-2.27/compilers_and_libraries/linux/bin/compilervars.sh intel64
module load GCCcore/4.9.2
export INTEL_LICENSE_FILE=28518@hpc-admin1.hpc.nrel.gov
for i in ICCCFG ICPCCFG IFORTCFG
do
  export $i=${SPACK_ROOT}/etc/spack/intel.cfg
done
export TMPDIR=/dev/shm

# Change these three options to suit your needs:
COMPILER=gcc #or intel
SPACK_ROOT=${HOME}/spack
TRILINOS_ROOT=${HOME}/Trilinos/build/install

SPACK_EXE=${SPACK_ROOT}/bin/spack

# Load necessary modules created by spack
module use ${SPACK_ROOT}/share/spack/modules/$(${SPACK_EXE} arch)
module load $(${SPACK_EXE} module find cmake %${COMPILER})
module load $(${SPACK_EXE} module find openmpi %${COMPILER})

# Clean before cmake configure
set +e
rm -rf CMakeFiles
rm -f CMakeCache.txt
set -e

(set -x; which cmake)
(set -x; which mpirun)

cmake \
  -DTrilinos_DIR:PATH=${TRILINOS_ROOT} \
  -DYAML_DIR:PATH=$(${SPACK_EXE} location -i yaml-cpp %${COMPILER}) \
  -DCMAKE_BUILD_TYPE:STRING=RELEASE \
  -DENABLE_DOCUMENTATION:BOOL=OFF \
  -DENABLE_TESTS:BOOL=ON \
  ..

# Uncomment the next line after you make sure you are not on a login node
# and run this script to configure and build Nalu
#make -j 24

rm -rf /dev/shm/*
