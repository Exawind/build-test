#!/bin/bash -l

#Script that runs the nightly tests at NREL on Merlin

NALU_TESTING_DIR=/scratch/jrood/TestNalu

cd ${NALU_TESTING_DIR}/jobs && qsub ${NALU_TESTING_DIR}/NaluSpack/test_scripts/test_nalu_peregrine.sh

