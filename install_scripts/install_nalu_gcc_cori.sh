#!/bin/bash

#Script for installing Nalu on Cori using Spack with GCC compiler.
#With the Cori-specific packages.yaml we are using many external
#packages already installed on Cori over installing our own
#and are using Cray's default mpich.
#Therefore there are a few minor differences to the "official" TPL versions.

set -e

# Get TPL preferences from a single location
NALUSPACK_ROOT=`pwd`
source ${NALUSPACK_ROOT}/spack_config/tpls.sh
TPLS="${TPLS} ^cmake@3.5.2 ^zlib@1.2.8"

spack install -j 4 nalu %gcc@4.9.3 ${TRILINOS} ${TPLS}
