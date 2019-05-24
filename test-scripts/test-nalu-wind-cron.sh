#!/bin/bash -l

#Script that runs the nightly Nalu-Wind test script at NREL on multiple machines

set -e

# Decide what machine we are on
if [ "${NREL_CLUSTER}" == 'eagle' ]; then
  MACHINE_NAME=eagle
elif [ $(hostname) == 'jrood-31712s.nrel.gov' ]; then
  MACHINE_NAME=mac
elif [ $(hostname) == 'rhodes.hpc.nrel.gov' ]; then
  MACHINE_NAME=rhodes
fi
  
# Set root testing directory
if [ "${MACHINE_NAME}" == 'eagle' ]; then
  NALU_WIND_TESTING_ROOT_DIR=/projects/hfm/exawind/nalu-wind-testing
elif [ "${MACHINE_NAME}" == 'mac' ]; then
  NALU_WIND_TESTING_ROOT_DIR=${HOME}/nalu-wind-testing
elif [ "${MACHINE_NAME}" == 'rhodes' ]; then
  NALU_WIND_TESTING_ROOT_DIR=/projects/ecp/exawind/nalu-wind-testing
fi

LOG_DIR=${NALU_WIND_TESTING_ROOT_DIR}/logs
TEST_SCRIPT=${NALU_WIND_TESTING_ROOT_DIR}/build-test/test-scripts/test-nalu-wind.sh
 
if [ "${MACHINE_NAME}" == 'eagle' ]; then
  cd ${LOG_DIR} && sbatch -J test-nalu-wind -N 1 -t 4:00:00 -A hfm -p standard -o "%x.o%j" --gres=gpu:1 ${TEST_SCRIPT}
elif [ "${MACHINE_NAME}" == 'rhodes' ] || [ "${MACHINE_NAME}" == 'mac' ]; then
  cd ${LOG_DIR} && nice -n19 ionice -c3 ${TEST_SCRIPT} &> "test-nalu-wind-$(date +%Y-%m-%d).log"
fi
