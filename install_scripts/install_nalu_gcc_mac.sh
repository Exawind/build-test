#!/bin/bash -l

#Script for installing Nalu on a Mac using Spack with GCC compiler

# Get general preferred Nalu constraints from a single location
source ../spack_config/shared_constraints.sh

(set -x; spack install nalu %gcc@7.2.0 ^${TRILINOS}@develop ${GENERAL_CONSTRAINTS})
