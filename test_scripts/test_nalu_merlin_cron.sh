#!/bin/bash -l

#Script that runs the nightly tests at NREL on Merlin

cd /scratch/jrood/TestNalu/jobs && qsub /scratch/jrood/TestNalu/NaluSpack/test_scripts/test_nalu_merlin.sh

