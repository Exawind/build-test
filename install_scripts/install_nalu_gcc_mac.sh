#!/bin/bash -l

#Script for installing Nalu on a Mac using Spack with GCC compiler

set -e

# Get TPL preferences from a single location
NALUSPACK_ROOT=`pwd`
source ${NALUSPACK_ROOT}/../spack_config/tpls.sh
TPLS="${TPLS} ^openmpi@1.10.3 ^cmake@3.6.1"

spack install nalu %gcc@6.3.0 ^${TRILINOS}@develop ${TPLS}
