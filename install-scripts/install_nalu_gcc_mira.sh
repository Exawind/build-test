#!/bin/bash

#Script for installing Nalu on Mira using Spack with GCC compiler

# Function for printing and executing commands
cmd() {
  echo "+ $@"
  eval "$@"
}

set -e

# Get general preferred Nalu constraints from a single location
cmd "source ../configs/shared-constraints.sh"

# Disable openmp on Mira
TRILINOS=$(sed 's/+openmp/~openmp/g' <<<"${TRILINOS}")

cmd "nice spack install -j 8 nalu-wind+hypre %gcc@4.8.4 ^${TRILINOS}@develop"
