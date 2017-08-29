#!/bin/bash -l

#Script that runs the nightly tests at NREL on Merlin

cd /home/jrood/NaluNightlyTesting/jobs && qsub /home/jrood/NaluNightlyTesting/NaluSpack/test_scripts/test_nalu_merlin.sh

