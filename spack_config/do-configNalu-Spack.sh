#!/bin/bash

set -ex

# Instructions:
# A Nalu do-config script that uses Spack-built TPLs.
# Make a directory in the trilinos directory for building,
# Copy this script to that directory and edit the three
# options below to your own needs. Leave the SPACK_ROOT option
# alone to build against the communal spack location at NREL.
# Uncomment the last two lines and then run this script.

# Note Spack uses rpath so we don't need to worry so much
# about setting our environment when running, but when we 
# build manually we will then need to have the TPLs loaded in 
# the environment, and you will likely need
# the module load commands in effect to both build and run
# using a manual build of Trilinos and Nalu.

# Also note this script won't work on OSX.
# Mostly due to your OSX machine not having
# environment modules so the 'module load'
# won't add to your PATH (and LD_LIBRARY_PATH).

# Change these three options to suit your needs:
COMPILER=gcc #or intel
# Default to installing to 'install' directory in build directory
INSTALL_PREFIX=$(pwd)/install
# Using NREL communal spack installation by default
SPACK_ROOT=/projects/windFlowModeling/ExaWind/NaluSharedInstallation/spack

SPACK=${SPACK_ROOT}/bin/spack #actual spack executable

# Load necessary modules created by spack
module use ${SPACK_ROOT}/share/spack/modules/$(${SPACK} arch)
# Only need these three if building against communal Trilinos
module load $(${SPACK} module find binutils %${COMPILER})
module load $(${SPACK} module find cmake %${COMPILER})
module load $(${SPACK} module find openmpi %${COMPILER})
# Load all of these too if building against your own Trilinos
module load $(${SPACK} module find hdf5 %${COMPILER})
module load $(${SPACK} module find netcdf %${COMPILER})
module load $(${SPACK} module find parallel-netcdf %${COMPILER})
module load $(${SPACK} module find zlib %${COMPILER})
module load $(${SPACK} module find superlu %${COMPILER})
module load $(${SPACK} module find boost %${COMPILER})

# Clean before cmake configure
set +e
rm -rf CMakeFiles
rm -f CMakeCache.txt
set -e

# Use this line instead if you want to build against the communal Trilinos:
#-DTrilinos_DIR:PATH=$(${SPACK} location -i nalu-trilinos %${COMPILER}) \
cmake \
  -DTrilinos_DIR:PATH=${HOME}/Trilinos/mybuild/install \
  -DYAML_DIR:PATH=$(${SPACK} location -i yaml-cpp %${COMPILER}) \
  -DCMAKE_BUILD_TYPE:STRING=RELEASE \
  -DBUILD_DOCUMENTATION:BOOL=OFF \
  -DENABLE_TESTS:BOOL=OFF \
  ..

# Uncomment the next two lines after you make sure you are not on a login node
# and run this script to configure and build Nalu
#make -j 24
#make install
