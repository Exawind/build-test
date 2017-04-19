#!/bin/bash -l

#PBS -N test_nalu_peregrine
#PBS -l nodes=1:ppn=24,walltime=4:00:00
#PBS -A windFlowModeling
#PBS -q short
#PBS -j oe
#PBS -W umask=002

#Script for running regression tests on Peregrine using Spack and submitting results to CDash

#Set nightly directory and Nalu checkout directory
NALU_TESTING_DIR=/scratch/${USER}/TestNalu
NALU_DIR=${NALU_TESTING_DIR}/Nalu

#Load Spack
export SPACK_ROOT=${NALU_TESTING_DIR}/spack
. ${SPACK_ROOT}/share/spack/setup-env.sh

#Test Nalu for trilinos master, develop
for TRILINOS_BRANCH in master #develop
do
  #Test Nalu for intel, gcc
  for COMPILER_NAME in gcc intel
  do
    #Change to build directory
    cd ${NALU_DIR}/build
    {
    module purge
    module load gcc/5.2.0
    module load python/2.7.8
    } &> /dev/null
    printf "\n\nUninstalling Nalu and Trilinos...\n\n"
    spack uninstall -y nalu %${COMPILER_NAME} ^nalu-trilinos@${TRILINOS_BRANCH}
    spack uninstall -y nalu-trilinos@${TRILINOS_BRANCH} %${COMPILER_NAME}
    printf "\n\nInstalling Nalu and Trilinos...\n\n"
    if [ ${COMPILER_NAME} == 'gcc' ]; then
      spack install binutils %${COMPILER_NAME}
      . ${SPACK_ROOT}/share/spack/setup-env.sh
      spack load binutils %${COMPILER_NAME}
      spack install nalu %${COMPILER_NAME} ^nalu-trilinos@${TRILINOS_BRANCH} ^openmpi+verbs+psm+tm+mxm@1.10.3 ^boost@1.60.0 ^hdf5@1.8.16 ^parallel-netcdf@1.6.1 ^netcdf@4.3.3.1
    elif [ ${COMPILER_NAME} == 'intel' ]; then
      export TMPDIR=/scratch/${USER}/.tmp
      spack install nalu %${COMPILER_NAME} ^nalu-trilinos@${TRILINOS_BRANCH} ^openmpi+verbs+psm+tm@1.10.3 ^boost@1.60.0 ^hdf5@1.8.16 ^parallel-netcdf@1.6.1 ^netcdf@4.3.3.1 ^m4@1.4.17
      module load compiler/intel/16.0.2
      unset TMPDIR
    fi
    spack load cmake %${COMPILER_NAME}
    spack load openmpi %${COMPILER_NAME}
    TRILINOS_DIR=`spack location -i nalu-trilinos@${TRILINOS_BRANCH} %${COMPILER_NAME}`
    YAML_DIR=`spack location -i yaml-cpp %${COMPILER_NAME}`
    rm -r ${NALU_DIR}/build/*
    printf "\n\nRunning CTest...\n\n"
    ctest \
      -DNIGHTLY_DIR=${NALU_TESTING_DIR} \
      -DYAML_DIR=${YAML_DIR} \
      -DTRILINOS_DIR=${TRILINOS_DIR} \
      -DCOMPILER_NAME=${COMPILER_NAME} \
      -DTRILINOS_BRANCH=${TRILINOS_BRANCH} \
      -VV -S ${NALU_DIR}/reg_tests/CTestNightlyScript.cmake
    printf "\n\nReturned from CTest...\n\n"
    spack unload cmake %${COMPILER_NAME}
    spack unload openmpi %${COMPILER_NAME}
    if [ ${COMPILER_NAME} == 'gcc' ]; then
      spack unload binutils %${COMPILER_NAME}
    fi 
  done
done
