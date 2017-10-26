#!/bin/bash

#PBS -N nalu_build_gcc
#PBS -l nodes=1:ppn=24,walltime=4:00:00
#PBS -A windFlowModeling
#PBS -q batch
#PBS -j oe
#PBS -W umask=002

#Script for installing Nalu on Merlin using Spack with GCC compiler

# Control over printing and executing commands
print_cmds=true
execute_cmds=true

# Function for printing and executing commands
cmd() {
  if ${print_cmds}; then echo "+ $@"; fi
  if ${execute_cmds}; then eval "$@"; fi
}

set -e

cmd "module purge"
cmd "module load GCCcore/4.9.2"
cmd "source ../spack_config/shared_constraints.sh"
cmd "spack install nalu %gcc@4.9.2 ^${TRILINOS}@develop ${GENERAL_CONSTRAINTS}"
