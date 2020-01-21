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
COMPILER_VERSION=7.0.1
#For Intel compiler front end
GCC_COMPILER_VERSION=7.4.0

if [ "${COMPILER}" == 'gcc' ] || [ "${COMPILER}" == 'clang' ]; then
  CXX_COMPILER=mpicxx
  C_COMPILER=mpicc
  FORTRAN_COMPILER=mpifort
  printf "src:/projects/ecp/exawind/nalu-wind-testing/spack/opt/spack/linux-centos7-x86_64/clang-7.0.1/yaml-cpp-0.6.2-4jpmv5uvxyqo4qfzshvbmxmi357zmemz/include/yaml-cpp/node/impl.h" > /home/jrood/exawind/nalu-wind/build/asan_blacklist.txt
  export CXXFLAGS="-fsanitize=address -fsanitize-blacklist=/home/jrood/exawind/nalu-wind/build/asan_blacklist.txt -fno-omit-frame-pointer"
  OVERSUBSCRIBE_FLAGS="--use-hwthread-cpus --oversubscribe"
elif [ "${COMPILER}" == 'intel' ]; then
  CXX_COMPILER=mpiicpc
  C_COMPILER=mpiicc
  FORTRAN_COMPILER=mpiifort
  FLAGS="-O2 -xCORE-AVX2"
fi

# Set up environment on Rhodes
#Pure modules sans Spack
export MODULE_PREFIX=/opt/utilities/modules_prefix
export PATH=${MODULE_PREFIX}/bin:${PATH}
module() { eval $(${MODULE_PREFIX}/bin/modulecmd $(basename ${SHELL}) $*); }

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
cmd "module load python"
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
cmd "module load boost"
cmd "module load xterm"
cmd "module load trilinos-catalyst-ioss-adapter"
cmd "module list"

export ASAN_OPTIONS=detect_container_overflow=0

#(set -x; ctest -VV -R ablNeutralEdge)
mpiexec -n 1 lldb -- /home/jrood/exawind/nalu-wind/build/naluX -i /home/jrood/exawind/nalu-wind/reg_tests/test_files/ablNeutralEdge/ablNeutralEdge.i -o out.log

