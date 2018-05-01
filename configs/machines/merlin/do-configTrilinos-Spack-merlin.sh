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
COMPILER=gcc # or intel
INSTALL_PREFIX=$(pwd)/install
SPACK_ROOT=${HOME}/spack
SPACK_EXE=${SPACK_ROOT}/bin/spack

# Load necessary modules created by spack
module use ${SPACK_ROOT}/share/spack/modules/$(${SPACK_EXE} arch)
module load $(${SPACK_EXE} module find -m tcl cmake %${COMPILER})
module load $(${SPACK_EXE} module find -m tcl openmpi %${COMPILER})
module load $(${SPACK_EXE} module find -m tcl hdf5 %${COMPILER})
module load $(${SPACK_EXE} module find -m tcl netcdf %${COMPILER})
module load $(${SPACK_EXE} module find -m tcl parallel-netcdf %${COMPILER})
module load $(${SPACK_EXE} module find -m tcl zlib %${COMPILER})
module load $(${SPACK_EXE} module find -m tcl superlu %${COMPILER})
module load $(${SPACK_EXE} module find -m tcl boost %${COMPILER})
module load $(${SPACK_EXE} module find -m tcl netlib-lapack %${COMPILER})

# Clean before cmake configure
set +e
rm -rf CMakeFiles
rm -f CMakeCache.txt
set -e

(set -x; which cmake)
(set -x; which mpirun)

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
  -DBoostLib_INCLUDE_DIRS:PATH=$(${SPACK_EXE} location -i boost %${COMPILER})/include \
  -DBoostLib_LIBRARY_DIRS:PATH=$(${SPACK_EXE} location -i boost %${COMPILER})/lib \
  -DTPL_ENABLE_SuperLU:BOOL=ON \
  -DSuperLU_INCLUDE_DIRS:PATH=$(${SPACK_EXE} location -i superlu %${COMPILER})/include \
  -DSuperLU_LIBRARY_DIRS:PATH=$(${SPACK_EXE} location -i superlu %${COMPILER})/lib \
  -DTPL_ENABLE_Netcdf:BOOL=ON \
  -DNetCDF_ROOT:PATH=$(${SPACK_EXE} location -i netcdf %${COMPILER}) \
  -DTPL_ENABLE_Pnetcdf:BOOL=ON \
  -DPNetCDF_ROOT:PATH=$(${SPACK_EXE} location -i parallel-netcdf %${COMPILER}) \
  -DTPL_ENABLE_HDF5:BOOL=ON \
  -DHDF5_ROOT:PATH=$(${SPACK_EXE} location -i hdf5 %${COMPILER}) \
  -DHDF5_NO_SYSTEM_PATHS:BOOL=ON \
  -DTPL_ENABLE_Zlib:BOOL=ON \
  -DZlib_INCLUDE_DIRS:PATH=$(${SPACK_EXE} location -i zlib %${COMPILER})/include \
  -DZlib_LIBRARY_DIRS:PATH=$(${SPACK_EXE} location -i zlib %${COMPILER})/lib \
  -DTPL_ENABLE_BLAS:BOOL=ON \
  -DBLAS_INCLUDE_DIRS:PATH=$(${SPACK_EXE} location -i netlib-lapack %${COMPILER})/include \
  -DBLAS_LIBRARY_DIRS:PATH=$(${SPACK_EXE} location -i netlib-lapack %${COMPILER})/lib \
  ..

# Uncomment the next line after you make sure you are not on a login node
# and run this script to configure and build Nalu
#make -j 24
#make install

rm -rf /dev/shm/*
