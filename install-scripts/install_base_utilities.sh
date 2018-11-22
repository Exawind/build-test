#!/bin/bash -l

#PBS -N install-base-utilities
#PBS -l nodes=1:ppn=24,walltime=4:00:00,feature=haswell
#PBS -A windsim
#PBS -q short
#PBS -j oe
#PBS -W umask=002

# Script for shared installation of ECP related utilities on Eagle, Peregrine, and Rhodes

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

# Find machine we're on
case "${NREL_CLUSTER}" in
  peregrine)
    MACHINE=peregrine
  ;;
  eagle)
    MACHINE=eagle
  ;;
esac
MYHOSTNAME=$(hostname -s)
case "${MYHOSTNAME}" in
  rhodes)
    MACHINE=rhodes
  ;;
esac

DATE=2018-11-21
 
if [ "${MACHINE}" == 'eagle' ]; then
  INSTALL_DIR=/nopt/nrel/ecom/hpacf/utilities/${DATE}
  GCC_COMPILER_VERSION="4.8.5"
elif [ "${MACHINE}" == 'peregrine' ]; then
  INSTALL_DIR=/nopt/nrel/ecom/hpacf/utilities/${DATE}
  GCC_COMPILER_VERSION="4.8.5"
elif [ "${MACHINE}" == 'rhodes' ]; then
  INSTALL_DIR=/opt/utilities/${DATE}
  GCC_COMPILER_VERSION="4.8.5"
else
  printf "\nMachine name not recognized.\n"
  exit 1
fi

