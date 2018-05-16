#!/bin/bash
 
set -e

cmd() {
  echo "+ $@"
  eval "$@"
}

CXX_COMPILER=mpicxx
C_COMPILER=mpicc
FORTRAN_COMPILER=mpifort

# Set up environment on Rhodes
#Pure modules sans Spack
export MODULE_PREFIX=/opt/software/module_prefix
export PATH=${MODULE_PREFIX}/Modules/bin:${PATH}
module() { eval $(${MODULE_PREFIX}/Modules/bin/modulecmd $(basename ${SHELL}) $*); }

#Load some base modules
cmd "module use /opt/software/modules"
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
cmd "module load python/2.7.14"
cmd "module load openmpi"
cmd "module load catalyst-ioss-adapter"
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

(set -x; cmake \
  -DCMAKE_CXX_COMPILER:STRING=${CXX_COMPILER} \
  -DCMAKE_C_COMPILER:STRING=${C_COMPILER} \
  -DCMAKE_Fortran_COMPILER:STRING=${FORTRAN_COMPILER} \
  -DMPI_CXX_COMPILER:STRING=${CXX_COMPILER} \
  -DMPI_C_COMPILER:STRING=${C_COMPILER} \
  -DMPI_Fortran_COMPILER:STRING=${FORTRAN_COMPILER} \
  -DTrilinos_DIR:PATH=${TRILINOS_ROOT_DIR} \
  -DYAML_DIR:PATH=${YAML_CPP_ROOT_DIR} \
  -DCMAKE_BUILD_TYPE:STRING=RELEASE \
  -DENABLE_DOCUMENTATION:BOOL=OFF \
  -DENABLE_TESTS:BOOL=ON \
  -DENABLE_OPENFAST:BOOL=ON \
  -DOpenFAST_DIR:PATH=${OPENFAST_ROOT_DIR} \
  -DENABLE_HYPRE:BOOL=ON \
  -DHYPRE_DIR:PATH=${HYPRE_ROOT_DIR} \
  -DENABLE_TIOGA:BOOL=ON \
  -DTIOGA_DIR:PATH=${TIOGA_ROOT_DIR} \
  -DENABLE_PARAVIEW_CATALYST:BOOL=ON \
  -DPARAVIEW_CATALYST_INSTALL_PATH:PATH=${CATALYST_IOSS_ADAPTER_ROOT_DIR} \
  .. && nice make -j32)
