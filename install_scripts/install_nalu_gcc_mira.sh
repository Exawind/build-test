#!/bin/bash

#Script for installing Nalu on Mira using Spack with GCC compiler

# Function for printing and executing commands
cmd() {
  echo "+ $@"
  eval "$@"
}

set -e

# Get general preferred Nalu constraints from a single location
cmd "source ../configs/shared_constraints.sh"

# Disable openmp on Mira
TRILINOS=$(sed 's/+openmp/~openmp/g' <<<"${TRILINOS}")

cmd "spack install --only dependencies nalu+hypre+openfast %gcc@4.8.4 arch=bgq-cnk-ppc64 ^${TRILINOS}@develop"
