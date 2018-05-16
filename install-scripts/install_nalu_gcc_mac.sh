#!/bin/bash

#Script for installing Nalu on a Mac using Spack with GCC compiler

# Function for printing and executing commands
cmd() {
  echo "+ $@"
  eval "$@"
}

# Get general preferred Nalu constraints from a single location
cmd "source ../configs/shared-constraints.sh"

# Disable openmp on osx
TRILINOS=$(sed 's/+openmp/~openmp/g' <<<"${TRILINOS}")

cmd "spack install nalu-wind %gcc@7.3.0 ^${TRILINOS}@develop"
