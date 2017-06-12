#!/bin/bash

#Script for installing Nalu on Cori using Spack with GCC compiler.
#With the Cori-specific packages.yaml we are using many external
#packages already installed on Cori over installing our own
#and are using Cray's default mpich.
#Therefore there are a few minor differences to the "official" TPL versions.

set -e

TRILINOS="
^trilinos~alloptpkgs~xsdkflags~metis~mumps~superlu-dist+superlu~hypre+hdf5~suite-sparse~python~shared~debug+boost+tpetra~epetra~epetraext+exodus+pnetcdf+zlib+stk+teuchos+belos+zoltan+zoltan2~amesos+amesos2~ifpack+ifpack2+muelu~fortran~ml+gtest~aztec~sacado~x11+instantiate~instantiate_cmplx~dtk@master
"

TPLS="
^boost@1.60.0 \
^cmake@3.5.2 \
^parallel-netcdf@1.6.1 \
^hdf5@1.8.16 \
^netcdf@4.3.3.1 \
^zlib@1.2.8 \
^superlu@4.3
"

spack install -j 4 nalu %gcc@4.9.3 ${TRILINOS} ${TPLS}
