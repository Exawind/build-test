#!/bin/bash

#Script for installing Nalu on a Mac using Spack with GCC compiler

# Control over printing and executing commands
print_cmds=true
execute_cmds=true

# Function for printing and executing commands
cmd() {
  if ${print_cmds}; then echo "+ $@"; fi
  if ${execute_cmds}; then eval "$@"; fi
}

# Get general preferred Nalu constraints from a single location
cmd "source ../spack_config/shared_constraints.sh"

cmd "spack install nalu %gcc@7.2.0 ^${TRILINOS}@develop ${GENERAL_CONSTRAINTS}"
