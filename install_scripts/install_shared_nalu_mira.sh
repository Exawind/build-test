#!/bin/bash

#Script for installing Nalu on Mira using Spack with GCC compiler

# Function for printing and executing commands
cmd() {
  echo "+ $@"
  eval "$@"
}

set -e

export SPACK_ROOT=/projects/ExaWindFarm/spack
source ${SPACK_ROOT}/share/spack/setup-env.sh

#cd /projects/ExaWindFarm/NaluSpack/configs && ./setup_spack.sh
#spack compilers

# Get general preferred Nalu constraints from a single location
cmd "source /projects/ExaWindFarm/NaluSpack/configs/shared_constraints.sh"

# Disable openmp on Mira
TRILINOS=$(sed 's/+openmp/~openmp/g' <<<"${TRILINOS}")

cmd "spack install --only dependencies nalu+hypre+openfast %gcc@4.8.4 arch=bgq-cnk-ppc64 ^${TRILINOS}@develop"

#cmd "chmod -R ug+rX,go-w /projects/ExaWindFarm/NaluSpack /projects/ExaWindFarm/spack"
#cmd "chmod g+w /projects/ExaWindFarm/spack/"
#cmd "chmod g+w /projects/ExaWindFarm/spack/opt"
#cmd "chmod g+w /projects/ExaWindFarm/spack/opt/spack"
#cmd "chmod -R g+w /projects/ExaWindFarm/spack/opt/spack/.spack-db"
