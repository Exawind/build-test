#!/bin/bash

set -ex

# A Nalu do-config script that uses Spack-built TPLs.
# Make a directory in the Nalu directory for building,
# cd to that directory and then run this script.

COMPILER=gcc

set +e
find . -name "CMakeFiles" -exec rm -rf {} \;
rm -f CMakeCache.txt
set -e

# You will likely need to load these:
spack load binutils %${COMPILER}
spack load cmake %${COMPILER}
spack load openmpi %${COMPILER}
spack load yaml-cpp %${COMPILER}

# Use this if you built Trilinos manually:
#-DTrilinos_DIR:PATH=${HOME}/Trilinos/mybuild/install \
cmake \
  -DTrilinos_DIR:PATH=`spack location -i nalu-trilinos %${COMPILER}` \
  -DYAML_DIR:PATH=`spack location -i yaml-cpp %${COMPILER}` \
  -DCMAKE_BUILD_TYPE=RELEASE \
  ..
