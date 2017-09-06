#!/bin/bash

set -ex

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

COMPILER=intel
INSTALL_PREFIX=$(pwd)/install
SPACK_ROOT=${HOME}/spack
SPACK_EXE=${SPACK_ROOT}/bin/spack

module use ${SPACK_ROOT}/share/spack/modules/$(${SPACK_EXE} arch)
module load $(${SPACK_EXE} module find cmake %${COMPILER})
module load $(${SPACK_EXE} module find openmpi %${COMPILER})
module load $(${SPACK_EXE} module find hdf5 %${COMPILER})
module load $(${SPACK_EXE} module find netcdf %${COMPILER})
module load $(${SPACK_EXE} module find parallel-netcdf %${COMPILER})
module load $(${SPACK_EXE} module find zlib %${COMPILER})
module load $(${SPACK_EXE} module find superlu %${COMPILER})
module load $(${SPACK_EXE} module find boost %${COMPILER})
module load $(${SPACK_EXE} module find netlib-lapack %${COMPILER})

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
  -DBoost_ROOT:PATH=$(${SPACK_EXE} location -i boost %${COMPILER}) \
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

make -j 24
make install

rm -rf /dev/shm/*
