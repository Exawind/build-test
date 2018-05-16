#!/bin/bash

#Script for installing Nalu on Mutrino using Spack with GCC compiler.

## I am not sure if we need to hand-tune a specific packages.yaml for Cori...
#With the Cori-specific packages.yaml we are using many external
#packages already installed on Cori over installing our own
#and are using Cray's default mpich.Therefore there are a few 
#minor differences to the "official" TPL versions.
#This can/should be run on a login node

set -e

# Get general preferred Nalu constraints from a single location
source ../configs/shared-constraints.sh

(set -x; spack -k install -j 4 -v nalu-wind %gcc@7.2.0 ^${TRILINOS}@develop)
# (set -x; spack -k install -j 1 -v nalu-wind %gcc@7.2.0 ^${TRILINOS}@develop)
