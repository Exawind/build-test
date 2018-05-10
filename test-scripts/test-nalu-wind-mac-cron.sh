#!/bin/bash -l

#Script that runs the nightly Nalu-Wind tests at NREL on a Mac

set -e

cd /Users/jrood/nalu-wind-testing/jobs && \
/Users/jrood/nalu-wind-testing/build-test/test-scripts/test-nalu-wind.sh mac &> "test-nalu-wind-$(date +%Y-%m-%d).log"
