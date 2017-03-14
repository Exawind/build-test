#!/bin/bash -l

#Script that runs the nightly tests at NREL on Peregrine

set -e

cd ${SCRATCH}/TestNalu/jobs && qsub ${HOME}/NaluSpack/test_scripts/test_nalu_peregrine.sh
#cd ${SCRATCH}/TestNalu/jobs && qsub ${HOME}/NaluSpack/test_scripts/test_nalu_peregrine_old.sh
