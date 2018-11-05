#!/bin/bash -l

cmd() {
  echo "+ $@"
  eval "$@"
}

set -e

cmd "module load texlive"
cmd "source ../configs/shared-constraints.sh"
cmd "spack install nalu-wind+hypre+tioga+catalyst %gcc@6.4.0 ^${TRILINOS}@develop"
