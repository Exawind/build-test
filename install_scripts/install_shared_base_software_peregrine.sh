#!/bin/bash -l

#PBS -N install_shared_base_software_peregrine
#PBS -l nodes=1:ppn=24,walltime=4:00:00,feature=haswell
#PBS -A windsim
#PBS -q short
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

# Set installation directory
INSTALL_DIR=/projects/windsim/exawind/SharedBaseSoftwareA
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

for COMPILER_NAME in gcc
do
  if [ ${COMPILER_NAME} == 'gcc' ]; then
    COMPILER_VERSION="${GCC_COMPILER_VERSION}"
  fi
  printf "\nInstalling base software with ${COMPILER_NAME}@${COMPILER_VERSION} at $(date).\n"

  # Load necessary modules
  printf "\nLoading modules...\n"
  cmd "module purge"
  cmd "module load gcc/5.2.0"
  cmd "module load python/2.7.8 &> /dev/null"
  cmd "module unload mkl"

  # Set the TMPDIR to disk so it doesn't run out of space
  printf "\nMaking and setting TMPDIR to disk...\n"
  cmd "mkdir -p /scratch/${USER}/.tmp"
  cmd "export TMPDIR=/scratch/${USER}/.tmp"

  # Fix for Peregrine's broken linker for gcc
  printf "\nInstalling binutils...\n"
  cmd "spack install binutils %${COMPILER_NAME}@${COMPILER_VERSION}"
  printf "\nReloading Spack...\n"
  cmd "source ${SPACK_ROOT}/share/spack/setup-env.sh"
  printf "\nLoading binutils...\n"
  cmd "spack load binutils %${COMPILER_NAME}@${COMPILER_VERSION}"

  # Install our own python
  printf "\nInstalling Python using ${COMPILER_NAME}@${COMPILER_VERSION}...\n"
  cmd "spack install python@2.7.14 %${COMPILER_NAME}@${COMPILER_VERSION}"
  cmd "spack install python@3.6.3 %${COMPILER_NAME}@${COMPILER_VERSION}"
  cmd "module unload python/2.7.8"
  cmd "unset PYTHONHOME"
  cmd "spack load python@2.7.14 ${COMPILER_NAME}@${COMPILER_VERSION}"
  cmd "spack install py-numpy ^python@2.7.14 %${COMPILER_NAME}@${COMPILER_VERSION}"
  cmd "spack install py-matplotlib ^python@2.7.14 %${COMPILER_NAME}@${COMPILER_VERSION}"
  cmd "spack install py-pandas ^python@2.7.14 %${COMPILER_NAME}@${COMPILER_VERSION}"
  cmd "spack install py-scipy ^python@2.7.14 %${COMPILER_NAME}@${COMPILER_VERSION}"
  cmd "spack install py-nose ^python@2.7.14 %${COMPILER_NAME}@${COMPILER_VERSION}"
  cmd "spack install py-numpy ^python@3.6.3 %${COMPILER_NAME}@${COMPILER_VERSION}"
  cmd "spack install py-matplotlib ^python@3.6.3 %${COMPILER_NAME}@${COMPILER_VERSION}"
  cmd "spack install py-pandas ^python@3.6.3 %${COMPILER_NAME}@${COMPILER_VERSION}"
  cmd "spack install py-scipy ^python@3.6.3 %${COMPILER_NAME}@${COMPILER_VERSION}"
  cmd "spack install py-nose ^python@3.6.3 %${COMPILER_NAME}@${COMPILER_VERSION}"

  printf "\nInstalling other tools using ${COMPILER_NAME}@${COMPILER_VERSION}...\n"
  cmd "spack install cmake %${COMPILER_NAME}@${COMPILER_VERSION}"
  cmd "spack install emacs %${COMPILER_NAME}@${COMPILER_VERSION}"
  cmd "spack install vim %${COMPILER_NAME}@${COMPILER_VERSION}"
  cmd "spack install git %${COMPILER_NAME}@${COMPILER_VERSION}"
  cmd "spack install tmux %${COMPILER_NAME}@${COMPILER_VERSION}"
  cmd "spack install screen %${COMPILER_NAME}@${COMPILER_VERSION}"
  cmd "spack install global %${COMPILER_NAME}@${COMPILER_VERSION}"
  cmd "spack install texlive scheme=full %${COMPILER_NAME}@${COMPILER_VERSION}"
  cmd "spack install gnuplot %${COMPILER_NAME}@${COMPILER_VERSION}"
  cmd "spack install htop %${COMPILER_NAME}@${COMPILER_VERSION}"
  cmd "spack install makedepend %${COMPILER_NAME}@${COMPILER_VERSION}"

  # Install our own compilers
  printf "\nInstalling compilers using ${COMPILER_NAME}@${COMPILER_VERSION}...\n"
  cmd "spack install gcc@7.2.0 %${COMPILER_NAME}@${COMPILER_VERSION}"
  cmd "spack install gcc@6.4.0 %${COMPILER_NAME}@${COMPILER_VERSION}"
  cmd "spack install gcc@5.5.0 %${COMPILER_NAME}@${COMPILER_VERSION}"
  cmd "spack install gcc@4.9.4 %${COMPILER_NAME}@${COMPILER_VERSION}"
  cmd "spack install llvm %${COMPILER_NAME}@${COMPILER_VERSION}"

  cmd "unset TMPDIR"

  printf "\nDone installing shared software with ${COMPILER_NAME}@${COMPILER_VERSION} at $(date).\n"
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
