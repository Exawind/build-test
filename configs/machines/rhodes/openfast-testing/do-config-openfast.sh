#!/bin/bash -l
 
set -e

cmd() {
  echo "+ $@"
  eval "$@"
}

# Instructions:
# Make a directory in the Nalu-Wind directory for building,
# Copy this script to that directory and edit the
# options below to your own needs and run it.

#gcc 7.3.0, gcc 4.9.4, intel 18.0.4, clang 6.0.1
COMPILER=clang
COMPILER_VERSION=6.0.1
#For Intel compiler front end
GCC_COMPILER_VERSION=7.3.0

if [ "${COMPILER}" == 'gcc' ] || [ "${COMPILER}" == 'clang' ]; then
  CXX_COMPILER=mpicxx
  C_COMPILER=mpicc
  FORTRAN_COMPILER=mpifort
  export CXXFLAGS="-O2 -march=native -mtune=native"
  OVERSUBSCRIBE_FLAGS="--use-hwthread-cpus --oversubscribe"
elif [ "${COMPILER}" == 'intel' ]; then
  CXX_COMPILER=mpiicpc
  C_COMPILER=mpiicc
  FORTRAN_COMPILER=mpiifort
  FLAGS="-O2 -xCORE-AVX2"
fi

# Set up environment on Rhodes
#Pure modules sans Spack
export MODULE_PREFIX=/opt/utilities/module_prefix
export PATH=${MODULE_PREFIX}/Modules/bin:${PATH}
module() { eval $(${MODULE_PREFIX}/Modules/bin/modulecmd $(basename ${SHELL}) $*); }

#Load some base modules
cmd "module purge"
cmd "module unuse ${MODULEPATH}"
cmd "module use /opt/compilers/modules"
cmd "module use /opt/utilities/modules"
#Use main software stack
#cmd "module use /opt/software/modules/${COMPILER}-${COMPILER_VERSION}"
#Use testing software stack
cmd "module use /projects/ecp/exawind/nalu-wind-testing/spack/share/spack/modules/linux-centos7-x86_64/${COMPILER}-${COMPILER_VERSION}"

cmd "module load unzip"
cmd "module load patch"
cmd "module load bzip2"
cmd "module load git"
cmd "module load flex"
cmd "module load bison"
cmd "module load wget"
cmd "module load bc"
cmd "module load python/2.7.15"
cmd "module load binutils"
cmd "module load cmake"
cmd "module load libxml2"
cmd "module load zlib"
cmd "module load hdf5"
cmd "module load yaml-cpp" 
if [ "${COMPILER}" == 'gcc' ]; then
  cmd "module load gcc/${COMPILER_VERSION}"
  cmd "module load openmpi"
  cmd "module load netlib-lapack"
elif [ "${COMPILER}" == 'clang' ]; then
  cmd "module load llvm/${COMPILER_VERSION}"
  cmd "module load openmpi"
  cmd "module load netlib-lapack"
elif [ "${COMPILER}" == 'intel' ]; then
  #cmd "module load gcc/${GCC_COMPILER_VERSION}"
  cmd "module load intel-parallel-studio/cluster.2018.4"
  cmd "module load intel-mpi/2018.4.274"
  cmd "module load intel-mkl/2018.4.274"
fi
cmd "module list"

# Clean before cmake configure
set +e
cmd "rm -rf CMakeFiles"
cmd "rm -f CMakeCache.txt"
set -e

cmd "which mpiexec"

(set -x; cmake \
  -DCMAKE_INSTALL_PREFIX:PATH=/home/jrood/exawind/openfast/build/install \
  -DCMAKE_CXX_COMPILER:STRING=${CXX_COMPILER} \
  -DCMAKE_C_COMPILER:STRING=${C_COMPILER} \
  -DCMAKE_Fortran_COMPILER:STRING=${FORTRAN_COMPILER} \
  -DMPI_CXX_COMPILER:STRING=${CXX_COMPILER} \
  -DMPI_C_COMPILER:STRING=${C_COMPILER} \
  -DMPI_Fortran_COMPILER:STRING=${FORTRAN_COMPILER} \
  -DHDF5_ROOT:STRING=${HDF5_ROOT_DIR} \
  -DYAML_ROOT:STRING=${YAML_CPP_ROOT_DIR} \
  -DBUILD_SHARED_LIBS:BOOL=ON \
  -DDOUBLE_PRECISION:BOOL=ON \
  -DUSE_DLL_INTERFACE:BOOL=ON \
  -DBUILD_OPENFAST_CPP_API:BOOL=ON \
  -DCMAKE_POSITION_INDEPENDENT_CODE:BOOL=ON \
  -DCMAKE_BUILD_TYPE:STRING=RelWithDebInfo \
  -DBLAS_LIBRARIES:STRING='/projects/ecp/exawind/nalu-wind-testing/spack/opt/spack/linux-centos7-x86_64/gcc-7.3.0/netlib-lapack-3.8.0-gks4jjuxpvfpb2fa6qatsw5qyocvrwgj/lib64/liblapack.so;/projects/ecp/exawind/nalu-wind-testing/spack/opt/spack/linux-centos7-x86_64/gcc-7.3.0/netlib-lapack-3.8.0-gks4jjuxpvfpb2fa6qatsw5qyocvrwgj/lib64/libblas.so' \
  -DLAPACK_LIBRARIES:STRING='/projects/ecp/exawind/nalu-wind-testing/spack/opt/spack/linux-centos7-x86_64/gcc-7.3.0/netlib-lapack-3.8.0-gks4jjuxpvfpb2fa6qatsw5qyocvrwgj/lib64/liblapack.so;/projects/ecp/exawind/nalu-wind-testing/spack/opt/spack/linux-centos7-x86_64/gcc-7.3.0/netlib-lapack-3.8.0-gks4jjuxpvfpb2fa6qatsw5qyocvrwgj/lib64/libblas.so' \
  ..)

(set -x; nice make -j 4 && make install)
