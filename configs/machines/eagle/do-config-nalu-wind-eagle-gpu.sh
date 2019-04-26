#!/bin/bash -l

# Instructions:
# Make a directory in the Nalu-Wind directory for building,
# Copy this script to that directory and edit the
# options below to your own needs and run it.

COMPILER=gcc #intel

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
elif [ "${COMPILER}" == 'intel' ]; then
  CXX_COMPILER=mpiicpc
  C_COMPILER=mpiicc
  FORTRAN_COMPILER=mpiifort
  FLAGS="-O2 -xSKYLAKE-AVX512"
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
if [ "${COMPILER}" == 'gcc' ]; then
  cmd "module use /nopt/nrel/ecom/hpacf/software/modules-2018-11-21/gcc-7.3.0"
elif [ "${COMPILER}" == 'intel' ]; then
  cmd "module use /nopt/nrel/ecom/hpacf/software/modules/intel-18.0.4"
fi
cmd "module load gcc/7.3.0"
cmd "module load python/2.7.15"
cmd "module load git"
cmd "module load binutils"
if [ "${COMPILER}" == 'gcc' ]; then
  cmd "module load openmpi"
  cmd "module load netlib-lapack"
elif [ "${COMPILER}" == 'intel' ]; then
  cmd "module load intel-parallel-studio/cluster.2018.4"
  cmd "module load intel-mpi/2018.4.274"
  cmd "module load intel-mkl/2018.4.274"
fi
cmd "module load openfast"
cmd "module load hypre"
cmd "module load tioga"
cmd "module load yaml-cpp"
cmd "module load cmake"
cmd "module load fftw"
cmd "module load cuda"
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
if [ "${COMPILER}" == 'gcc' ]; then
  cmd "which orterun"
elif [ "${COMPILER}" == 'intel' ]; then
  cmd "which mpirun"
fi

TRILINOS_ROOT_DIR=$(spack location -i trilinos)

(set -x; cmake \
  -DCMAKE_CXX_COMPILER:PATH=mpic++ \
  -DTrilinos_DIR:PATH=${TRILINOS_ROOT_DIR} \
  -DYAML_DIR:PATH=${YAML_CPP_ROOT_DIR} \
  -DCMAKE_BUILD_TYPE:STRING=RELEASE \
  -DENABLE_DOCUMENTATION:BOOL=OFF \
  -DENABLE_TESTS:BOOL=ON \
  -DENABLE_CUDA:BOOL=ON \
  -DMPIEXEC_EXECUTABLE:STRING=$(which orterun) \
  -DMPIEXEC_NUMPROC_FLAG:STRING="-np" \
  ..)

(set -x; VERBOSE=1 nice make -j 42)
