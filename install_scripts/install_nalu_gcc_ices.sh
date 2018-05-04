#!/bin/bash

#Script for installing Nalu-Wind on an Ices machine using Spack with GCC compiler

# Function for printing and executing commands
cmd() {
  echo "+ $@"
  eval "$@"
}

# Get general preferred Nalu-Wind constraints from a single location
cmd "source ${SPACK_ROOT}/../build-test/configs/shared-constraints.sh"

cmd "spack install nalu-wind %gcc@7.2.0 ^${TRILINOS}@develop"
