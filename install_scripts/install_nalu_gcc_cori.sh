#!/bin/bash

#Script for installing Nalu on Cori using Spack with GCC compiler.

#With the Cori-specific packages.yaml we are using many external
#packages already installed on Cori over installing our own
#and are using Cray's default mpich.Therefore there are a few 
#minor differences to the "official" TPL versions.
#This can/should be run on a login node

set -e

# Get general preferred Nalu constraints from a single location
source ../configs/shared_constraints.sh

(set -x; spack install -j 4 nalu %gcc@4.9.3 ^${TRILINOS}@develop)
