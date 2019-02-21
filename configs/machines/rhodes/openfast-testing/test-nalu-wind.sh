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
  export CXXFLAGS="-fsanitize=address -fno-omit-frame-pointer -O2 -march=native -mtune=native"
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
cmd "module load trilinos"
cmd "module load tioga"
cmd "module load yaml-cpp"
cmd "module load hypre"
cmd "module load openfast"
cmd "module load fftw"
cmd "module load trilinos-catalyst-ioss-adapter"
cmd "module list"

# Clean before cmake configure
set +e
cmd "rm -rf CMakeFiles"
cmd "rm -f CMakeCache.txt"
set -e

cmd "which mpiexec"

#To run with asan use this same script to set up the same environment as building and replace cmake and make with:
export ASAN_OPTIONS=detect_container_overflow=0
printf "leak:libopen-pal\nleak:libmpi\nleak:libnetcdf" > /home/jrood/exawind/nalu-wind/build/asan.supp
export LSAN_OPTIONS=suppressions=/home/jrood/exawind/nalu-wind/build/asan.supp
(set -x; ctest -VV -R nrel5MWactuatorLine)

