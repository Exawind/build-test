#!/bin/bash -l

#PBS -N test_nalu_merlin
#PBS -l nodes=1:ppn=24,walltime=8:00:00
#PBS -A windFlowModeling
#PBS -q batch
#PBS -j oe
#PBS -W umask=002

# Script for running regression tests on Merlin using Spack and submitting results to CDash

echo `date`
echo ------------------------------------------------------
echo "Job is running on node ${HOSTNAME}"
echo ------------------------------------------------------
if [ ! -z "${PBS_JOBID}" ]; then
  echo PBS: Qsub is running on ${PBS_O_HOST}
  echo PBS: Originating queue is ${PBS_O_QUEUE}
  echo PBS: Executing queue is ${PBS_QUEUE}
  echo PBS: Working directory is ${PBS_O_WORKDIR}
  echo PBS: Execution mode is ${PBS_ENVIRONMENT}
  echo PBS: Job identifier is ${PBS_JOBID}
  echo PBS: Job name is ${PBS_JOBNAME}
  echo PBS: Node file is ${PBS_NODEFILE}
  echo PBS: Current home directory is ${PBS_O_HOME}
  echo PBS: PATH = ${PBS_O_PATH}
  echo ------------------------------------------------------
fi
printf "\n\n"

# Set nightly directory and Nalu checkout directory
NALU_TESTING_DIR=/nodescratch/NaluNightlyTesting
NALU_DIR=${NALU_TESTING_DIR}/Nalu
NALUSPACK_DIR=${NALU_TESTING_DIR}/NaluSpack

# Set host name to pass to CDash
HOST_NAME="merlin.hpc.nrel.gov"

# Set spack location
export SPACK_ROOT=${NALU_TESTING_DIR}/spack

