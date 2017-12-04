#!/bin/bash

#Script for installing Nalu on Cori using Spack with GCC compiler

# Function for printing and executing commands
cmd() {
  echo "+ $@"
  eval "$@"
}

set -e

# Get general preferred Nalu constraints from a single location
TRILINOS="trilinos~alloptpkgs~xsdkflags~metis~mumps~superlu-dist+superlu~hypre+hdf5~suite-sparse~python~shared+boost+tpetra+epetra+epetraext+exodus+pnetcdf+zlib+stk+teuchos+belos+zoltan+zoltan2~amesos+amesos2~anasazi~ifpack+ifpack2+muelu~fortran~ml+gtest+aztec+sacado~x11+instantiate~instantiate_cmplx~dtk~fortrilinos~openmp+shards~nox+intrepid~intrepid2+cgns"
GENERAL_CONSTRAINTS="^cmake@3.8.2 ^boost+filesystem+graph+mpi+program_options+regex+serialization+signals+system+thread@1.60.0 ^parallel-netcdf@1.6.1 ^hdf5@1.8.16 ^netcdf@4.3.3.1 ^superlu@4.3"

cmd "spack install percept %gcc@6.3.0 ^${TRILINOS}@12.12.1 ${GENERAL_CONSTRAINTS}"
