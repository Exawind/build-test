#!/bin/bash -l

#PBS -N test_nalu_peregrine
#PBS -l nodes=1:ppn=24,walltime=4:00:00
#PBS -A windFlowModeling
#PBS -q short
#PBS -j oe
#PBS -W umask=002

# Script for running regression tests on Peregrine using Spack and submitting results to CDash

# Set nightly directory and Nalu checkout directory
NALU_TESTING_DIR=/scratch/jrood/TestNalu
NALU_DIR=${NALU_TESTING_DIR}/Nalu

# Set spack location
export SPACK_ROOT=${NALU_TESTING_DIR}/spack

# Uncomment this if statement to create and set up
# a testing directory if it doesn't exist
#if [ ! -d "${NALU_TESTING_DIR}" ]; then
#  mkdir -p ${NALU_TESTING_DIR}
#
#  # Create and set up nightly directory with Spack installation
#  printf "\n\nCloning Spack repo...\n\n"
#  git clone https://github.com/LLNL/spack.git ${SPACK_ROOT}
#
#  # Configure Spack for Peregrine
#  printf "\n\nConfiguring Spack...\n\n"
#  cd ${NALU_TESTING_DIR} && git clone https://github.com/NaluCFD/NaluSpack.git
#  cd ${NALU_TESTING_DIR}/NaluSpack/spack_config
#  ./copy_config.sh
#
#  # Checkout Nalu and meshes submodule outside of Spack so ctest can build it itself
#  printf "\n\nCloning Nalu repo...\n\n"
#  git clone --recursive https://github.com/NaluCFD/Nalu.git ${NALU_DIR}
#
#  # Create a jobs directory
#  printf "\n\nMaking job output directory...\n\n"
#  mkdir -p ${NALU_TESTING_DIR}/jobs
#fi

# Load Spack
. ${SPACK_ROOT}/share/spack/setup-env.sh

