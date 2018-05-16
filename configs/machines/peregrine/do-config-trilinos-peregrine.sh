#!/bin/bash

set -e

COMPILER=gcc #or intel
# Default to installing to 'install' directory in build directory
INSTALL_PREFIX=$(pwd)/install

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
cmd "module load git/2.17.0"
cmd "module load python/2.7.14"
cmd "module load binutils/2.29.1"
cmd "module load yaml-cpp"
cmd "module load cmake/3.9.4"
cmd "module load hdf5/1.10.1"
cmd "module load zlib/1.2.11"
cmd "module load netcdf/4.4.1.1"
cmd "module load parallel-netcdf/1.8.0"
cmd "module load boost/1.66.0"
cmd "module load superlu/4.3"
cmd "module load openfast/develop"
cmd "module load hypre/2.14.0"
cmd "module load tioga/develop"

if [ "${COMPILER}" == 'gcc' ]; then
  # Load correct modules for GCC
  cmd "module load openmpi/1.10.4"
  cmd "module load netlib-lapack/3.8.0"
  MPI_ROOT_DIR=${OPENMPI_ROOT_DIR}
  BLAS_ROOT_DIR=${NETLIB_LAPACK_ROOT_DIR}
elif [ "${COMPILER}" == 'intel' ]; then
  # Load correct modules for Intel"
  cmd "module load /nopt/nrel/ecom/ecp/base/c/spack/share/spack/modules/linux-centos7-x86_64/gcc-6.2.0/intel-parallel-studio/cluster.2018.1"
  cmd "module load intel-mpi/2018.1.163"
  cmd "module load intel-mkl/2018.1.163"
  MPI_ROOT_DIR=${INTEL_MPI_ROOT_DIR}
  BLAS_ROOT_DIR=${INTEL_MKL_ROOT_DIR}
fi
cmd "module list"

# Set tmpdir to scratch filesystem so it doesn't run out of space
cmd "mkdir -p /scratch/${USER}/.tmp"
cmd "export TMPDIR=/scratch/${USER}/.tmp"

# Clean before cmake configure
set +e
cmd "rm -rf CMakeFiles"
cmd "rm -f CMakeCache.txt"
set -e

cmd "which cmake"
cmd "which mpirun"

(set -x; cmake \
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
  -DMPI_BASE_DIR:PATH=${MPI_ROOT_DIR} \
  -DTPL_ENABLE_Boost:BOOL=ON \
  -DBoostLib_INCLUDE_DIRS:PATH=${BOOST_ROOT_DIR}/include \
  -DBoostLib_LIBRARY_DIRS:PATH=${BOOST_ROOT_DIR}/lib \
  -DTPL_ENABLE_SuperLU:BOOL=ON \
  -DSuperLU_INCLUDE_DIRS:PATH=${SUPERLU_ROOT_DIR}/include \
  -DSuperLU_LIBRARY_DIRS:PATH=${SUPERLU_ROOT_DIR}/lib \
  -DTPL_ENABLE_Netcdf:BOOL=ON \
  -DNetCDF_ROOT:PATH=${NETCDF_ROOT_DIR} \
  -DTPL_ENABLE_Pnetcdf:BOOL=ON \
  -DPNetCDF_ROOT:PATH=${PARALLEL_NETCDF_ROOT_DIR} \
  -DTPL_ENABLE_HDF5:BOOL=ON \
  -DHDF5_ROOT:PATH=${HDF5_ROOT_DIR} \
  -DHDF5_NO_SYSTEM_PATHS:BOOL=ON \
  -DTPL_ENABLE_Zlib:BOOL=ON \
  -DZlib_INCLUDE_DIRS:PATH=${ZLIB_ROOT_DIR}/include \
  -DZlib_LIBRARY_DIRS:PATH=${ZLIB_ROOT_DIR/lib \
  -DTPL_ENABLE_BLAS:BOOL=ON \
  -DBLAS_INCLUDE_DIRS:PATH=${BLAS_ROOT_DIR}/include \
  -DBLAS_LIBRARY_DIRS:PATH=${BLAS_ROOT_DIR}/lib \
  ..)
  #.. && make -j24 && make install)
  # Replace the ..) with the line above to actually build and install
