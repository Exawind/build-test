#!/bin/bash -l

#PBS -N install_shared_software_peregrine
#PBS -l nodes=1:ppn=24,walltime=14:00:00
#PBS -A windsim
#PBS -q batch-h
#PBS -j oe
#PBS -W umask=002

# Script for shared installation of Nalu related software on Peregrine using Spack

# Control over printing and executing commands
print_cmds=true
execute_cmds=true

# Function for printing and executing commands
cmd() {
  if ${print_cmds}; then echo "+ $@"; fi
  if ${execute_cmds}; then eval "$@"; fi
}

printf "============================================================\n"
printf "$(date)\n"
printf "============================================================\n"
printf "Job is running on ${HOSTNAME}\n"
printf "============================================================\n"
if [ ! -z "${PBS_JOBID}" ]; then
  printf "PBS: Qsub is running on ${PBS_O_HOST}\n"
  printf "PBS: Originating queue is ${PBS_O_QUEUE}\n"
  printf "PBS: Executing queue is ${PBS_QUEUE}\n"
  printf "PBS: Working directory is ${PBS_O_WORKDIR}\n"
  printf "PBS: Execution mode is ${PBS_ENVIRONMENT}\n"
  printf "PBS: Job identifier is ${PBS_JOBID}\n"
  printf "PBS: Job name is ${PBS_JOBNAME}\n"
  printf "PBS: Node file is ${PBS_NODEFILE}\n"
  printf "PBS: Current home directory is ${PBS_O_HOME}\n"
  printf "PBS: PATH = ${PBS_O_PATH}\n"
  printf "============================================================\n"
fi

# Set some version numbers
GCC_COMPILER_VERSION="5.2.0"
INTEL_COMPILER_VERSION="17.0.2"

# Set installation directory
INSTALL_DIR=/projects/windsim/exawind/SharedSoftwareB
NALU_DIR=${INSTALL_DIR}/Nalu
NALUSPACK_DIR=${INSTALL_DIR}/NaluSpack

# Set spack location
export SPACK_ROOT=${INSTALL_DIR}/spack

if [ ! -d "${INSTALL_DIR}" ]; then
  printf "============================================================\n"
  printf "Install directory doesn't exist.\n"
  printf "Creating everything from scratch...\n"
  printf "============================================================\n"

  printf "Creating top level install directory...\n"
  cmd "mkdir -p ${INSTALL_DIR}"

  printf "\nCloning Spack repo...\n"
  cmd "git clone https://github.com/spack/spack.git ${SPACK_ROOT}"

  printf "\nConfiguring Spack...\n"
  cmd "git clone https://github.com/NaluCFD/NaluSpack.git ${NALUSPACK_DIR}"
  cmd "cd ${NALUSPACK_DIR}/spack_config && ./setup_spack.sh"

  printf "============================================================\n"
  printf "Done setting up install directory.\n"
  printf "============================================================\n"
fi

printf "\nLoading Spack...\n"
cmd "source ${SPACK_ROOT}/share/spack/setup-env.sh"

