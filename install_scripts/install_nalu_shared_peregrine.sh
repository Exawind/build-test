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
ROOT_DIR=/projects/windFlowModeling/ExaWind/NaluSharedInstallationB

# Set spack location
export SPACK_ROOT=${ROOT_DIR}/spack

# Create and set up the entire root directory if it doesn't exist
if [ ! -d "${ROOT_DIR}" ]; then
  (set -x; mkdir -p ${ROOT_DIR})

  printf "\n\nCloning Spack repo...\n\n"
  (set -x; git clone https://github.com/LLNL/spack.git ${SPACK_ROOT})

  printf "\n\nConfiguring Spack for Peregrine...\n\n"
  (set -x; cd ${ROOT_DIR} && git clone https://github.com/NaluCFD/NaluSpack.git)
  (set -x; cd ${ROOT_DIR}/NaluSpack/spack_config && ./copy_config.sh)
fi

# Load Spack
. ${SPACK_ROOT}/share/spack/setup-env.sh

# Define TRILINOS and GENERAL_CONSTRAINTS from a single location for all scripts
printf "\n\nConstructing Spack constraints...\n\n"
source ${ROOT_DIR}/NaluSpack/spack_config/general_preferred_nalu_constraints.sh
MACHINE_SPECIFIC_CONSTRAINTS="^openmpi@1.10.3 fabrics=verbs,mxm schedulers=tm ^cmake@3.6.1 ^m4@1.4.17"
ALL_CONSTRAINTS="${MACHINE_SPECIFIC_CONSTRAINTS} ${GENERAL_CONSTRAINTS}"

# Install Nalu for trilinos develop
for TRILINOS_BRANCH in develop
do
  # Install Nalu for intel, gcc
  for COMPILER_NAME in gcc intel
  do
    printf "\n\nInstalling Nalu with ${COMPILER_NAME} and Trilinos ${TRILINOS_BRANCH}.\n\n"

    # Change to Nalu testing directory
    (set -x; cd ${ROOT_DIR})

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
    (set -x; spack uninstall -y nalu %${COMPILER_NAME} ^${TRILINOS}@${TRILINOS_BRANCH} ${ALL_CONSTRAINTS})
    (set -x; spack uninstall -y ${TRILINOS}@${TRILINOS_BRANCH} %${COMPILER_NAME} ${ALL_CONSTRAINTS})
    set -e

    if [ ${COMPILER_NAME} == 'gcc' ]; then
      # Fix for Peregrine's broken linker for gcc
      printf "\n\nInstalling binutils...\n\n"
      (set -x; spack install binutils %${COMPILER_NAME})
      . ${SPACK_ROOT}/share/spack/setup-env.sh
      printf "\n\nLoading binutils...\n\n"
      spack load binutils %${COMPILER_NAME}
    elif [ ${COMPILER_NAME} == 'intel' ]; then
      printf "\n\nChanging TMPDIR to disk for Intel compiler...\n\n"
      (set -x; mkdir -p /scratch/${USER}/.tmp)
      export TMPDIR=/scratch/${USER}/.tmp
    fi

    # Install Nalu and Trilinos
    printf "\n\nInstalling Nalu using ${COMPILER_NAME}...\n\n"
    (set -x; spack install nalu %${COMPILER_NAME} ^${TRILINOS}@${TRILINOS_BRANCH} ${ALL_CONSTRAINTS})
    (set -x; spack install netcdf-fortran@4.4.3 %${COMPILER_NAME} ^/$(spack find -L netcdf %${COMPILER_NAME} | grep netcdf | awk -F" " '{print $1}' | sed -r "s/\x1B\[([0-9]{1,2}(;[0-9]{1,2})?)?[mGK]//g") ^m4@1.4.17)

    # Remove spack built cmake and openmpi from path
    printf "\n\nUnloading Spack modules from environment...\n\n"
    if [ ${COMPILER_NAME} == 'gcc' ]; then
      spack unload binutils %${COMPILER_NAME}
    fi 

    printf "\n\nDone installing Nalu with ${COMPILER_NAME} and Trilinos ${TRILINOS_BRANCH}.\n\n"
  done
done

printf "\n\nSetting permissions...\n\n"
(set -x; chmod -R a+rX,go-w ${ROOT_DIR})
(set -x; chmod g+w ${ROOT_DIR})
(set -x; chmod g+w ${ROOT_DIR}/spack)
(set -x; chmod g+w ${ROOT_DIR}/spack/opt)
(set -x; chmod g+w ${ROOT_DIR}/spack/opt/spack)
(set -x; chmod -R g+w ${ROOT_DIR}/spack/opt/spack/.spack-db)
printf "\n\nDone!\n\n"