# Test Nalu for trilinos master, develop
for TRILINOS_BRANCH in master #develop
do
  # Test Nalu for intel, gcc
  for COMPILER_NAME in gcc intel
  do
    # Load necessary modules
    printf "\n\nLoading modules...\n\n"
    {
    module purge
    module load gcc/5.2.0
    module load python/2.7.8
    } &> /dev/null
 
    # Uninstall Nalu and Trilinos; it's an error if they don't exist yet, but we skip it
    printf "\n\nUninstalling Nalu and Trilinos...\n\n"
    spack uninstall -y nalu %${COMPILER_NAME} ^nalu-trilinos@${TRILINOS_BRANCH}
    spack uninstall -y nalu-trilinos@${TRILINOS_BRANCH} %${COMPILER_NAME}

    # Change to Nalu build directory
    cd ${NALU_DIR}/build

    # Update and install Nalu and Trilinos
    if [ ${COMPILER_NAME} == 'gcc' ]; then
      # Fix for Peregrine's broken linker
      spack install binutils %${COMPILER_NAME}
      . ${SPACK_ROOT}/share/spack/setup-env.sh
      spack load binutils %${COMPILER_NAME}

      printf "\n\nPulling Nalu and Trilinos updates...\n\n"
      spack cd nalu %${COMPILER_NAME} ^nalu-trilinos@${TRILINOS_BRANCH} ^openmpi+verbs+psm+tm+mxm@1.10.3 ^boost@1.60.0 ^hdf5@1.8.16 ^parallel-netcdf@1.6.1 ^netcdf@4.3.3.1 && pwd && git pull
      spack cd nalu-trilinos@${TRILINOS_BRANCH} %${COMPILER_NAME} ^openmpi+verbs+psm+tm+mxm@1.10.3 ^boost@1.60.0 ^hdf5@1.8.16 ^parallel-netcdf@1.6.1 ^netcdf@4.3.3.1 && pwd && git pull

      printf "\n\nInstalling Nalu using ${COMPILER_NAME}...\n\n"
      spack install --keep-stage nalu %${COMPILER_NAME} ^nalu-trilinos@${TRILINOS_BRANCH} ^openmpi+verbs+psm+tm+mxm@1.10.3 ^boost@1.60.0 ^hdf5@1.8.16 ^parallel-netcdf@1.6.1 ^netcdf@4.3.3.1
    elif [ ${COMPILER_NAME} == 'intel' ]; then
      # Fix for Intel compiler failing when building trilinos with tmpdir set as a RAM disk by default
      export TMPDIR=/scratch/${USER}/.tmp

      printf "\n\nPulling Nalu and Trilinos updates...\n\n"
      spack cd nalu %${COMPILER_NAME} ^nalu-trilinos@${TRILINOS_BRANCH} ^openmpi+verbs+psm+tm@1.10.3 ^boost@1.60.0 ^hdf5@1.8.16 ^parallel-netcdf@1.6.1 ^netcdf@4.3.3.1 ^m4@1.4.17 && pwd && git pull
      spack cd nalu-trilinos@${TRILINOS_BRANCH} %${COMPILER_NAME} ^openmpi+verbs+psm+tm@1.10.3 ^boost@1.60.0 ^hdf5@1.8.16 ^parallel-netcdf@1.6.1 ^netcdf@4.3.3.1 ^m4@1.4.17 && pwd && git pull

      printf "\n\nInstalling Nalu using ${COMPILER_NAME}...\n\n"
      spack install --keep-stage nalu %${COMPILER_NAME} ^nalu-trilinos@${TRILINOS_BRANCH} ^openmpi+verbs+psm+tm@1.10.3 ^boost@1.60.0 ^hdf5@1.8.16 ^parallel-netcdf@1.6.1 ^netcdf@4.3.3.1 ^m4@1.4.17
      module load compiler/intel/16.0.2
      unset TMPDIR
    fi

    # Load spack built cmake and openmpi into path
    printf "\n\nLoading Spack modules into environment...\n\n"
    spack load cmake %${COMPILER_NAME}
    spack load openmpi %${COMPILER_NAME}

    # Set the Trilinos and Yaml directories to pass to ctest
    printf "\n\nSetting variables to pass to CTest...\n\n"
    TRILINOS_DIR=`spack location -i nalu-trilinos@${TRILINOS_BRANCH} %${COMPILER_NAME}`
    YAML_DIR=`spack location -i yaml-cpp %${COMPILER_NAME}`

    # Set the hostname and extra identifiers for CDash build description
    HOST_NAME="peregrine.hpc.nrel.gov"
    EXTRA_BUILD_NAME="-${COMPILER_NAME}-trlns_${TRILINOS_BRANCH}"

    # Clean build directory; checkout if NALU_DIR is not blank first
    printf "\n\nCleaning build directory...\n\n"
    if [ ! -z "${NALU_DIR}" ]; then
      rm -rf ${NALU_DIR}/build/*
    fi

    # Run ctest
    printf "\n\nRunning CTest...\n\n"
    ctest \
      -DNIGHTLY_DIR=${NALU_TESTING_DIR} \
      -DYAML_DIR=${YAML_DIR} \
      -DTRILINOS_DIR=${TRILINOS_DIR} \
      -DHOST_NAME=${HOST_NAME} \
      -DEXTRA_BUILD_NAME=${EXTRA_BUILD_NAME} \
      -VV -S ${NALU_DIR}/reg_tests/CTestNightlyScript.cmake
    printf "\n\nReturned from CTest...\n\n"

    # Remove spack built cmake and openmpi from path
    printf "\n\nUnloading Spack modules from environment...\n\n"
    spack unload cmake %${COMPILER_NAME}
    spack unload openmpi %${COMPILER_NAME}
    if [ ${COMPILER_NAME} == 'gcc' ]; then
      spack unload binutils %${COMPILER_NAME}
    fi 
  done
done

