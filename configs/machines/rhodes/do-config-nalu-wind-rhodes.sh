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

COMPILER=gcc #or intel

if [ "${COMPILER}" == 'gcc' ]; then
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
export MODULE_PREFIX=/opt/utilities/module_prefix
export PATH=${MODULE_PREFIX}/Modules/bin:${PATH}
module() { eval $(${MODULE_PREFIX}/Modules/bin/modulecmd $(basename ${SHELL}) $*); }

#Load some base modules
cmd "module use /opt/compilers/modules"
cmd "module use /opt/utilities/modules"
cmd "module use /opt/software/modules/gcc-7.3.0"
cmd "module purge"
cmd "module load unzip"
cmd "module load patch"
cmd "module load bzip2"
cmd "module load cmake"
cmd "module load git"
cmd "module load flex"
cmd "module load bison"
cmd "module load wget"
cmd "module load bc"
cmd "module load binutils"
cmd "module load python/2.7.15"
if [ "${COMPILER}" == 'gcc' ]; then
  cmd "module load openmpi"
  cmd "module load netlib-lapack"
elif [ "${COMPILER}" == 'intel' ]; then
  cmd "module load intel-mpi/2018.4.274"
  cmd "module load intel-mkl/2018.4.274"
fi
cmd "module load trilinos-catalyst-ioss-adapter"
cmd "module load trilinos"
cmd "module load tioga"
cmd "module load yaml-cpp"
cmd "module load hypre"
cmd "module load openfast"
cmd "module list"

# Clean before cmake configure
set +e
cmd "rm -rf CMakeFiles"
cmd "rm -f CMakeCache.txt"
set -e

cmd "which cmake"
cmd "which mpirun"

# Extra TPLs that can be included in the cmake configure:
#  -DENABLE_PARAVIEW_CATALYST:BOOL=ON \
#  -DPARAVIEW_CATALYST_INSTALL_PATH:PATH=${CATALYST_IOSS_ADAPTER_ROOT_DIR} \
#  -DENABLE_OPENFAST:BOOL=ON \
#  -DOpenFAST_DIR:PATH=${OPENFAST_ROOT_DIR} \
#  -DENABLE_FFTW:BOOL=ON \
#  -DFFTW_DIR:PATH=${FFTW_ROOT_DIR} \

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
  -DCMAKE_BUILD_RPATH:STRING="${NETLIB_LAPACK_ROOT_DIR}/lib64;${TIOGA_ROOT_DIR}/lib;${HYPRE_ROOT_DIR}/lib;${OPENFAST_ROOT_DIR}/lib;${YAML_ROOT_DIR}/lib;${TRILINOS_ROOT_DIR}/lib;$(pwd)" \
  ..)

(set -x; nice make -j 64)
