#!/bin/bash -l

#PBS -N install_nalu_shared_peregrine
#PBS -l nodes=1:ppn=24,walltime=6:00:00
#PBS -A windFlowModeling
#PBS -q batch-h
#PBS -j oe
#PBS -W umask=002

# Script for shared installation of Nalu on Peregrine using Spack

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

# Set some version numbers
GCC_COMPILER_VERSION="5.2.0"
INTEL_COMPILER_VERSION="17.0.2"
YAML_VERSION="develop"

# Set nightly directory and Nalu checkout directory
INSTALL_DIR=/projects/windFlowModeling/ExaWind/NaluSharedInstallationA
NALU_DIR=${INSTALL_DIR}/Nalu
NALUSPACK_DIR=${INSTALL_DIR}/NaluSpack

# Set spack location
export SPACK_ROOT=${INSTALL_DIR}/spack

# Create and set up the entire testing directory if it doesn't exist
if [ ! -d "${INSTALL_DIR}" ]; then
  printf "\n\nTop level install directory doesn't exist. Creating everything from scratch...\n\n"

  # Make top level testing directory
  printf "\n\nCreating top level install directory...\n\n"
  (set -x; mkdir -p ${INSTALL_DIR})

  # Create and set up install directory with Spack installation
  printf "\n\nCloning Spack repo...\n\n"
  (set -x; git clone https://github.com/LLNL/spack.git ${SPACK_ROOT})

  # Configure Spack for Peregrine
  printf "\n\nConfiguring Spack...\n\n"
  (set -x; cd ${INSTALL_DIR} && git clone https://github.com/NaluCFD/NaluSpack.git)
  (set -x; cd ${INSTALL_DIR}/NaluSpack/spack_config && ./copy_config.sh)
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
    if [ ${COMPILER_NAME} == 'gcc' ]; then
      COMPILER_VERSION="${GCC_COMPILER_VERSION}"
    elif [ ${COMPILER_NAME} == 'intel' ]; then
      COMPILER_VERSION="${INTEL_COMPILER_VERSION}"
    fi
    printf "\n\nInstalling Nalu with ${COMPILER_NAME}@${COMPILER_VERSION} and Trilinos ${TRILINOS_BRANCH}.\n\n"

    # Define TRILINOS and GENERAL_CONSTRAINTS from a single location for all scripts
    unset GENERAL_CONSTRAINTS
    source ${INSTALL_DIR}/NaluSpack/spack_config/general_preferred_nalu_constraints.sh
    printf "\n\nUsing constraints: ^yaml-cpp@${YAML_VERSION} ${GENERAL_CONSTRAINTS}\n\n"

    # Change to Nalu testing directory
    cd ${INSTALL_DIR}

    # Load necessary modules
    printf "\n\nLoading modules...\n\n"
    {
    module purge
    module load gcc/5.2.0
    module load python/2.7.8
    module unload mkl
    } &> /dev/null
 
    if [ ${COMPILER_NAME} == 'gcc' ]; then
      # Fix for Peregrine's broken linker for gcc
      printf "\n\nInstalling binutils...\n\n"
      (set -x; spack install binutils %${COMPILER_NAME}@${COMPILER_VERSION})
      printf "\n\nReloading Spack...\n\n"
      . ${SPACK_ROOT}/share/spack/setup-env.sh
      printf "\n\nLoading binutils...\n\n"
      spack load binutils %${COMPILER_NAME}@${COMPILER_VERSION}
    elif [ ${COMPILER_NAME} == 'intel' ]; then
      printf "\n\nSetting up rpath for Intel...\n\n"
      # For Intel compiler to include rpath to its own libraries
      for i in ICCCFG ICPCCFG IFORTCFG
      do
        export $i=${SPACK_ROOT}/etc/spack/intel.cfg
      done
    fi

    # Set the TMPDIR to disk so it doesn't run out of space
    printf "\n\nMaking and setting TMPDIR to disk...\n\n"
    mkdir -p /scratch/${USER}/.tmp
    export TMPDIR=/scratch/${USER}/.tmp

    # Install Nalu and Trilinos
    printf "\n\nInstalling Nalu using ${COMPILER_NAME}@${COMPILER_VERSION}...\n\n"
    (set -x; spack install nalu %${COMPILER_NAME}@${COMPILER_VERSION} ^yaml-cpp@${YAML_VERSION} ^${TRILINOS}@${TRILINOS_BRANCH} ${GENERAL_CONSTRAINTS})
    (set -x; spack install netcdf-fortran@4.4.3 %${COMPILER_NAME}@${COMPILER_VERSION} ^/$(spack find -L netcdf %${COMPILER_NAME}@${COMPILER_VERSION} | grep netcdf | awk -F" " '{print $1}' | sed -r "s/\x1B\[([0-9]{1,2}(;[0-9]{1,2})?)?[mGK]//g") ^m4@1.4.17)

    unset TMPDIR

    printf "\n\nDone installing Nalu with ${COMPILER_NAME}@${COMPILER_VERSION} and Trilinos ${TRILINOS_BRANCH}.\n\n"
  done
done

printf "\n\nSetting permissions...\n\n"
(set -x; chmod -R a+rX,go-w ${INSTALL_DIR})
(set -x; chmod g+w ${INSTALL_DIR})
(set -x; chmod g+w ${INSTALL_DIR}/spack)
(set -x; chmod g+w ${INSTALL_DIR}/spack/opt)
(set -x; chmod g+w ${INSTALL_DIR}/spack/opt/spack)
(set -x; chmod -R g+w ${INSTALL_DIR}/spack/opt/spack/.spack-db)
printf "\n\nDone!\n\n"
