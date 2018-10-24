#!/bin/bash -l

#PBS -N install-software-eagle
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
  INSTALL_DIR=${SCRATCH}/eagle/eagle_software
  GCC_COMPILER_VERSION="7.3.0"
  INTEL_COMPILER_VERSION="18.0.3"
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
  # Make sure compilers.yaml is set up to point to the base compilers before this step
  cmd "cp ${BUILD_TEST_DIR}/configs/machines/${MACHINE}/compilers.yaml ${SPACK_ROOT}/etc/spack/compilers.yaml"
  #cmd "mkdir -p ${SPACK_ROOT}/etc/spack/licenses/intel"
  #cmd "cp ${HOME}/save/intel_license/new_license/license.lic ${SPACK_ROOT}/etc/spack/licenses/intel/"

  printf "============================================================\n"
  printf "Done setting up install directory.\n"
  printf "============================================================\n"
fi

printf "\nLoading Spack...\n"
cmd "source ${SPACK_ROOT}/share/spack/setup-env.sh"

for COMPILER_NAME in gcc intel
do
  if [ ${COMPILER_NAME} == 'gcc' ]; then
    COMPILER_VERSION="${GCC_COMPILER_VERSION}"
  elif [ ${COMPILER_NAME} == 'intel' ]; then
    COMPILER_VERSION="${INTEL_COMPILER_VERSION}"
  fi
  printf "\nInstalling with ${COMPILER_NAME}@${COMPILER_VERSION} at $(date).\n"

  # Load necessary modules
  printf "\nLoading modules...\n"
  cmd "module purge"
  cmd "module use /nopt/nrel/ecom/ecp/base/a/spack/share/spack/modules/linux-centos7-x86_64/gcc-6.2.0"
  cmd "module load git"
  cmd "module load python/2.7.15"
  cmd "module load curl"
  cmd "module load binutils"
  cmd "module load /scratch/jrood/eagle/eagle_compilers/spack/share/spack/modules/linux-centos7-x86_64/gcc-6.2.0/gcc/7.3.0"
  if [ "${COMPILER_NAME}" == 'intel' ]; then
    cmd "module load /scratch/jrood/eagle/eagle_compilers/spack/share/spack/modules/linux-centos7-x86_64/gcc-6.2.0/intel-parallel-studio/cluster.2018.3"
  fi
  cmd "module list"
  # Set the TMPDIR to disk so it doesn't run out of space
  printf "\nMaking and setting TMPDIR to disk...\n"
  cmd "mkdir -p /scratch/${USER}/.tmp"
  cmd "export TMPDIR=/scratch/${USER}/.tmp"

  printf "\nInstalling software using ${COMPILER_NAME}@${COMPILER_VERSION}...\n"
  cmd "spack install intel-mpi@2018.3.222 %${COMPILER_NAME}@${COMPILER_VERSION}"
  cmd "spack install intel-mkl@2018.3.222 %${COMPILER_NAME}@${COMPILER_VERSION}"
  cmd "spack install openmpi@3.1.2 %${COMPILER_NAME}@${COMPILER_VERSION}"
  cmd "spack install openmpi@2.1.5 %${COMPILER_NAME}@${COMPILER_VERSION}"
  cmd "spack install openmpi@1.10.7 %${COMPILER_NAME}@${COMPILER_VERSION}"
  cmd "spack install hdf5~mpi %${COMPILER_NAME}@${COMPILER_VERSION}"
  if [ "${COMPILER_NAME}" == 'intel' ]; then
    ADD_MPI='^intel-mpi@2018.3.222'
    cmd "spack load intel-mpi@2018.3.222 %${COMPILER_NAME}@${COMPILER_VERSION}"
  fi
  cmd "spack install boost+mpi %${COMPILER_NAME}@${COMPILER_VERSION} ${ADD_MPI}"
  cmd "spack install fftw+mpi %${COMPILER_NAME}@${COMPILER_VERSION} ${ADD_MPI}"
  cmd "spack install hdf5+mpi %${COMPILER_NAME}@${COMPILER_VERSION} ${ADD_MPI}"
  cmd "spack install netcdf+mpi %${COMPILER_NAME}@${COMPILER_VERSION} ${ADD_MPI}"
  cmd "spack install lammps+mpi %${COMPILER_NAME}@${COMPILER_VERSION} ${ADD_MPI} ^cmake %gcc"
  cmd "spack install quantum-espresso+hdf5 %${COMPILER_NAME}@${COMPILER_VERSION} ${ADD_MPI}"

  cmd "unset TMPDIR"

  printf "\nDone installing with ${COMPILER_NAME}@${COMPILER_VERSION} at $(date).\n"
done

printf "\nSetting permissions...\n"
cmd "chmod -R a+rX,o-w,g+w ${INSTALL_DIR}"

printf "\n$(date)\n"
printf "\nDone!\n"
