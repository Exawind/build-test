#!/bin/bash -l

#Script that runs the nightly tests at NREL on Peregrine

cd /projects/windFlowModeling/ExaWind/NaluNightlyTesting/jobs && \
qsub \
-N test_nalu \
-l nodes=1:ppn=24,walltime=4:00:00,feature=64GB \
-A windFlowModeling \
-q short \
-j oe \
-W umask=002 \
-F "peregrine" \
/projects/windFlowModeling/ExaWind/NaluNightlyTesting/NaluSpack/test_scripts/test_nalu_peregrine.sh

