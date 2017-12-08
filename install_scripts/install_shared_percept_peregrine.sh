#!/bin/bash -l

#PBS -N install_shared_percept_peregrine
#PBS -l nodes=1:ppn=24,walltime=4:00:00,feature=haswell
#PBS -A windsim
#PBS -q short
#PBS -j oe
#PBS -W umask=002

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
INSTALL_DIR=/projects/windsim/exawind/percept
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
  cmd "git clone https://github.com/jrood-nrel/spack.git ${SPACK_ROOT}"
  cmd "cd ${SPACK_ROOT} && git checkout add_percept"

  printf "\nConfiguring Spack...\n"
  cmd "git clone https://github.com/NaluCFD/NaluSpack.git ${NALUSPACK_DIR}"
  cmd "cd ${NALUSPACK_DIR}/spack_config && ./setup_spack.sh"

  printf "============================================================\n"
  printf "Done setting up install directory.\n"
  printf "============================================================\n"
fi

printf "\nLoading Spack...\n"
cmd "source ${SPACK_ROOT}/share/spack/setup-env.sh"

for TRILINOS_BRANCH in 12.12.1
do
  for COMPILER_NAME in gcc
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
      # Fix for Peregrine's broken linker for gcc
      printf "\nInstalling binutils...\n"
      cmd "spack install binutils %${COMPILER_NAME}@${COMPILER_VERSION}"
      printf "\nReloading Spack...\n"
      cmd "source ${SPACK_ROOT}/share/spack/setup-env.sh"
      printf "\nLoading binutils...\n"
      cmd "spack load binutils %${COMPILER_NAME}@${COMPILER_VERSION}"
    fi

    # Set the TMPDIR to disk so it doesn't run out of space
    printf "\nMaking and setting TMPDIR to disk...\n"
    cmd "mkdir -p /scratch/${USER}/.tmp"
    cmd "export TMPDIR=/scratch/${USER}/.tmp"

    printf "\nInstalling Percept using ${COMPILER_NAME}@${COMPILER_VERSION}...\n"
    if [ ${COMPILER_NAME} == 'gcc' ]; then
      cmd "spack install percept %${COMPILER_NAME}@${COMPILER_VERSION} ^${TRILINOS_PERCEPT}@${TRILINOS_BRANCH} ${GENERAL_CONSTRAINTS}"
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
