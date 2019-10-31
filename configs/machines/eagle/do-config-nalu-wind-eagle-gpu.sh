#!/bin/bash -l

COMPILER=gcc

export SPACK_ROOT=/projects/hfm/exawind/nalu-wind-testing/spack
source ${SPACK_ROOT}/share/spack/setup-env.sh

if [ "${COMPILER}" == 'gcc' ]; then
  export OMPI_MCA_opal_cuda_support=1
  export EXAWIND_CUDA_WRAPPER=$(spack location -i trilinos)/bin/nvcc_wrapper
  export CUDA_LAUNCH_BLOCKING=1
  export CUDA_MANAGED_FORCE_DEVICE_ALLOC=1
  export KOKKOS_ARCH="SKX;Volta70"
  export NVCC_WRAPPER_DEFAULT_COMPILER=g++
  export OMPI_CXX=${EXAWIND_CUDA_WRAPPER}
  export CXX=mpic++
  export CUDACXX=$(which nvcc)
  C_COMPILER=mpicc
  FORTRAN_COMPILER=mpifort
fi
  
set -e

cmd() {
  echo "+ $@"
  eval "$@"
}

# Set up environment on Eagle
cmd "module purge"
cmd "module unuse ${MODULEPATH}"
cmd "module use /nopt/nrel/ecom/hpacf/compilers/modules"
cmd "module use /nopt/nrel/ecom/hpacf/utilities/modules"
cmd "module use ${SPACK_ROOT}/share/spack/modules/linux-centos7-x86_64/gcc-7.4.0"
cmd "module load gcc"
cmd "module load python"
cmd "module load git"
cmd "module load binutils"
cmd "module load openmpi"
cmd "module load netlib-lapack"
cmd "module load yaml-cpp"
cmd "module load cmake"
cmd "module load cuda/9.2.88"
cmd "module list"

# Set tmpdir to the scratch filesystem so it doesn't run out of space
cmd "mkdir -p ${HOME}/.tmp"
cmd "export TMPDIR=${HOME}/.tmp"

# Clean before cmake configure
set +e
cmd "rm -rf CMakeFiles"
cmd "rm -f CMakeCache.txt"
set -e

cmd "which cmake"
cmd "which orterun"

TRILINOS_ROOT_DIR=$(spack location -i trilinos)

(set -x; cmake \
  -DCMAKE_CXX_COMPILER:PATH=mpic++ \
  -DTrilinos_DIR:PATH=${TRILINOS_ROOT_DIR} \
  -DYAML_DIR:PATH=${YAML_CPP_ROOT_DIR} \
  -DCMAKE_BUILD_TYPE:STRING=RelWithDebInfo \
  -DENABLE_DOCUMENTATION:BOOL=OFF \
  -DENABLE_TESTS:BOOL=ON \
  -DENABLE_CUDA:BOOL=ON \
  -DMPIEXEC_EXECUTABLE:STRING=$(which orterun) \
  -DMPIEXEC_NUMPROC_FLAG:STRING="-np" \
  ..)

(set -x; make -j40)
