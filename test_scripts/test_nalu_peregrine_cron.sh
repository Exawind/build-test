#!/bin/bash -l

#Script that runs the nightly tests at NREL on Peregrine

cd /projects/windFlowModeling/ExaWind/NaluNightlyTesting/jobs && qsub /projects/windFlowModeling/ExaWind/NaluNightlyTesting/NaluSpack/test_scripts/test_nalu_peregrine.sh

