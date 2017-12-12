#!/bin/bash

TRILINOS="trilinos~alloptpkgs~xsdkflags~metis~mumps~superlu-dist+superlu~hypre+hdf5~suite-sparse~python~shared+boost+tpetra~epetra~epetraext+exodus+pnetcdf+zlib+stk+teuchos+belos+zoltan+zoltan2~amesos+amesos2~anasazi~ifpack+ifpack2+muelu~fortran~ml+gtest~aztec~sacado~x11+instantiate~instantiate_cmplx~dtk~fortrilinos+openmp~nox+shards~intrepid~intrepid2"
#TRILINOS="trilinos~alloptpkgs~xsdkflags~metis~mumps~superlu-dist+superlu~hypre+hdf5~suite-sparse~python~shared+boost+tpetra~epetra~epetraext+exodus+pnetcdf+zlib+stk+teuchos+belos+zoltan+zoltan2~amesos+amesos2~anasazi~ifpack+ifpack2+muelu~fortran~ml+gtest~aztec~sacado~x11+instantiate~instantiate_cmplx~dtk~fortrilinos+openmp~rol~nox+shards~intrepid~intrepid2~cgns"

# This is the explicit trilinos signature that can be used for percept
TRILINOS_PERCEPT="trilinos~alloptpkgs~xsdkflags~metis~mumps~superlu-dist+superlu~hypre+hdf5~suite-sparse~python~shared+boost+tpetra+epetra+epetraext+exodus+pnetcdf+zlib+stk+teuchos+belos+zoltan+zoltan2~amesos+amesos2~anasazi~ifpack+ifpack2+muelu~fortran~ml+gtest+aztec+sacado~x11+instantiate~instantiate_cmplx~dtk~fortrilinos~openmp~rol~nox+shards+intrepid~intrepid2+cgns"

GENERAL_CONSTRAINTS="^boost@1.60.0 ^parallel-netcdf@1.6.1 ^hdf5@1.8.16 ^netcdf@4.3.3.1 ^superlu@4.3"

# These are the constraints that should be used for percept
GENERAL_CONSTRAINTS_PERCEPT="^boost@1.60.0 ^parallel-netcdf@1.6.1 ^hdf5@1.8.16 ^netcdf@4.3.3.1 maxdims=65536 maxvars=524288 ^superlu@4.3"
