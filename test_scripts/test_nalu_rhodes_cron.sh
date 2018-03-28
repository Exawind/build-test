#!/bin/bash -l

#Script that runs the nightly tests at NREL on Rhodes

set -e

cd /projects/ecp/exawind/nalu_testing/jobs && \
nice -n19 ionice -c2 -n7 \
/projects/ecp/exawind/nalu_testing/NaluSpack/test_scripts/test_nalu.sh rhodes &> \
"TestNalu-$(date +%Y-%m-%d).log"
