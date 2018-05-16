#!/bin/bash

#Script for installing Percept on Cori using Spack with GCC compiler

# Function for printing and executing commands
cmd() {
  echo "+ $@"
  eval "$@"
}

set -e

# Get general preferred percept constraints from a single location
cmd "source ../configs/shared-constraints.sh"

cmd "spack install percept %gcc@6.3.0 ^${TRILINOS_PERCEPT}@12.12.1"
