#!/bin/bash -l

#Script that runs the nightly Nalu-Wind tests at NREL on Eagle

cd /projects/hfm/exawind/nalu-wind-testing/logs && \
sbatch \
-J test-nalu-wind \
-N 1 \
-t 4:00:00 \
-A hfm \
-p standard \
-o "%x.o%j" \
--gres=gpu:1 \
/projects/hfm/exawind/nalu-wind-testing/build-test/test-scripts/test-nalu-wind.sh

