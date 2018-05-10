#!/bin/bash -l

#Script that runs the nightly Nalu-Wind tests at NREL on Merlin

cd /home/jrood/nalu-wind-testing/logs && \
qsub \
-N test-nalu-wind \
-l nodes=1:ppn=24,walltime=12:00:00 \
-A windsim \
-q batch \
-j oe \
-W umask=002 \
-- /home/jrood/nalu-wind-testing/build-test/test-scripts/test-nalu-wind.sh merlin
