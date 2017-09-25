#!/bin/bash -l

#Script that runs the nightly tests at NREL on a Mac

set -e

cd /home/jrood/NaluNightlyTests/jobs && \
/home/jrood/NaluNightlyTesting/NaluSpack/test_scripts/test_nalu.sh mac > "TestNalu-$(date +%Y-%m-%d).log"
