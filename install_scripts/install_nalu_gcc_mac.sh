#!/bin/bash

#Script for installing Nalu on a Mac using Spack with GCC compiler

# Function for printing and executing commands
cmd() {
  echo "+ $@"
  eval "$@"
}

# Get general preferred Nalu constraints from a single location
cmd "source ../spack_config/shared_constraints.sh"

# Disable openmp on osx
TRILINOS=$(sed 's/+openmp/~openmp/g' <<<"${TRILINOS}")

cmd "spack install nalu %gcc@7.2.0 ^${TRILINOS}@develop"
