#!/bin/bash -l

#Script for installing Nalu on a Mac using Spack with GCC compiler

set -e

NALUSPACK_ROOT=`pwd`

# Get general preferred Nalu constraints from a single location
source ${NALUSPACK_ROOT}/../spack_config/general_preferred_nalu_constraints.sh

MACHINE_SPECIFIC_CONSTRAINTS="^openmpi@1.10.3 ^cmake@3.6.1"

ALL_CONSTRAINTS="${GENERAL_CONSTRAINTS} ${MACHINE_SPECIFIC_CONSTRAINTS}"

(set -x; spack install nalu %gcc@6.3.0 ^${TRILINOS}@develop ${ALL_CONSTRAINTS})
