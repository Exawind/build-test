#!/bin/bash

#Script for installing Nalu on Cori using Spack with GCC compiler.

#With the Cori-specific packages.yaml we are using many external
#packages already installed on Cori over installing our own
#and are using Cray's default mpich.Therefore there are a few 
#minor differences to the "official" TPL versions.
#This can/should be run on a login node

set -e

NALUSPACK_ROOT=`pwd`

# Get general preferred Nalu constraints from a single location
source ${NALUSPACK_ROOT}/../spack_config/general_preferred_nalu_constraints.sh

MACHINE_SPECIFIC_CONSTRAINTS="^mpich@7.4.4 ^cmake@3.5.2 ^zlib@1.2.8"

ALL_CONSTRAINTS="${GENERAL_CONSTRAINTS} ${MACHINE_SPECIFIC_CONSTRAINTS}"

(set -x; spack install -j 4 nalu %gcc@4.9.3 ^${TRILINOS}@develop ${ALL_CONSTRAINTS})
