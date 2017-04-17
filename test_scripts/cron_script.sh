#!/bin/bash -l

#Script that runs the nightly tests at NREL on Peregrine

set -e

NALU_TESTING_DIR=/scratch/${USER}/TestNalu
NALU_DIR=${NALU_TESTING_DIR}/Nalu
export SPACK_ROOT=${NALU_TESTING_DIR}/spack

#Create a test directory if it doesn't exist
if [ ! -d "${NALU_TESTING_DIR}" ]; then
  mkdir -p ${NALU_TESTING_DIR}

  #Create and set up nightly directory with Spack installation
  git clone https://github.com/LLNL/spack.git ${SPACK_ROOT}

  #Configure Spack for Peregrine
  cd ${NALU_TESTING_DIR} && git clone https://github.com/NaluCFD/NaluSpack.git
  cd ${NALU_TESTING_DIR}/NaluSpack/spack_config
  ./copy_config.sh

  #Checkout Nalu and meshes submodule outside of Spack so ctest can build it itself
  git clone --recursive https://github.com/NaluCFD/Nalu.git ${NALU_DIR}

  #Create a jobs directory
  mkdir -p ${NALU_TESTING_DIR}/jobs
fi

#Change to jobs directory and launch tests
cd ${NALU_TESTING_DIR}/jobs && qsub ${NALU_TESTING_DIR}/NaluSpack/test_scripts/test_nalu_peregrine.sh
