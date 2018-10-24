#!/bin/bash -l

#PBS -N install-compilers-eagle
#PBS -l nodes=1:ppn=24,walltime=4:00:00,feature=haswell
#PBS -A hpcapps
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

set -e

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
    MACHINE=eagle
  ;;
esac
 
if [ "${MACHINE}" == 'eagle' ]; then
  INSTALL_DIR=${SCRATCH}/eagle/eagle_compilers
  GCC_COMPILER_VERSION="6.2.0"
else
  printf "\nMachine name not recognized.\n"
  exit 1
fi

BUILD_TEST_DIR=${INSTALL_DIR}/build-test

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
  cmd "cp ${BUILD_TEST_DIR}/configs/machines/${MACHINE}/*.yaml ${SPACK_ROOT}/etc/spack/"
  cmd "cp ${BUILD_TEST_DIR}/configs/machines/${MACHINE}/compilers.yaml.base ${SPACK_ROOT}/etc/spack/compilers.yaml"
  cmd "cp ${BUILD_TEST_DIR}/configs/machines/${MACHINE}/modules.yaml.base ${SPACK_ROOT}/etc/spack/modules.yaml"
  cmd "cp ${BUILD_TEST_DIR}/configs/machines/${MACHINE}/packages.yaml.base ${SPACK_ROOT}/etc/spack/packages.yaml"
  cmd "mkdir -p ${SPACK_ROOT}/etc/spack/licenses/intel"
  cmd "cp ${HOME}/save/intel_license/new_license/license.lic ${SPACK_ROOT}/etc/spack/licenses/intel/"

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

  printf "\nInstalling with ${COMPILER_NAME}@${COMPILER_VERSION} at $(date).\n"

  # Load necessary modules
  printf "\nLoading modules...\n"
  cmd "module purge"
  cmd "module use /nopt/nrel/ecom/ecp/base/a/spack/share/spack/modules/linux-centos7-x86_64/gcc-6.2.0"
  cmd "module load gcc/${COMPILER_VERSION}"
  cmd "module load git"
  cmd "module load python/2.7.15"
  cmd "module load curl"
  cmd "module load binutils"
  cmd "module list"
  # Set the TMPDIR to disk so it doesn't run out of space
  printf "\nMaking and setting TMPDIR to disk...\n"
  cmd "mkdir -p /scratch/${USER}/.tmp"
  cmd "export TMPDIR=/scratch/${USER}/.tmp"

  if [ ${COMPILER_NAME} == 'gcc' ]; then
    printf "\nInstalling compilers using ${COMPILER_NAME}@${COMPILER_VERSION}...\n"
    cmd "spack install gcc@8.2.0 %${COMPILER_NAME}@${COMPILER_VERSION}"
    cmd "spack install gcc@7.3.0 %${COMPILER_NAME}@${COMPILER_VERSION}"
    cmd "spack install gcc@6.4.0 %${COMPILER_NAME}@${COMPILER_VERSION}"
    cmd "spack install gcc@5.5.0 %${COMPILER_NAME}@${COMPILER_VERSION}"
    cmd "spack install gcc@4.9.4 %${COMPILER_NAME}@${COMPILER_VERSION}"
    cmd "spack install intel-parallel-studio@cluster.2019.0+advisor+inspector~mkl~mpi~itac+vtune %${COMPILER_NAME}@${COMPILER_VERSION}"
    cmd "spack install intel-parallel-studio@cluster.2018.3+advisor+inspector~mkl~mpi~itac+vtune %${COMPILER_NAME}@${COMPILER_VERSION}"
    cmd "spack install intel-parallel-studio@cluster.2017.7+advisor+inspector~mkl~mpi~itac+vtune %${COMPILER_NAME}@${COMPILER_VERSION}"
    cmd "spack install cmake %${COMPILER_NAME}@${COMPILER_VERSION}"
  fi

  cmd "unset TMPDIR"

  printf "\nDone installing with ${COMPILER_NAME}@${COMPILER_VERSION} at $(date).\n"
done

printf "\nSetting permissions...\n"
cmd "chmod -R a+rX,o-w,g+w ${INSTALL_DIR}"

printf "\n$(date)\n"
printf "\nDone!\n"
