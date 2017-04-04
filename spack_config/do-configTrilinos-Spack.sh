#!/bin/bash

set -ex

# A Trilinos do-config script that uses Spack-built TPLs.
# Make a directory in the trilinos directory for building,
# cd to that directory and then run this script.

# Note Spack uses rpath, but when we build manually
# we will then need to have the TPLs loaded in 
# the environment, and you will likely need
# the spack load commands in your .bash_profile
# to achieve success using/developing with
# a manual build of Trilinos and Nalu.

# Also note this won't work on OSX.
# Mostly due to your OSX machine not having
# environment modules so the 'spack load'
# won't add to your PATH (and LD_LIBRARY_PATH).

# Change these to suit your needs:
COMPILER=gcc
INSTALL_PREFIX=`pwd`/install

set +e
find . -name "CMakeFiles" -exec rm -rf {} \;
rm -f CMakeCache.txt
set -e

spack load binutils %${COMPILER}
spack load cmake %${COMPILER}
spack load openmpi %${COMPILER}
spack load hdf5 %${COMPILER}
spack load netcdf %${COMPILER}
spack load parallel-netcdf %${COMPILER}
spack load zlib %${COMPILER}
spack load superlu %${COMPILER}
spack load boost %${COMPILER}

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
  -DTPL_ENABLE_MPI:BOOL=ON \
  -DMPI_BASE_DIR:PATH=`spack location -i openmpi %${COMPILER}` \
  -DTPL_ENABLE_Boost:BOOL=ON \
  -DBoost_ROOT:PATH=`spack location -i boost %${COMPILER}` \
  -DTPL_ENABLE_SuperLU:BOOL=ON \
  -DSuperLU_ROOT:PATH=`spack location -i superlu %${COMPILER}` \
  -DTPL_ENABLE_Netcdf:BOOL=ON \
  -DNetCDF_ROOT:PATH=`spack location -i netcdf %${COMPILER}` \
  -DTPL_Netcdf_Enables_Netcdf4:BOOL=ON \
  -DTPL_Netcdf_PARALLEL:BOOL=ON \
  -DTPL_ENABLE_Pnetcdf:BOOL=ON \
  -DPNetCDF_ROOT:PATH=`spack location -i parallel-netcdf %${COMPILER}` \
  -DTPL_ENABLE_HDF5:BOOL=ON \
  -DHDF5_ROOT:PATH=`spack location -i hdf5 %${COMPILER}` \
  -DTPL_ENABLE_Zlib:BOOL=ON \
  -DZlib_ROOT:PATH=`spack location -i zlib %${COMPILER}` \
  ..
