#!/bin/bash -l

#Script that runs the nightly tests at NREL on Merlin

cd /home/jrood/NaluNightlyTesting/jobs && \
qsub \
-N test_nalu \
-l nodes=1:ppn=24,walltime=12:00:00 \
-A windFlowModeling \
-q batch \
-j oe \
-W umask=002 \
-F "merlin" \
/home/jrood/NaluNightlyTesting/NaluSpack/test_scripts/test_nalu.sh
