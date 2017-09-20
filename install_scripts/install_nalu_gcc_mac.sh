#!/bin/bash -l

#Script for installing Nalu on a Mac using Spack with GCC compiler

set -e

# Get general preferred Nalu constraints from a single location
source ../spack_config/shared_constraints.sh

ALL_CONSTRAINTS="^openmpi@1.10.4 ${GENERAL_CONSTRAINTS}"

(set -x; spack install nalu %gcc@6.3.0 ^${TRILINOS}@develop ${ALL_CONSTRAINTS})
