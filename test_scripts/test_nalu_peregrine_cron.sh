#!/bin/bash -l

#Script that runs the nightly tests at NREL on Peregrine

cd /projects/windsim/exawind/NaluNightlyTesting/jobs && \
qsub \
-N test_nalu \
-l nodes=1:ppn=24,walltime=4:00:00,feature=haswell \
-A windsim \
-q short \
-j oe \
-W umask=002 \
/projects/windsim/exawind/NaluNightlyTesting/NaluSpack/test_scripts/test_nalu_peregrine.sh

