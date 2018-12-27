#!/bin/bash -l

cmd() {
  echo "+ $@"
  eval "$@"
}

set -e

cmd "source ../configs/shared-constraints.sh"
cmd "spack install nalu-wind+fftw+hypre+tioga+catalyst %gcc@7.3.0 ^${TRILINOS}@develop"
