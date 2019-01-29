#!/bin/bash -l

# Script for installation of ECP related compilers on Eagle, Peregrine, and Rhodes

set -e
TYPE=compilers

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
 
if [ "${MACHINE}" == 'eagle' ] || [ "${MACHINE}" == 'peregrine' ]; then
  INSTALL_DIR=/nopt/nrel/ecom/hpacf/${TYPE}/${DATE}
  GCC_COMPILER_VERSION="4.8.5"
elif [ "${MACHINE}" == 'rhodes' ]; then
  INSTALL_DIR=/opt/${TYPE}/${DATE}
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
  cmd "cd ${BUILD_TEST_DIR}/configs && ./setup-spack.sh"
  cmd "cp ${BUILD_TEST_DIR}/configs/machines/${MACHINE}/compilers.yaml.${TYPE} ${SPACK_ROOT}/etc/spack/compilers.yaml"
  cmd "cp ${BUILD_TEST_DIR}/configs/machines/${MACHINE}/modules.yaml.${TYPE} ${SPACK_ROOT}/etc/spack/modules.yaml"
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
  printf "\nInstalling ${TYPE} with ${COMPILER_NAME}@${COMPILER_VERSION} at $(date).\n"

  # Load necessary modules
  printf "\nLoading modules...\n"
  if [ "${MACHINE}" == 'eagle' ] || [ "${MACHINE}" == 'peregrine' ]; then
    cmd "module purge"
    cmd "module unuse ${MODULEPATH}"
    cmd "module use /nopt/nrel/ecom/hpacf/utilities/modules"
    cmd "module load git"
    cmd "module load python/2.7.15"
    cmd "module load curl"
    cmd "module load binutils"
    cmd "module list"
    printf "\nMaking and setting TMPDIR to disk...\n"
    cmd "mkdir -p /scratch/${USER}/.tmp"
    cmd "export TMPDIR=/scratch/${USER}/.tmp"
  elif [ "${MACHINE}" == 'rhodes' ]; then
    cmd "module purge"
    cmd "module unuse ${MODULEPATH}"
    cmd "module use /opt/utilities/modules"
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
    cmd "module load python/2.7.15"
    cmd "module list"
    cmd "source ${SPACK_ROOT}/share/spack/setup-env.sh"
  fi

  if [ ${COMPILER_NAME} == 'gcc' ]; then
    printf "\nInstalling ${TYPE} using ${COMPILER_NAME}@${COMPILER_VERSION}...\n"
    cmd "spack install gcc@8.2.0 %${COMPILER_NAME}@${COMPILER_VERSION}"
    cmd "spack install gcc@7.3.0 %${COMPILER_NAME}@${COMPILER_VERSION}"
    cmd "spack install gcc@6.4.0 %${COMPILER_NAME}@${COMPILER_VERSION}"
    cmd "spack install gcc@5.5.0 %${COMPILER_NAME}@${COMPILER_VERSION}"
    cmd "spack install gcc@4.9.4 %${COMPILER_NAME}@${COMPILER_VERSION}"
    cmd "spack install gcc@4.8.5 %${COMPILER_NAME}@${COMPILER_VERSION}"
    cmd "spack install llvm %${COMPILER_NAME}@${COMPILER_VERSION}"
    cmd "spack install llvm@6.0.1 %${COMPILER_NAME}@${COMPILER_VERSION}"
    cmd "spack install intel-parallel-studio@cluster.2019.1+advisor+inspector+mkl+mpi+vtune %${COMPILER_NAME}@${COMPILER_VERSION}"
    cmd "spack install intel-parallel-studio@cluster.2018.4+advisor+inspector+mkl+mpi+vtune %${COMPILER_NAME}@${COMPILER_VERSION}"
    cmd "spack install binutils %${COMPILER_NAME}@${COMPILER_VERSION}"
    cmd "spack install pgi+nvidia %${COMPILER_NAME}@${COMPILER_VERSION}"
    # The PGI compilers need a libnuma.so.1.0.0 copied into its lib directory and symlinked to libnuma.so and libnuma.so.1
    cmd "spack install numactl %${COMPILER_NAME}@${COMPILER_VERSION}"
  fi

  cmd "unset TMPDIR"

  printf "\nDone installing ${TYPE} with ${COMPILER_NAME}@${COMPILER_VERSION} at $(date).\n"
done

printf "\nSetting permissions...\n"
if [ "${MACHINE}" == 'eagle' ] || [ "${MACHINE}" == 'peregrine' ]; then
  cmd "chmod -R a+rX,go-w ${INSTALL_DIR}"
  cmd "chgrp -R n-ecom ${INSTALL_DIR}"
elif [ "${MACHINE}" == 'rhodes' ]; then
  cmd "chgrp windsim /opt"
  cmd "chgrp windsim /opt/${TYPE}"
  cmd "chgrp -R windsim ${INSTALL_DIR}"
  cmd "chmod a+rX,go-w /opt"
  cmd "chmod a+rX,go-w /opt/${TYPE}"
  cmd "chmod -R a+rX,go-w ${INSTALL_DIR}"
fi

printf "\n$(date)\n"
printf "\nDone!\n"

# Last step
# Edit compilers.yaml to point to all compilers this script installed
# Edit intel-parallel-studio modules to set INTEL_LICENSE_FILE correctly
