#!/bin/bash -l

#Script that runs the nightly Nalu-Wind tests at NREL on Peregrine

cd /projects/windsim/exawind/nalu-wind-testing/logs && \
qsub \
-N test-nalu-wind \
-l nodes=1:ppn=24,walltime=4:00:00,feature=haswell \
-A windsim \
-q short \
-j oe \
-W umask=002 \
/projects/windsim/exawind/nalu-wind-testing/build-test/test-scripts/test-nalu-wind-peregrine.sh

