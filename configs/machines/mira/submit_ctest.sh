#!/bin/bash

# Script for submitting Nalu-Wind test suite in pieces on Mira

set -e

start=1
end=10
block=5

for i in $(seq ${start} ${block} ${end}); do
  (set -x; qsub -A ExaWindFarm -t 60 -n 1 --env INDEX1=${i}:INDEX2=$(((i+${block}-1))) --mode script run_ctest.sh)
done
