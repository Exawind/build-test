#!/bin/bash -l

#PBS -N test_nalu_merlin
#PBS -l nodes=1:ppn=24,walltime=4:00:00
#PBS -A windFlowModeling
#PBS -q short
#PBS -j oe
#PBS -W umask=002

#Script for running regression tests on Merlin using Spack and submitting results to CDash

#Set nightly directory and Nalu checkout directory
NALU_TESTING_DIR=/scratch/jrood/TestNalu
NALU_DIR=${NALU_TESTING_DIR}/Nalu

#Set spack location
export SPACK_ROOT=${NALU_TESTING_DIR}/spack

#Create a test directory if it doesn't exist
#if [ ! -d "${NALU_TESTING_DIR}" ]; then
#  mkdir -p ${NALU_TESTING_DIR}
#
#  #Create and set up nightly directory with Spack installation
#  git clone https://github.com/LLNL/spack.git ${SPACK_ROOT}
#
#  #Configure Spack for Merlin
#  cd ${NALU_TESTING_DIR} && git clone https://github.com/NaluCFD/NaluSpack.git
#  cd ${NALU_TESTING_DIR}/NaluSpack/spack_config
#  ./copy_config.sh
#
#  #Checkout Nalu and meshes submodule outside of Spack so ctest can build it itself
#  git clone --recursive https://github.com/NaluCFD/Nalu.git ${NALU_DIR}
#
#  #Create a jobs directory
#  mkdir -p ${NALU_TESTING_DIR}/jobs
#fi

#Load Spack
. ${SPACK_ROOT}/share/spack/setup-env.sh

# Make sure compilers are already loaded into Spack (this searches for all compilers in your path)
spack compilers &> /dev/null

#Test Nalu for trilinos master, develop
for TRILINOS_BRANCH in master #develop
do
  #Test Nalu for intel, gcc
  for COMPILER_NAME in gcc intel
  do
    module purge
    module load intel/2017.02

    #Change to build directory
    cd ${NALU_DIR}/build

    # Uninstall Nalu and Trilinos; it's an error if they don't exist yet, but we skip it
    printf "\n\nUninstalling Nalu and Trilinos...\n\n"
    spack uninstall -y nalu %${COMPILER_NAME} ^nalu-trilinos@${TRILINOS_BRANCH}
    spack uninstall -y nalu-trilinos@${TRILINOS_BRANCH} %${COMPILER_NAME}

    # Install Nalu and Trilinos
    printf "\n\nInstalling Nalu and Trilinos...\n\n"
    if [ ${COMPILER_NAME} == 'gcc' ]; then
      spack install nalu %${COMPILER_NAME} ^nalu-trilinos@${TRILINOS_BRANCH} ^openmpi+verbs+psm+tm+mxm@1.10.3 ^boost@1.60.0 ^hdf5@1.8.16 ^parallel-netcdf@1.6.1 ^netcdf@4.3.3.1
    elif [ ${COMPILER_NAME} == 'intel' ]; then
      spack install nalu %${COMPILER_NAME} ^nalu-trilinos@${TRILINOS_BRANCH} ^openmpi+verbs+psm+tm@1.10.3 ^boost@1.60.0 ^hdf5@1.8.16 ^parallel-netcdf@1.6.1 ^netcdf@4.3.3.1 ^m4@1.4.17
    fi

    # Load spack built cmake and openmpi into path
    spack load cmake %${COMPILER_NAME}
    spack load openmpi %${COMPILER_NAME}

    # Set the Trilinos and Yaml directories to pass to ctest
    TRILINOS_DIR=`spack location -i nalu-trilinos@${TRILINOS_BRANCH} %${COMPILER_NAME}`
    YAML_DIR=`spack location -i yaml-cpp %${COMPILER_NAME}`

    # Clean the ctest build directory
    rm -r ${NALU_DIR}/build/*

    # Run ctest
    printf "\n\nRunning CTest...\n\n"
    ctest \
      -DNIGHTLY_DIR=${NALU_TESTING_DIR} \
      -DYAML_DIR=${YAML_DIR} \
      -DTRILINOS_DIR=${TRILINOS_DIR} \
      -DCOMPILER_NAME=${COMPILER_NAME} \
      -DTRILINOS_BRANCH=${TRILINOS_BRANCH} \
      -VV -S ${NALU_DIR}/reg_tests/CTestNightlyScript.cmake

    # Remove spack built cmake and openmpi from path
    printf "\n\nReturned from CTest...\n\n"
    spack unload cmake %${COMPILER_NAME}
    spack unload openmpi %${COMPILER_NAME}
  done
done