BUILD_TEST_DIR=$(pwd)/..

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
  cmd "git clone https://github.com/exawind/build-test.git ${BUILD_TEST_DIR}"
  cmd "cd ${BUILD_TEST_DIR}/configs && ./setup-spack.sh"
  cmd "cp ${BUILD_TEST_DIR}/configs/machines/${MACHINE}/compilers.yaml.base ${SPACK_ROOT}/etc/spack/compilers.yaml"
  cmd "mkdir -p ${SPACK_ROOT}/etc/spack/licenses/intel"
  cmd "cp ${HOME}/save/license.lic ${SPACK_ROOT}/etc/spack/licenses/intel/"

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
  printf "\nInstalling base utilities with ${COMPILER_NAME}@${COMPILER_VERSION} at $(date).\n"

  printf "\nLoading modules...\n"
  if [ "${MACHINE}" == 'eagle' ]; then
    cmd "module purge"
    cmd "module load gcc/7.3.0"
    cmd "module list"
    printf "\nMaking and setting TMPDIR to disk...\n"
    cmd "mkdir -p ${HOME}/.tmp"
    cmd "export TMPDIR=${HOME}/.tmp"
  elif [ "${MACHINE}" == 'peregrine' ]; then
    cmd "module purge"
    cmd "module use /nopt/nrel/ecom/ecp/base/c/spack/share/spack/modules/linux-centos7-x86_64/gcc-6.2.0"
    cmd "module load gcc/6.2.0"
    cmd "module load git"
    cmd "module load python/2.7.15"
    cmd "module load curl"
    cmd "module load binutils"
    cmd "module load texinfo"
    cmd "module load texlive"
    cmd "module list"
    printf "\nMaking and setting TMPDIR to disk...\n"
    cmd "mkdir -p /scratch/${USER}/.tmp"
    cmd "export TMPDIR=/scratch/${USER}/.tmp"
  elif [ "${MACHINE}" == 'rhodes' ]; then
    module use /opt/software/modules
    cmd "module purge"
    cmd "module load unzip"
    cmd "module load patch"
    cmd "module load bzip2"
    cmd "module load cmake"
    cmd "module load git"
    cmd "module load texinfo"
    cmd "module load flex"
    cmd "module load bison"
    cmd "module load wget"
    cmd "module load bc"
    cmd "module load python"
    cmd "module list"
    cmd "source ${SPACK_ROOT}/share/spack/setup-env.sh"
  fi

  if [ ${COMPILER_NAME} == 'gcc' ]; then
    if [ "${MACHINE}" == 'rhodes' ]; then
      printf "\nInstalling utilities needed on rhodes with ${COMPILER_NAME}@${COMPILER_VERSION}...\n"
      cmd "spack install environment-modules %${COMPILER_NAME}@${COMPILER_VERSION}"
      cmd "spack install unzip %${COMPILER_NAME}@${COMPILER_VERSION}"
      cmd "spack install bc %${COMPILER_NAME}@${COMPILER_VERSION}"
      cmd "spack install patch %${COMPILER_NAME}@${COMPILER_VERSION}"
      cmd "spack install bzip2 %${COMPILER_NAME}@${COMPILER_VERSION}"
      cmd "spack install flex %${COMPILER_NAME}@${COMPILER_VERSION}"
      cmd "spack install bison %${COMPILER_NAME}@${COMPILER_VERSION}"
    fi

    printf "\nInstalling utilities using ${COMPILER_NAME}@${COMPILER_VERSION}...\n"
    cmd "spack install binutils %${COMPILER_NAME}@${COMPILER_VERSION}"
    cmd "spack install curl %${COMPILER_NAME}@${COMPILER_VERSION}"
    cmd "spack install wget %${COMPILER_NAME}@${COMPILER_VERSION}"
    cmd "spack install cmake %${COMPILER_NAME}@${COMPILER_VERSION}"
    cmd "spack install emacs %${COMPILER_NAME}@${COMPILER_VERSION}"
    cmd "spack install vim %${COMPILER_NAME}@${COMPILER_VERSION}"
    cmd "spack install git %${COMPILER_NAME}@${COMPILER_VERSION}"
    cmd "spack install tmux %${COMPILER_NAME}@${COMPILER_VERSION}"
    cmd "spack install screen %${COMPILER_NAME}@${COMPILER_VERSION}"
    cmd "spack install global %${COMPILER_NAME}@${COMPILER_VERSION}"
    cmd "spack install texlive scheme=full %${COMPILER_NAME}@${COMPILER_VERSION}"
    cmd "spack install gnuplot+X+wx %${COMPILER_NAME}@${COMPILER_VERSION} ^pango+X"
    cmd "spack install htop %${COMPILER_NAME}@${COMPILER_VERSION}"
    cmd "spack install makedepend %${COMPILER_NAME}@${COMPILER_VERSION}"
    cmd "spack install cppcheck %${COMPILER_NAME}@${COMPILER_VERSION}"
    cmd "spack install likwid %${COMPILER_NAME}@${COMPILER_VERSION}"
    cmd "spack install texinfo %${COMPILER_NAME}@${COMPILER_VERSION}"
    cmd "spack install image-magick %${COMPILER_NAME}@${COMPILER_VERSION}"
  fi

  cmd "unset TMPDIR"

  printf "\nDone installing utilities with ${COMPILER_NAME}@${COMPILER_VERSION} at $(date).\n"
done

printf "\nSetting permissions...\n"
if [ "${MACHINE}" == 'eagle' ]; then
  cmd "chmod -R a+rX,go-w ${INSTALL_DIR}"
elif [ "${MACHINE}" == 'peregrine' ]; then
  cmd "chmod -R a+rX,go-w ${INSTALL_DIR}"
elif [ "${MACHINE}" == 'rhodes' ]; then
  cmd "chgrp windsim /opt"
  cmd "chgrp windsim /opt/utilities"
  cmd "chgrp -R windsim ${INSTALL_DIR}"
  cmd "chmod a+rX,go-w /opt"
  cmd "chmod a+rX,go-w /opt/utilities"
  cmd "chmod -R a+rX,go-w ${INSTALL_DIR}"
fi

printf "\n$(date)\n"
printf "\nDone!\n"
