#!/bin/bash

set -ex

# Instructions:
# A Nalu do-config script that uses Spack-built TPLs on Peregrine.
# Make a directory in the Nalu directory for building,
# Copy this script to that directory and edit the
# options below to your own needs. Leave the SPACK_ROOT option
# alone to build against the communal spack location at NREL.
# Uncomment the last line and then run this script.

# Note Spack uses rpath so we don't need to worry so much
# about setting our environment when running, but when we 
# build manually we will then need to have some TPLs loaded in 
# the environment, namely binutils, cmake, and openmpi.

# Also note this script won't work on OSX.
# Mostly due to your OSX machine not having
# environment modules so the 'module load'
# won't add to your PATH (and LD_LIBRARY_PATH).

# Change these three options to suit your needs:
COMPILER=gcc #or intel
# Using NREL communal spack installation by default
SPACK_ROOT=/projects/windFlowModeling/ExaWind/NaluSharedSoftware/spack
SPACK_EXE=${SPACK_ROOT}/bin/spack #actual spack executable
# Specify location of Trilinos
#TRILINOS_ROOT=$(${SPACK_EXE} location -i trilinos %${COMPILER})
# Use this line instead if you want to build against your own Trilinos:
TRILINOS_ROOT=${HOME}/Trilinos/build/install

# Set up environment on Peregrine
{
module purge
module load gcc/5.2.0
module load python/2.7.8
module unload mkl
} &> /dev/null

# Load necessary modules created by spack
module use ${SPACK_ROOT}/share/spack/modules/$(${SPACK_EXE} arch)
module load $(${SPACK_EXE} module find cmake %${COMPILER})
module load $(${SPACK_EXE} module find openmpi %${COMPILER})

# Set tmpdir to the scratch filesystem so it doesn't run out of space
mkdir -p /scratch/${USER}/.tmp
export TMPDIR=/scratch/${USER}/.tmp

# Load correct modules per compiler
if [ ${COMPILER} == 'gcc' ]; then
  module load $(${SPACK_EXE} module find binutils %${COMPILER})
elif [ ${COMPILER_NAME} == 'intel' ]; then
  module load comp-intel/2017.0.2
fi

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
