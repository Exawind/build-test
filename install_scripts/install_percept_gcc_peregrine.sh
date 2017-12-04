#!/bin/bash

#PBS -N percept_build_gcc
#PBS -l nodes=1:ppn=24,walltime=4:00:00
#PBS -A windsim
#PBS -q short
#PBS -j oe
#PBS -W umask=002

#Script for installing Percept on Peregrine using Spack with GCC compiler

# Function for printing and executing commands
cmd() {
  echo "+ $@"
  eval "$@"
}

set -e

cmd "module purge"
cmd "module load gcc/5.2.0"
cmd "module load python/2.7.8 &> /dev/null"
cmd "module unload mkl"

# Get general preferred Nalu constraints from a single location
TRILINOS="trilinos~alloptpkgs~xsdkflags~metis~mumps~superlu-dist+superlu~hypre+hdf5~suite-sparse~python~shared+boost+tpetra+epetra+epetraext+exodus+pnetcdf+zlib+stk+teuchos+belos+zoltan+zoltan2~amesos+amesos2~anasazi~ifpack+ifpack2+muelu~fortran~ml+gtest+aztec+sacado~x11+instantiate~instantiate_cmplx~dtk~fortrilinos~openmp+shards~nox+intrepid~intrepid2+cgns"
GENERAL_CONSTRAINTS="^cmake@3.7.2 ^boost+filesystem+graph+mpi+program_options+regex+serialization+signals+system+thread@1.60.0 ^parallel-netcdf@1.6.1 ^hdf5@1.8.16 ^netcdf@4.3.3.1 ^superlu@4.3"
#cmd "source ../spack_config/shared_constraints_percept.sh"

# Fix for Peregrine's broken linker
cmd "spack install binutils %gcc@5.2.0"
cmd "source ${SPACK_ROOT}/share/spack/setup-env.sh"
cmd "spack load binutils"

# Sometimes /tmp runs out of space for some reason so set TMPDIR to /scratch
cmd "mkdir -p /scratch/${USER}/.tmp"
cmd "export TMPDIR=/scratch/${USER}/.tmp"

cmd "spack install percept %gcc@5.2.0 ^${TRILINOS}@12.12.1 ${GENERAL_CONSTRAINTS}"
