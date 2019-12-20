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
COMPILER=gcc
COMPILER_VERSION=7.4.0
#For Intel compiler front end
GCC_COMPILER_VERSION=7.4.0

if [ "${COMPILER}" == 'gcc' ] || [ "${COMPILER}" == 'clang' ]; then
  CXX_COMPILER=mpicxx
  C_COMPILER=mpicc
  FORTRAN_COMPILER=mpifort
  FLAGS="-O2 -march=native -mtune=native"
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
cmd "module load trilinos-catalyst-ioss-adapter"
cmd "module load boost"
cmd "module list"

# Clean before cmake configure
set +e
cmd "rm -rf CMakeFiles"
cmd "rm -f CMakeCache.txt"
set -e

cmd "which mpiexec"

# Extra TPLs that can be included in the cmake configure:
#  -DENABLE_PARAVIEW_CATALYST:BOOL=ON \
#  -DPARAVIEW_CATALYST_INSTALL_PATH:PATH=${CATALYST_IOSS_ADAPTER_ROOT_DIR} \
#  -DENABLE_OPENFAST:BOOL=ON \
#  -DOpenFAST_DIR:PATH=${OPENFAST_ROOT_DIR} \
#  -DENABLE_FFTW:BOOL=ON \
#  -DFFTW_DIR:PATH=${FFTW_ROOT_DIR} \
#  -DCMAKE_BUILD_RPATH:STRING="${NETLIB_LAPACK_ROOT_DIR}/lib64;${TIOGA_ROOT_DIR}/lib;${HYPRE_ROOT_DIR}/lib;${OPENFAST_ROOT_DIR}/lib;${FFTW_ROOT_DIR}/lib;${YAML_ROOT_DIR}/lib;${TRILINOS_ROOT_DIR}/lib;$(pwd)" \

(set -x; cmake \
  -DCMAKE_CXX_COMPILER:STRING=${CXX_COMPILER} \
  -DCMAKE_CXX_FLAGS:STRING="${FLAGS}" \
  -DCMAKE_C_COMPILER:STRING=${C_COMPILER} \
  -DCMAKE_C_FLAGS:STRING="${FLAGS}" \
  -DCMAKE_Fortran_COMPILER:STRING=${FORTRAN_COMPILER} \
  -DCMAKE_Fortran_FLAGS:STRING="${FLAGS}" \
  -DMPI_CXX_COMPILER:STRING=${CXX_COMPILER} \
  -DMPI_C_COMPILER:STRING=${C_COMPILER} \
  -DMPI_Fortran_COMPILER:STRING=${FORTRAN_COMPILER} \
  -DMPIEXEC_PREFLAGS:STRING="${OVERSUBSCRIBE_FLAGS}" \
  -DTrilinos_DIR:PATH=${TRILINOS_ROOT_DIR} \
  -DYAML_DIR:PATH=${YAML_CPP_ROOT_DIR} \
  -DBoost_DIR:PATH=${BOOST_ROOT_DIR} \
  -DENABLE_HYPRE:BOOL=ON \
  -DHYPRE_DIR:PATH=${HYPRE_ROOT_DIR} \
  -DENABLE_TIOGA:BOOL=ON \
  -DTIOGA_DIR:PATH=${TIOGA_ROOT_DIR} \
  -DCMAKE_BUILD_TYPE:STRING=RELEASE \
  -DENABLE_DOCUMENTATION:BOOL=OFF \
  -DENABLE_TESTS:BOOL=ON \
  -DCMAKE_SKIP_BUILD_RPATH:BOOL=FALSE \
  -DCMAKE_BUILD_WITH_INSTALL_RPATH:BOOL=FALSE \
  -DCMAKE_INSTALL_RPATH_USE_LINK_PATH:BOOL=TRUE \
  -DCMAKE_BUILD_RPATH:STRING="${NETLIB_LAPACK_ROOT_DIR}/lib64;${TIOGA_ROOT_DIR}/lib;${HYPRE_ROOT_DIR}/lib;${YAML_ROOT_DIR}/lib;${TRILINOS_ROOT_DIR}/lib;$(pwd)" \
  ..)

(set -x; nice make -j 64)
