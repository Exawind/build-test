#!/bin/bash -l

#Script that runs the nightly Nalu-Wind tests at NREL on Rhodes

set -e

cd /projects/ecp/exawind/nalu-wind-testing/jobs && \
nice -n19 ionice -c2 -n7 \
/projects/ecp/exawind/nalu-wind-testing/build-test/test-scripts/test-nalu-wind.sh rhodes &> \
"test-nalu-wind-$(date +%Y-%m-%d).log"
