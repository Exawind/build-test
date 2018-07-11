#!/bin/bash -l

#Script for installing Nalu on Theta using Spack with GCC compiler

# Function for printing and executing commands
cmd() {
  echo "+ $@"
  eval "$@"
}

set -e

# Assuming a standard login env with PrgEnv-gnu loaded instead of PrgEnv-intel

# Get general preferred Nalu constraints from a single location
cmd "source ../configs/shared-constraints.sh"

cmd "nice ${HOME}/spack/bin/spack install -j 8 nalu-wind %intel@18.2.199 ^${TRILINOS}@develop"
