#!/bin/bash

#Script for installing Nalu on a Mac using Spack with Apple's Clang compiler

# Function for printing and executing commands
cmd() {
  echo "+ $@"
  eval "$@"
}

# Get general preferred Nalu constraints from a single location
cmd "source ../configs/shared-constraints.sh"

# Disable shared and openmp on osx
TRILINOS=$(sed 's/+openmp/~openmp/g' <<<"${TRILINOS}")
TRILINOS=$(sed 's/+shared/~shared/g' <<<"${TRILINOS}")

cmd "spack install nalu-wind+fftw+tioga+hypre %clang ^${TRILINOS}@develop"
