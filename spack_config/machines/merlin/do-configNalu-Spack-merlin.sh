#!/bin/bash

set -ex

module purge
module load GCCcore/4.9.2

# Change these three options to suit your needs:
COMPILER=gcc
SPACK_ROOT=${HOME}/NaluNightlyTesting/spack
SPACK_EXE=${SPACK_ROOT}/bin/spack

# Load necessary modules created by spack
module use ${SPACK_ROOT}/share/spack/modules/$(${SPACK_EXE} arch)
module load $(${SPACK_EXE} module find -m tcl cmake %${COMPILER})
module load $(${SPACK_EXE} module find -m tcl openmpi %${COMPILER})

# Clean before cmake configure
set +e
rm -rf CMakeFiles
rm -f CMakeCache.txt
set -e

(set -x; which cmake)
(set -x; which mpirun)

cmake \
  -DTrilinos_DIR:PATH=$(${SPACK_EXE} location -i trilinos build_type=Release %${COMPILER}) \
  -DYAML_DIR:PATH=$(${SPACK_EXE} location -i yaml-cpp %${COMPILER}) \
  -DCMAKE_BUILD_TYPE:STRING=RELEASE \
  -DENABLE_DOCUMENTATION:BOOL=OFF \
  -DENABLE_TESTS:BOOL=ON \
  ..

# Uncomment the next line after you make sure you are not on a login node
# and run this script to configure and build Nalu
#make -j 24
