#!/bin/bash

#PBS -N paraview_build_gcc
#PBS -l nodes=1:ppn=24,walltime=1:00:00,feature=haswell
#PBS -A windsim
#PBS -q debug
#PBS -j oe
#PBS -W umask=002

#Script for installing Nalu on Peregrine using Spack with GCC compiler

# Function for printing and executing commands
cmd() {
  echo "+ $@"
  eval "$@"
}

set -e

cmd "module purge"
cmd "module use /nopt/nrel/ecom/ecp/base/modules/gcc-6.2.0"
cmd "module load gcc/6.2.0"
cmd "module load python/2.7.14"
cmd "module load git/2.17.0"
cmd "module load curl/7.59.0"
cmd "module load binutils/2.29.1"
cmd "module load texinfo/6.5"
cmd "module load texlive/live"
cmd "module list"

# Sometimes /tmp runs out of space for some reason so set TMPDIR to /scratch
cmd "mkdir -p /scratch/${USER}/.tmp"
cmd "export TMPDIR=/scratch/${USER}/.tmp"

cmd "nice spack install -j 12 paraview+mpi+python+qt+opengl2+visit+boxlib %gcc@6.2.0"
#cmd "spack install paraview+mpi+python+osmesa+visit+boxlib %gcc@6.2.0"