# Create and set up a testing directory if it doesn't exist
if [ ! -d "${NALU_TESTING_DIR}" ]; then
  printf "\n\nTop level testing directory doesn't exist. Creating everything from scratch...\n\n"

  # Make top level testing directory
  printf "\n\nCreating top level testing directory...\n\n"
  (set -x; mkdir -p ${NALU_TESTING_DIR})

  # Create and set up nightly directory with Spack installation
  printf "\n\nCloning Spack repo...\n\n"
  (set -x; git clone https://github.com/LLNL/spack.git ${SPACK_ROOT})

  # Configure Spack for Merlin
  printf "\n\nConfiguring Spack...\n\n"
  (set -x; git clone https://github.com/NaluCFD/NaluSpack.git ${NALUSPACK_DIR})
  (set -x; cd ${NALUSPACK_DIR}/spack_config && ./copy_config.sh)

  # Checkout Nalu and meshes submodule outside of Spack so ctest can build it itself
  printf "\n\nCloning Nalu repo...\n\n"
  (set -x; git clone --recursive https://github.com/NaluCFD/Nalu.git ${NALU_DIR})
fi

# Load Spack
printf "\n\nLoading Spack...\n\n"
. ${SPACK_ROOT}/share/spack/setup-env.sh

# Test Nalu for trilinos master, develop
for TRILINOS_BRANCH in develop #master
do
  # Test Nalu for intel, gcc
  for COMPILER_NAME in gcc intel
  do
    printf "\n\nTesting Nalu with ${COMPILER_NAME} and Trilinos ${TRILINOS_BRANCH}.\n\n"

    # Define TRILINOS and GENERAL_CONSTRAINTS from a single location for all scripts
    unset GENERAL_CONSTRAINTS
    source ${NALU_TESTING_DIR}/NaluSpack/spack_config/general_preferred_nalu_constraints.sh
    MACHINE_SPECIFIC_CONSTRAINTS="^openmpi@1.10.3 fabrics=psm2 ^cmake@3.6.1 ^netlib-lapack"
    ALL_CONSTRAINTS="${GENERAL_CONSTRAINTS} ${MACHINE_SPECIFIC_CONSTRAINTS}"
    printf "\n\nUsing constraints: ${ALL_CONSTRAINTS}\n\n"

    # Change to Nalu testing directory
    cd ${NALU_TESTING_DIR}

    # Load necessary modules
    printf "\n\nLoading modules...\n\n"
    module purge
    module load GCC/4.8.5
 
    # For Intel compiler
    export TMPDIR=/dev/shm
    export INTEL_LICENSE_FILE=28518@hpc-admin1.hpc.nrel.gov
    for i in ICCCFG ICPCCFG IFORTCFG
    do
      export $i=${SPACK_ROOT}/etc/spack/intel.cfg
    done
    # End for Intel compiler

    printf "\n\nInstalling Nalu using ${COMPILER_NAME}...\n\n"
    (set -x; spack install nalu %${COMPILER_NAME} ^${TRILINOS}@${TRILINOS_BRANCH} ${ALL_CONSTRAINTS})

    # Load spack built cmake and openmpi into path
    printf "\n\nLoading Spack modules into environment...\n\n"
    # Refresh available modules (this is only really necessary on the first run of this script
    # because cmake and openmpi will already have been built and module files registered in subsequent runs)
    . ${SPACK_ROOT}/share/spack/setup-env.sh
    spack load cmake %${COMPILER_NAME}
    spack load openmpi %${COMPILER_NAME}

    # Set the Trilinos and Yaml directories to pass to ctest
    printf "\n\nSetting variables to pass to CTest...\n\n"
    TRILINOS_DIR=$(spack location -i ${TRILINOS}@${TRILINOS_BRANCH} %${COMPILER_NAME} ${ALL_CONSTRAINTS})
    YAML_DIR=$(spack location -i yaml-cpp %${COMPILER_NAME})

    # Set the extra identifiers for CDash build description
    EXTRA_BUILD_NAME="-${COMPILER_NAME}-trlns_${TRILINOS_BRANCH}"

    for RELEASE_OR_DEBUG in RELEASE DEBUG
    do
      # Make build type lowercase
      BUILD_TYPE="$(tr [A-Z] [a-z] <<< "${RELEASE_OR_DEBUG}")"

      # Clean build directory; check if NALU_DIR is blank first
      if [ ! -z "${NALU_DIR}" ]; then
        printf "\n\nCleaning build directory...\n\n"
        (set -x; rm -rf ${NALU_DIR}/build/*)
      fi

      # Run ctest
      printf "\n\nRunning CTest...\n\n"
      # Change to Nalu build directory
      cd ${NALU_DIR}/build
      (set -x; export OMP_NUM_THREADS=1; ctest \
        -DNIGHTLY_DIR=${NALU_TESTING_DIR} \
        -DYAML_DIR=${YAML_DIR} \
        -DTRILINOS_DIR=${TRILINOS_DIR} \
        -DHOST_NAME=${HOST_NAME} \
        -DRELEASE_OR_DEBUG=${RELEASE_OR_DEBUG} \
        -DEXTRA_BUILD_NAME=${EXTRA_BUILD_NAME}-${BUILD_TYPE} \
        -VV -S ${NALU_DIR}/reg_tests/CTestNightlyScript.cmake)
      printf "\n\nReturned from CTest...\n\n"
    done

    # Remove spack built cmake and openmpi from path
    printf "\n\nUnloading Spack modules from environment...\n\n"
    spack unload cmake %${COMPILER_NAME}
    spack unload openmpi %${COMPILER_NAME}

    # Clean TMPDIR before exiting
    if [ ! -z "${TMPDIR}" ]; then
      printf "\n\nCleaning TMPDIR directory...\n\n"
      (set -x; rm -rf ${TMPDIR}/*)
      unset TMPDIR
    fi

    # Clean nodescratch before exiting
    if [ ! -z "${NALU_TESTING_DIR}" ]; then
      printf "\n\nCleaning NALU_TESTING_DIR directory...\n\n"
      (set -x; rm -rf ${NALU_TESTING_DIR})
    fi

    printf "\n\nDone testing Nalu with ${COMPILER_NAME} and Trilinos ${TRILINOS_BRANCH}.\n\n"
  done
done

printf "\n\nDone!\n\n"
