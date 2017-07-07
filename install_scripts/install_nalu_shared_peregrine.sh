#!/bin/bash -l

#PBS -N nalu_shared_build
#PBS -l nodes=1:ppn=24,walltime=4:00:00,feature=64GB
#PBS -A windFlowModeling
#PBS -q short
#PBS -j oe
#PBS -W umask=002

# Script for installing and updating a shared Nalu software stack

set -e

echo `date`
printf "\n\n"

# Set root install directory
ROOT_DIR=/projects/windFlowModeling/ExaWind/NaluSharedInstallation

# Set spack location
export SPACK_ROOT=${ROOT_DIR}/spack

# Create and set up a directory if it doesn't exist
if [ ! -d "${ROOT_DIR}" ]; then
  mkdir -p ${ROOT_DIR}

  # Create and set up directory with Spack installation
  printf "\n\nCloning Spack repo...\n\n"
  git clone https://github.com/LLNL/spack.git ${SPACK_ROOT}

  # Configure Spack for Peregrine
  printf "\n\nConfiguring Spack...\n\n"
  cd ${ROOT_DIR} && git clone https://github.com/NaluCFD/NaluSpack.git
  cd ${ROOT_DIR}/NaluSpack/spack_config
  ./copy_config.sh
fi

# Load Spack
. ${SPACK_ROOT}/share/spack/setup-env.sh

# Define TRILINOS and TPLS from a single location for all scripts
source ${ROOT_DIR}/NaluSpack/spack_config/tpls.sh
TPLS="${TPLS} ^cmake@3.6.1 ^m4@1.4.17"

# Install Nalu for trilinos develop
for TRILINOS_BRANCH in develop
do
  # Install Nalu for intel, gcc
  for COMPILER_NAME in gcc intel
  do
    printf "\n\nInstalling Nalu with ${COMPILER_NAME} and Trilinos ${TRILINOS_BRANCH}.\n\n"

    # Change to Nalu testing directory
    cd ${ROOT_DIR}

    # Load necessary modules
    printf "\n\nLoading modules...\n\n"
    {
    module purge
    module load gcc/5.2.0
    module load python/2.7.8
    } &> /dev/null
 
    # Uninstall Nalu and Trilinos; it's an error if they don't exist yet, but we skip it
    printf "\n\nUninstalling Nalu and Trilinos...\n\n"
    set +e
    spack uninstall -y nalu %${COMPILER_NAME} ^${TRILINOS}@${TRILINOS_BRANCH} ${TPLS}
    spack uninstall -y ${TRILINOS}@${TRILINOS_BRANCH} %${COMPILER_NAME} ${TPLS}
    set -e

    if [ ${COMPILER_NAME} == 'gcc' ]; then
      # Fix for Peregrine's broken linker for gcc
      printf "\n\nInstalling binutils...\n\n"
      spack install binutils %${COMPILER_NAME}
      . ${SPACK_ROOT}/share/spack/setup-env.sh
      spack load binutils %${COMPILER_NAME}
    elif [ ${COMPILER_NAME} == 'intel' ]; then
      # Fix for Intel compiler failing when building trilinos with tmpdir set as a RAM disk by default
      mkdir -p /scratch/${USER}/.tmp
      export TMPDIR=/scratch/${USER}/.tmp
    fi

    # Install Nalu and Trilinos
    printf "\n\nInstalling Nalu using ${COMPILER_NAME}...\n\n"
    spack install nalu %${COMPILER_NAME} ^${TRILINOS}@${TRILINOS_BRANCH} ${TPLS}
    spack install netcdf-fortran@4.4.3 %${COMPILER_NAME} ^/$(spack find -L netcdf %${COMPILER_NAME} | grep netcdf | awk -F" " '{print $1}' | sed -r "s/\x1B\[([0-9]{1,2}(;[0-9]{1,2})?)?[mGK]//g") ^m4@1.4.17

    # Remove spack built cmake and openmpi from path
    printf "\n\nUnloading Spack modules from environment...\n\n"
    if [ ${COMPILER_NAME} == 'gcc' ]; then
      spack unload binutils %${COMPILER_NAME}
    fi 

    printf "\n\nDone installing Nalu with ${COMPILER_NAME} and Trilinos ${TRILINOS_BRANCH}.\n\n"
  done
done

printf "\n\nSetting permissions...\n\n"
chmod -R a+rX,go-w ${ROOT_DIR}
printf "\n\nDone!\n\n"
