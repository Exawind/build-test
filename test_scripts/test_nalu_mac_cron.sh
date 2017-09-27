#!/bin/bash -l

#Script that runs the nightly tests at NREL on a Mac

set -e

cd /Users/jrood/NaluNightlyTests/jobs && \
/Users/jrood/NaluNightlyTesting/NaluSpack/test_scripts/test_nalu.sh mac &> "TestNalu-$(date +%Y-%m-%d).log"
