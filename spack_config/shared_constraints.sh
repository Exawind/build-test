#!/bin/bash

# This is the latest trilinos constraint with all the variants explicitly stated
TRILINOS="trilinos~alloptpkgs~xsdkflags~metis~mumps~superlu-dist+superlu~hypre+hdf5~suite-sparse~python~shared+boost+tpetra~epetra~epetraext+exodus+pnetcdf+zlib+stk+teuchos+belos+zoltan+zoltan2~amesos+amesos2~anasazi~ifpack+ifpack2+muelu~fortran~ml+gtest~aztec~sacado~x11+instantiate~instantiate_cmplx~dtk~fortrilinos+openmp~rol~nox+shards~intrepid~intrepid2~cgns"

# This is the explicit trilinos signature that can be used for percept and should probably be merged into a single constraint that Nalu can use as well
TRILINOS_PERCEPT="trilinos~alloptpkgs~xsdkflags~metis~mumps~superlu-dist+superlu~hypre+hdf5~suite-sparse~python~shared+boost+tpetra+epetra+epetraext+exodus+pnetcdf+zlib+stk+teuchos+belos+zoltan+zoltan2~amesos+amesos2~anasazi~ifpack+ifpack2+muelu~fortran~ml+gtest+aztec+sacado~x11+instantiate~instantiate_cmplx~dtk~fortrilinos~openmp~rol~nox+shards+intrepid~intrepid2+cgns"

# This is the latest general constraints that should be used in the future
GENERAL_CONSTRAINTS="^boost@1.60.0 ^netcdf@4.3.3.1 maxdims=65536 maxvars=524288 ^parallel-netcdf@1.6.1 ^hdf5+cxx@1.8.16 ^superlu@4.3"
