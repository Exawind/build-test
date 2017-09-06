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
SPACK_ROOT=${HOME}/spack
SPACK_EXE=${SPACK_ROOT}/bin/spack
TRILINOS_ROOT=${HOME}/Trilinos/build/install

module use ${SPACK_ROOT}/share/spack/modules/$(${SPACK_EXE} arch)
module load $(${SPACK_EXE} module find cmake %${COMPILER})
module load $(${SPACK_EXE} module find openmpi %${COMPILER})

export TMPDIR=/dev/shm

set +e
rm -rf CMakeFiles
rm -f CMakeCache.txt
set -e

cmake \
  -DTrilinos_DIR:PATH=${TRILINOS_ROOT} \
  -DYAML_DIR:PATH=$(${SPACK_EXE} location -i yaml-cpp %${COMPILER}) \
  -DCMAKE_BUILD_TYPE:STRING=RELEASE \
  -DBUILD_DOCUMENTATION:BOOL=OFF \
  -DENABLE_TESTS:BOOL=ON \
  ..

make -j 24

rm -rf /dev/shm/*
