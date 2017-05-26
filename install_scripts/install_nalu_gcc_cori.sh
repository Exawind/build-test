#!/bin/bash

#Script for installing Nalu on Cori using Spack with GCC compiler.
#With the Cori-specific packages.yaml we are using many external
#packages already installed on Cori over installing our own
#and are using Cray's default mpich.
#Therefore there are a few minor differences to the "official" TPL versions.

set -e

TPLS="
^boost@1.60.0 \
^cmake@3.5.2 \
^parallel-netcdf@1.6.1 \
^hdf5@1.8.16 \
^netcdf@4.3.3.1 \
^zlib@1.2.8 \
^superlu@4.3
"

spack install -j 4 nalu %gcc@4.9.3 ^nalu-trilinos@master ${TPLS}