for TRILINOS_BRANCH in develop
do
  for COMPILER_NAME in gcc intel
  do
    if [ ${COMPILER_NAME} == 'gcc' ]; then
      COMPILER_VERSION="${GCC_COMPILER_VERSION}"
    elif [ ${COMPILER_NAME} == 'intel' ]; then
      COMPILER_VERSION="${INTEL_COMPILER_VERSION}"
    fi
    printf "\nInstalling software with ${COMPILER_NAME}@${COMPILER_VERSION} at $(date).\n"

    # Define TRILINOS and GENERAL_CONSTRAINTS from a single location for all scripts
    unset GENERAL_CONSTRAINTS
    cmd "source ${INSTALL_DIR}/NaluSpack/spack_config/shared_constraints.sh"
    printf "\nUsing constraints: ${GENERAL_CONSTRAINTS}\n"

    # Change to Nalu testing directory
    cd ${INSTALL_DIR}

    # Load necessary modules
    printf "\nLoading modules...\n"
    cmd "module purge"
    cmd "module load gcc/5.2.0"
    cmd "module load python/2.7.8 &> /dev/null"
    cmd "module unload mkl"
 
    if [ ${COMPILER_NAME} == 'gcc' ]; then
      # Fix for Peregrine's broken linker for gcc
      printf "\nInstalling binutils...\n"
      cmd "spack install binutils %${COMPILER_NAME}@${COMPILER_VERSION}"
      printf "\nReloading Spack...\n"
      cmd "source ${SPACK_ROOT}/share/spack/setup-env.sh"
      printf "\nLoading binutils...\n"
      cmd "spack load binutils %${COMPILER_NAME}@${COMPILER_VERSION}"
    elif [ ${COMPILER_NAME} == 'intel' ]; then
      printf "\nSetting up rpath for Intel...\n"
      # For Intel compiler to include rpath to its own libraries
      for i in ICCCFG ICPCCFG IFORTCFG
      do
        cmd "export $i=${SPACK_ROOT}/etc/spack/intel.cfg"
      done
    fi

    # Set the TMPDIR to disk so it doesn't run out of space
    printf "\nMaking and setting TMPDIR to disk...\n"
    cmd "mkdir -p /scratch/${USER}/.tmp"
    cmd "export TMPDIR=/scratch/${USER}/.tmp"

    # Install and load our own python for glib because it doesn't like the system python
    printf "\nInstalling Python using ${COMPILER_NAME}@${COMPILER_VERSION}...\n"
    cmd "spack install python %${COMPILER_NAME}@${COMPILER_VERSION}"
    cmd "module unload python/2.7.8"
    cmd "unset PYTHONHOME"
    cmd "spack load python ${COMPILER_NAME}@${COMPILER_VERSION}"

    printf "\nInstalling Nalu using ${COMPILER_NAME}@${COMPILER_VERSION}...\n"
    if [ ${COMPILER_NAME} == 'gcc' ]; then
      cmd "spack install nalu %${COMPILER_NAME}@${COMPILER_VERSION} ^${TRILINOS}@${TRILINOS_BRANCH} ${GENERAL_CONSTRAINTS}"
      cmd "spack install nalu %${COMPILER_NAME}@${COMPILER_VERSION} build_type=Debug ^${TRILINOS}@${TRILINOS_BRANCH} build_type=Debug ${GENERAL_CONSTRAINTS}"
    elif [ ${COMPILER_NAME} == 'intel' ]; then
      cmd "spack install nalu %${COMPILER_NAME}@${COMPILER_VERSION} ^${TRILINOS}@${TRILINOS_BRANCH} ^intel-mpi ^intel-mkl ${GENERAL_CONSTRAINTS}"
      cmd "spack install nalu %${COMPILER_NAME}@${COMPILER_VERSION} build_type=Debug ^${TRILINOS}@${TRILINOS_BRANCH} build_type=Debug ^intel-mpi ^intel-mkl ${GENERAL_CONSTRAINTS}"
    fi

    printf "\nInstalling NetCDF Fortran using ${COMPILER_NAME}@${COMPILER_VERSION}...\n"
    (set -x; spack install netcdf-fortran@4.4.3 %${COMPILER_NAME}@${COMPILER_VERSION} ^/$(spack find -L netcdf %${COMPILER_NAME}@${COMPILER_VERSION} | grep netcdf | awk -F" " '{print $1}' | sed -r "s/\x1B\[([0-9]{1,2}(;[0-9]{1,2})?)?[mGK]//g"))

    printf "\nInstalling hypre using ${COMPILER_NAME}@${COMPILER_VERSION}...\n"
    cmd "spack install hypre %${COMPILER_NAME}@${COMPILER_VERSION}"

    if [ ${COMPILER_NAME} == 'gcc' ]; then
      printf "\nInstalling Paraview using ${COMPILER_NAME}@${COMPILER_VERSION}...\n"
      cmd "spack install paraview+mpi+python+osmesa@5.4.1 %${COMPILER_NAME}@${COMPILER_VERSION}"
    fi

    cmd "unset TMPDIR"

    printf "\nDone installing shared software with ${COMPILER_NAME}@${COMPILER_VERSION} at $(date).\n"
  done
done

printf "\nSetting permissions...\n"
cmd "chmod -R a+rX,go-w ${INSTALL_DIR}"
cmd "chmod g+w ${INSTALL_DIR}"
cmd "chmod g+w ${INSTALL_DIR}/spack"
cmd "chmod g+w ${INSTALL_DIR}/spack/opt"
cmd "chmod g+w ${INSTALL_DIR}/spack/opt/spack"
cmd "chmod -R g+w ${INSTALL_DIR}/spack/opt/spack/.spack-db"
printf "\n$(date)\n"
printf "\nDone!\n"
