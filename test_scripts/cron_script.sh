#!/bin/bash -l

#Script that runs the nightly tests at NREL on Peregrine

set -e

NALU_TESTING_DIR=/scratch/${USER}/TestNalu

#Create a test directory if it doesn't exist
if [ ! -d "${NALU_TESTING_DIR}" ]; then
  mkdir -p ${NALU_TESTING_DIR}
fi

#Create a jobs directory if it doesn't exist
if [ ! -d "${NALU_TESTING_DIR}/jobs" ]; then
  mkdir -p ${NALU_TESTING_DIR}/jobs
fi

#Create or update NaluSpack directory
if [ ! -d "${NALU_TESTING_DIR}/NaluSpack" ]; then
  cd ${NALU_TESTING_DIR} && git clone https://github.com/NaluCFD/NaluSpack.git
else
  cd ${NALU_TESTING_DIR}/NaluSpack && git pull
fi

cd ${NALU_TESTING_DIR}/jobs && qsub ${NALU_TESTING_DIR}/NaluSpack/test_scripts/test_nalu_peregrine.sh
