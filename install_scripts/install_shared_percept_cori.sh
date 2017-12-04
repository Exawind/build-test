#!/bin/bash -l

# Script for install percept in a shared location on Cori

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

# Set some version numbers
GCC_COMPILER_VERSION="6.3.0"
INTEL_COMPILER_VERSION="17.0.2"

# Set installation directory
INSTALL_DIR=$SCRATCH/percept
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

    unset GENERAL_CONSTRAINTS
    TRILINOS="trilinos~alloptpkgs~xsdkflags~metis~mumps~superlu-dist+superlu~hypre+hdf5~suite-sparse~python~shared+boost+tpetra+epetra+epetraext+exodus+pnetcdf+zlib+stk+teuchos+belos+zoltan+zoltan2~amesos+amesos2~anasazi~ifpack+ifpack2+muelu~fortran~ml+gtest+aztec+sacado~x11+instantiate~instantiate_cmplx~dtk~fortrilinos~openmp+shards~nox+intrepid~intrepid2+cgns"
    GENERAL_CONSTRAINTS="^cmake@3.8.2 ^boost+filesystem+graph+mpi+program_options+regex+serialization+signals+system+thread@1.60.0 ^parallel-netcdf@1.6.1 ^hdf5@1.8.16 ^netcdf@4.3.3.1 ^superlu@4.3"
    #cmd "source ${INSTALL_DIR}/NaluSpack/spack_config/shared_constraints.sh"
    printf "\nUsing constraints: ${GENERAL_CONSTRAINTS}\n"

    cd ${INSTALL_DIR}

    printf "\nInstalling Percept using ${COMPILER_NAME}@${COMPILER_VERSION}...\n"
    if [ ${COMPILER_NAME} == 'gcc' ]; then
      cmd "spack install percept %${COMPILER_NAME}@${COMPILER_VERSION} ^${TRILINOS}@${TRILINOS_BRANCH} ${GENERAL_CONSTRAINTS}"
    fi

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
