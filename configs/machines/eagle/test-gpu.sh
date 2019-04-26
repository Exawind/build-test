#!/bin/bash -l

COMPILER=gcc

export OMPI_MCA_opal_cuda_support=1
export EXAWIND_CUDA_WRAPPER=$(spack location -i trilinos)/bin/nvcc_wrapper
export CUDA_LAUNCH_BLOCKING=1
export CUDA_MANAGED_FORCE_DEVICE_ALLOC=1
export KOKKOS_ARCH="SKX;Volta70"
export KOKKOS_DEVICES=Cuda
export KOKKOS_CUDA_OPTIONS="enable_lambda,force_uvm"
export NVCC_WRAPPER_DEFAULT_COMPILER=g++
export OMPI_CXX=${EXAWIND_CUDA_WRAPPER}
export CXX=${EXAWIND_CUDA_WRAPPER}
C_COMPILER=mpicc
FORTRAN_COMPILER=mpifort
  
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
cmd "module use /nopt/nrel/ecom/hpacf/software/modules-2018-11-21/gcc-7.3.0"
cmd "module load gcc/7.3.0"
cmd "module load python/2.7.15"
cmd "module load git"
cmd "module load binutils"
cmd "module load openmpi"
cmd "module load netlib-lapack"
cmd "module load openfast"
cmd "module load hypre"
cmd "module load tioga"
cmd "module load yaml-cpp"
cmd "module load cmake"
cmd "module load fftw"
cmd "module load cuda"

#(set -x; srun -t 00:30:00 -N 1 -A hfm -n 1 --gres=gpu:1 ./unittestX --gtest_filter=*.NGP*)
(set -x; ctest)
