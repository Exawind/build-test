#!/bin/bash

set -ex

# Instructions:
# A Trilinos do-config script that uses Spack-built TPLs.
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
SPACK_ROOT=/projects/windFlowModeling/ExaWind/NaluSharedSoftware/spack

SPACK_EXE=${SPACK_ROOT}/bin/spack #actual spack executable

# Load necessary modules created by spack
module use ${SPACK_ROOT}/share/spack/modules/$(${SPACK_EXE} arch)
module load $(${SPACK_EXE} module find cmake %${COMPILER})
module load $(${SPACK_EXE} module find openmpi %${COMPILER})
module load $(${SPACK_EXE} module find hdf5 %${COMPILER})
module load $(${SPACK_EXE} module find netcdf %${COMPILER})
module load $(${SPACK_EXE} module find parallel-netcdf %${COMPILER})
module load $(${SPACK_EXE} module find zlib %${COMPILER})
module load $(${SPACK_EXE} module find superlu %${COMPILER})
module load $(${SPACK_EXE} module find boost %${COMPILER})

# Comment this one line if using Intel
module load $(${SPACK_EXE} module find binutils %${COMPILER})
# Uncomment these two lines if using Intel
#module load compiler/intel/16.0.2
#export TMPDIR=/scratch/${USER}/.tmp

# Clean before cmake configure
set +e
rm -rf CMakeFiles
rm -f CMakeCache.txt
set -e

cmake \
  -DCMAKE_INSTALL_PREFIX:PATH=${INSTALL_PREFIX} \
  -DCMAKE_BUILD_TYPE:STRING=RELEASE \
  -DTrilinos_ENABLE_CXX11:BOOL=ON \
  -DTrilinos_ENABLE_EXPLICIT_INSTANTIATION:BOOL=ON \
  -DTpetra_INST_DOUBLE:BOOL=ON \
  -DTpetra_INST_INT_LONG:BOOL=ON \
  -DTpetra_INST_COMPLEX_DOUBLE:BOOL=OFF \
  -DTrilinos_ENABLE_TESTS:BOOL=OFF \
  -DTrilinos_ENABLE_ALL_OPTIONAL_PACKAGES:BOOL=OFF \
  -DTrilinos_ASSERT_MISSING_PACKAGES:BOOL=OFF \
  -DTrilinos_ALLOW_NO_PACKAGES:BOOL=OFF \
  -DTrilinos_ENABLE_Epetra:BOOL=OFF \
  -DTrilinos_ENABLE_Tpetra:BOOL=ON \
  -DTrilinos_ENABLE_ML:BOOL=OFF \
  -DTrilinos_ENABLE_MueLu:BOOL=ON \
  -DTrilinos_ENABLE_EpetraExt:BOOL=OFF \
  -DTrilinos_ENABLE_AztecOO:BOOL=OFF \
  -DTrilinos_ENABLE_Belos:BOOL=ON \
  -DTrilinos_ENABLE_Ifpack2:BOOL=ON \
  -DTrilinos_ENABLE_Amesos2:BOOL=ON \
  -DTrilinos_ENABLE_Zoltan2:BOOL=ON \
  -DTrilinos_ENABLE_Ifpack:BOOL=OFF \
  -DTrilinos_ENABLE_Amesos:BOOL=OFF \
  -DTrilinos_ENABLE_Zoltan:BOOL=ON \
  -DTrilinos_ENABLE_STKMesh:BOOL=ON \
  -DTrilinos_ENABLE_STKSimd:BOOL=ON \
  -DTrilinos_ENABLE_STKIO:BOOL=ON \
  -DTrilinos_ENABLE_STKTransfer:BOOL=ON \
  -DTrilinos_ENABLE_STKSearch:BOOL=ON \
  -DTrilinos_ENABLE_STKUtil:BOOL=ON \
  -DTrilinos_ENABLE_STKTopology:BOOL=ON \
  -DTrilinos_ENABLE_STKUnit_tests:BOOL=ON \
  -DTrilinos_ENABLE_STKUnit_test_utils:BOOL=ON \
  -DTrilinos_ENABLE_Gtest:BOOL=ON \
  -DTrilinos_ENABLE_STKClassic:BOOL=OFF \
  -DTrilinos_ENABLE_SEACASExodus:BOOL=ON \
  -DTrilinos_ENABLE_SEACASEpu:BOOL=ON \
  -DTrilinos_ENABLE_SEACASExodiff:BOOL=ON \
  -DTrilinos_ENABLE_SEACASNemspread:BOOL=ON \
  -DTrilinos_ENABLE_SEACASNemslice:BOOL=ON \
  -DTrilinos_ENABLE_SEACASIoss:BOOL=ON \
  -DTPL_ENABLE_MPI:BOOL=ON \
  -DMPI_BASE_DIR:PATH=$(${SPACK_EXE} location -i openmpi %${COMPILER}) \
  -DTPL_ENABLE_Boost:BOOL=ON \
  -DBoost_ROOT:PATH=$(${SPACK_EXE} location -i boost %${COMPILER}) \
  -DTPL_ENABLE_SuperLU:BOOL=ON \
  -DSuperLU_ROOT:PATH=$(${SPACK_EXE} location -i superlu %${COMPILER}) \
  -DTPL_ENABLE_Netcdf:BOOL=ON \
  -DNetCDF_ROOT:PATH=$(${SPACK_EXE} location -i netcdf %${COMPILER}) \
  -DTPL_Netcdf_Enables_Netcdf4:BOOL=ON \
  -DTPL_Netcdf_PARALLEL:BOOL=ON \
  -DTPL_ENABLE_Pnetcdf:BOOL=ON \
  -DPNetCDF_ROOT:PATH=$(${SPACK_EXE} location -i parallel-netcdf %${COMPILER}) \
  -DTPL_ENABLE_HDF5:BOOL=ON \
  -DHDF5_ROOT:PATH=$(${SPACK_EXE} location -i hdf5 %${COMPILER}) \
  -DHDF5_NO_SYSTEM_PATHS:BOOL=ON \
  -DTPL_ENABLE_Zlib:BOOL=ON \
  -DZlib_ROOT:PATH=$(${SPACK_EXE} location -i zlib %${COMPILER}) \
  ..

# Uncomment the next two lines after you make sure you are not on a login node
# and run this script to configure and build Trilinos
#make -j 24
#make install
