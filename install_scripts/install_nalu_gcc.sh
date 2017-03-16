#!/bin/bash -l

#PBS -N nalu_build_gcc
#PBS -l nodes=1:ppn=24,walltime=4:00:00
#PBS -A windFlowModeling
#PBS -q short
#PBS -o $PBS_JOBNAME.log
#PBS -j oe
#PBS -W umask=002

#Script for installing Nalu on Peregrine using Spack with GCC compiler

set -e

{
module purge
module load gcc/5.2.0
module load python/2.7.8
} &> /dev/null

spack install binutils %gcc
. ${SPACK_ROOT}/share/spack/setup-env.sh
spack load binutils
# For different versions of trilinos add a '^nalu-trilinos+debug@develop'
# for a debug version of the trilinos development branch for example
spack install nalu %gcc ^openmpi+verbs+psm+tm+mxm@1.10.3 \
                        ^boost@1.60.0 \
                        ^hdf5@1.8.16 \
                        ^parallel-netcdf@1.6.1 \
                        ^netcdf@4.3.3.1
