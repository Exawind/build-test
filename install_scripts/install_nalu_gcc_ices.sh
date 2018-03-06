#!/bin/bash

#Script for installing Nalu on an Ices machine using Spack with GCC compiler

# Function for printing and executing commands
cmd() {
  echo "+ $@"
  eval "$@"
}

# Get general preferred Nalu constraints from a single location
cmd "source ${SPACK_ROOT}/../NaluSpack/spack_config/shared_constraints.sh"

cmd "spack install nalu %gcc@7.2.0 ^${TRILINOS}@develop"
