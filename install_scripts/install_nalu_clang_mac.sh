#!/bin/bash

#Script for installing Nalu on a Mac using Spack with Apple's Clang compiler

# Function for printing and executing commands
cmd() {
  echo "+ $@"
  eval "$@"
}

# Get general preferred Nalu constraints from a single location
cmd "source ../configs/shared_constraints.sh"

# Disable openmp on osx
TRILINOS=$(sed 's/+openmp/~openmp/g' <<<"${TRILINOS}")

cmd "spack install nalu+openfast+tioga+hypre %clang@9.0.0-apple ^${TRILINOS}@develop"
