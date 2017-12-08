#!/bin/bash -l

# Script for running nightly regression tests for Nalu on a particular set 
# of machines using Spack and submitting results to CDash

# Control over printing and executing commands
print_cmds=true
execute_cmds=true

# Function for printing and executing commands
cmd() {
  if ${print_cmds}; then echo "+ $@"; fi
  if ${execute_cmds}; then eval "$@"; fi
}

# Function for testing a single configuration
test_loop_body() {
  printf "************************************************************\n"
  printf "Testing Nalu with:\n"
  printf "${COMPILER_NAME}@${COMPILER_VERSION}\n"
  printf "trilinos@${TRILINOS_BRANCH}\n"
  printf "at $(date).\n"
  printf "************************************************************\n"
  printf "\n"

  # Define TRILINOS and GENERAL_CONSTRAINTS from a single location for all scripts
  cmd "unset GENERAL_CONSTRAINTS"
  cmd "source ${NALU_TESTING_DIR}/NaluSpack/spack_config/shared_constraints.sh"
  # For intel, we want to build against intel-mpi and intel-mkl
  if [ "${COMPILER_NAME}" == 'intel' ]; then
    GENERAL_CONSTRAINTS="^intel-mpi ^intel-mkl ${GENERAL_CONSTRAINTS}"
  fi
  printf "Using constraints: ${GENERAL_CONSTRAINTS}\n\n"

  cmd "cd ${NALU_TESTING_DIR}"

  printf "\nLoading modules...\n"
  if [ "${MACHINE_NAME}" == 'peregrine' ]; then
    cmd "module purge"
    cmd "module use /nopt/nrel/apps/modules/candidate/modulefiles"
    cmd "module use /projects/windsim/exawind/BaseSoftware/spack/share/spack/modules/linux-centos6-x86_64"
    cmd "module load gcc/5.2.0"
    cmd "module load python/2.7.14"
    cmd "module load git/2.6.3"
    cmd "module list"
  elif [ "${MACHINE_NAME}" == 'merlin' ]; then
    cmd "module purge"
    cmd "module load GCCcore/4.9.2"
    cmd "module list"
  fi

  # Don't use OpenMP for clang
  if [ "${COMPILER_NAME}" == 'clang' ]; then
    printf "\nTurning off OpenMP in Trilinos...\n"
    TRILINOS=$(sed 's/+openmp/~openmp/g' <<<"${TRILINOS}")
  fi

  # Uninstall Trilinos; it's an error if it doesn't exist yet, but we skip it
  printf "\nUninstalling Trilinos (this is fine to error when tests are first run or building Trilinos has previously failed)...\n"
  cmd "spack uninstall -a -y trilinos %${COMPILER_NAME}@${COMPILER_VERSION}"
  #cmd "spack uninstall -a -y ${TRILINOS}@${TRILINOS_BRANCH} %${COMPILER_NAME}@${COMPILER_VERSION}"
  #printf "\nUninstalling OpenFAST (this is fine to error when tests are first run or building OpenFAST has previously failed)...\n"
  #cmd "spack uninstall -a -y openfast %${COMPILER_NAME}@${COMPILER_VERSION}"
  #printf "\nUninstalling TIOGA (this is fine to error when tests are first run or building TIOGA has previously failed)...\n"
  #cmd "spack uninstall -a -y tioga %${COMPILER_NAME}@${COMPILER_VERSION}"

  if [ "${MACHINE_NAME}" == 'peregrine' ]; then
    # Fix for Peregrine's broken linker
    printf "\nInstalling binutils...\n"
    cmd "spack install binutils %${COMPILER_NAME}@${COMPILER_VERSION}"
    printf "\nReloading Spack...\n"
    cmd "source ${SPACK_ROOT}/share/spack/setup-env.sh"
    printf "\nLoading binutils...\n"
    cmd "spack load binutils %${COMPILER_NAME}@${COMPILER_VERSION}"
    if [ "${COMPILER_NAME}" == 'intel' ]; then
      printf "\nSetting up rpath for Intel...\n"
      # For Intel compiler to include rpath to its own libraries
      for i in ICCCFG ICPCCFG IFORTCFG
      do
        cmd "eval export $i=${SPACK_ROOT}/etc/spack/intel.cfg"
      done
    fi
  elif [ "${MACHINE_NAME}" == 'merlin' ]; then
    if [ "${COMPILER_NAME}" == 'intel' ]; then
      # For Intel compiler to include rpath to its own libraries
      cmd "eval export INTEL_LICENSE_FILE=28518@hpc-admin1.hpc.nrel.gov"
      for i in ICCCFG ICPCCFG IFORTCFG
      do
        cmd "eval export $i=${SPACK_ROOT}/etc/spack/intel.cfg"
      done
    fi
  fi

  # Set the TMPDIR to disk so it doesn't run out of space
  if [ "${MACHINE_NAME}" == 'peregrine' ]; then
    printf "\nMaking and setting TMPDIR to disk...\n"
    cmd "mkdir -p /scratch/${USER}/.tmp"
    cmd "eval export TMPDIR=/scratch/${USER}/.tmp"
  elif [ "${MACHINE_NAME}" == 'merlin' ]; then
    cmd "eval export TMPDIR=/dev/shm"
  fi

  printf "\nUpdating Trilinos (this is fine to error when tests are first run)...\n"
  cmd "spack cd ${TRILINOS}@${TRILINOS_BRANCH} %${COMPILER_NAME}@${COMPILER_VERSION} ${GENERAL_CONSTRAINTS} && pwd && git fetch --all && git reset --hard origin/${TRILINOS_BRANCH} && git clean -df && git status -uno"
  #printf "\nUpdating OpenFAST (this is fine to error when tests are first run)...\n"
  #cmd "spack cd openfast@${OPENFAST_BRANCH} %${COMPILER_NAME}@${COMPILER_VERSION} && pwd && git fetch --all && git reset --hard origin/${OPENFAST_BRANCH} && git clean -df && git status -uno"
  #printf "\nUpdating TIOGA (this is fine to error when tests are first run)...\n"
  #cmd "spack cd tioga@${TIOGA_BRANCH} %${COMPILER_NAME}@${COMPILER_VERSION} && pwd && git fetch --all && git reset --hard origin/${TIOGA_BRANCH} && git clean -df && git status -uno"

  printf "\nInstalling Nalu dependencies using ${COMPILER_NAME}@${COMPILER_VERSION}...\n"
  TPL_VARIANTS=''
  TPL_CONSTRAINTS=''
  for TPL in "${LIST_OF_TPLS[@]}"; do
    TPL_VARIANTS+="+${TPL}"
    if [ "${TPL}" == 'openfast' ] ; then
      TPL_CONSTRAINTS="^openfast@${OPENFAST_BRANCH} ${TPL_CONSTRAINTS}"
    fi
    if [ "${TPL}" == 'tioga' ] ; then
      TPL_CONSTRAINTS="^tioga@${TIOGA_BRANCH} ${TPL_CONSTRAINTS}"
    fi
  done

  cmd "spack install --keep-stage --only dependencies nalu ${TPL_VARIANTS} %${COMPILER_NAME}@${COMPILER_VERSION} ^${TRILINOS}@${TRILINOS_BRANCH} ${GENERAL_CONSTRAINTS} ${TPL_CONSTRAINTS}"

  STAGE_DIR=$(spack location -S)
  if [ ! -z "${STAGE_DIR}" ]; then
    #Haven't been able to find another robust way to rm with exclude
    printf "\nRemoving all staged directories except Trilinos...\n"
    cmd "cd ${STAGE_DIR} && rm -rf a* b* c* d* e* f* g* h* i* j* k* l* m* n* o* p* q* r* s* tar* u* v* w* x* y* z*"
    #printf "\nRemoving all staged directories except Trilinos and OpenFAST...\n"
    #cmd "cd ${STAGE_DIR} && rm -rf a* b* c* d* e* f* g* h* i* j* k* l* m* n* openmpi* p* q* r* s* tar* u* v* w* x* y* z*"
    #find ${STAGE_DIR}/ -maxdepth 0 -type d -not -name "trilinos*" -exec rm -r {} \;
  fi

  if [ "${MACHINE_NAME}" == 'peregrine' ]; then
    if [ "${COMPILER_NAME}" == 'intel' ]; then
      printf "\nLoading Intel compiler module for CTest...\n"
      cmd "module load comp-intel/2017.0.2"
      cmd "module list"
    fi
  elif [ "${MACHINE_NAME}" == 'merlin' ]; then
    if [ "${COMPILER_NAME}" == 'intel' ]; then
      printf "\nLoading Intel compiler module for CTest...\n"
      cmd "module purge"
      cmd "module load iccifort/2017.2.174-GCC-6.3.0-2.27"
      cmd "module unload GCCcore/6.3.0"
      cmd "module unload binutils/2.27-GCCcore-6.3.0"
      cmd "module load GCCcore/4.9.2"
      cmd "module list"
    fi
  fi

  printf "\nLoading Spack modules into environment...\n"
  # Refresh available modules (this is only really necessary on the first run of this script
  # because cmake and openmpi will already have been built and module files registered in subsequent runs)
  cmd "source ${SPACK_ROOT}/share/spack/setup-env.sh"
  if [ "${MACHINE_NAME}" == 'mac' ]; then
    cmd "eval export PATH=$(spack location -i cmake %${COMPILER_NAME}@${COMPILER_VERSION})/bin:${PATH}"
    cmd "eval export PATH=$(spack location -i openmpi %${COMPILER_NAME}@${COMPILER_VERSION})/bin:${PATH}"
  else
    if [ "${COMPILER_NAME}" == 'gcc' ]; then
      cmd "spack load cmake %${COMPILER_NAME}@${COMPILER_VERSION}"
      cmd "spack load openmpi %${COMPILER_NAME}@${COMPILER_VERSION}"
    elif [ "${COMPILER_NAME}" == 'intel' ]; then
      cmd "spack load cmake %${COMPILER_NAME}@${COMPILER_VERSION}"
      cmd "spack load intel-mpi %${COMPILER_NAME}@${COMPILER_VERSION}"
    fi
    cmd "module list"
    cmd "which cmake"
    cmd "which mpiexec"
  fi

  printf "\nSetting variables to pass to CTest...\n"
  TRILINOS_DIR=$(spack location -i ${TRILINOS}@${TRILINOS_BRANCH} %${COMPILER_NAME}@${COMPILER_VERSION} ${GENERAL_CONSTRAINTS})
  YAML_DIR=$(spack location -i yaml-cpp %${COMPILER_NAME}@${COMPILER_VERSION})
  printf "TRILINOS_DIR=${TRILINOS_DIR}\n"
  printf "YAML_DIR=${YAML_DIR}\n"
  TPL_TEST_ARGS=''
  for TPL in "${LIST_OF_TPLS[@]}"; do
    if [ "${TPL}" == 'openfast' ]; then
      OPENFAST_DIR=$(spack location -i openfast %${COMPILER_NAME}@${COMPILER_VERSION})
      TPL_TEST_ARGS="-DENABLE_OPENFAST=ON -DOpenFAST_DIR=${OPENFAST_DIR} ${TPL_TEST_ARGS}"
      printf "OPENFAST_DIR=${OPENFAST_DIR}\n"
    fi
    if [ "${TPL}" == 'tioga' ]; then
      TIOGA_DIR=$(spack location -i tioga %${COMPILER_NAME}@${COMPILER_VERSION})
      TPL_TEST_ARGS="-DENABLE_TIOGA=ON -DTIOGA_DIR=${TIOGA_DIR} ${TPL_TEST_ARGS}"
      printf "TIOGA_DIR=${TIOGA_DIR}\n"
    fi
  done

  for BUILD_TYPE in "${LIST_OF_BUILD_TYPES[@]}"; do

    # Set the extra identifiers for CDash build description
    #BUILD_TYPE_LOWERCASE="$(tr [A-Z] [a-z] <<< "${BUILD_TYPE}")"
    #EXTRA_BUILD_NAME="-${COMPILER_NAME}-${COMPILER_VERSION}-trlns_${TRILINOS_BRANCH}-${BUILD_TYPE_LOWERCASE}"
    EXTRA_BUILD_NAME="-${COMPILER_NAME}-${COMPILER_VERSION}-trlns_${TRILINOS_BRANCH}"

    if [ ! -z "${NALU_DIR}" ]; then
      printf "\nCleaning Nalu directory...\n"
      cmd "cd ${NALU_DIR} && git reset --hard origin/master && git clean -df && git status -uno"
      cmd "cd ${NALU_DIR}/build && rm -rf ${NALU_DIR}/build/*"
    fi

    printf "\nSetting warning flags...\n"
    WARNINGS="-Wall"
    cmd "eval export CXXFLAGS=\'"${WARNINGS}"\'"
    cmd "eval export CFLAGS=\'"${WARNINGS}"\'"
    cmd "eval export FFLAGS=\'"${WARNINGS}"\'"

    printf "\nSetting OpenMP stuff...\n"
    cmd "eval export OMP_NUM_THREADS=1"
    cmd "eval export OMP_PROC_BIND=false"

    printf "\nRunning CTest at $(date)...\n"
    cmd "cd ${NALU_DIR}/build"
    cmd "ctest -DNIGHTLY_DIR=${NALU_TESTING_DIR} -DYAML_DIR=${YAML_DIR} -DTRILINOS_DIR=${TRILINOS_DIR} -DHOST_NAME=${HOST_NAME} -DBUILD_TYPE=${BUILD_TYPE} -DEXTRA_BUILD_NAME=${EXTRA_BUILD_NAME} -DTPL_TEST_ARGS=\"${TPL_TEST_ARGS}\" -VV -S ${NALU_DIR}/reg_tests/CTestNightlyScript.cmake"
    printf "Returned from CTest at $(date)...\n"
  done

  printf "\nUnloading Spack modules from environment...\n"
  if [ "${MACHINE_NAME}" != 'mac' ]; then
    if [ "${COMPILER_NAME}" == 'gcc' ]; then
      cmd "spack unload cmake %${COMPILER_NAME}@${COMPILER_VERSION}"
      cmd "spack unload openmpi %${COMPILER_NAME}@${COMPILER_VERSION}"
    elif [ "${COMPILER_NAME}" == 'intel' ]; then
      cmd "spack unload cmake %${COMPILER_NAME}@${COMPILER_VERSION}"
      cmd "spack unload intel-mpi %${COMPILER_NAME}@${COMPILER_VERSION}"
    fi
    cmd "module list"
  elif [ "${MACHINE_NAME}" == 'peregrine' ]; then
    cmd "spack unload binutils %${COMPILER_NAME}@${COMPILER_VERSION}"
    cmd "module list"
    #unset TMPDIR
  fi

  printf "\n"
  printf "************************************************************\n"
  printf "Done testing Nalu with:\n"
  printf "${COMPILER_NAME}@${COMPILER_VERSION}\n"
  printf "trilinos@${TRILINOS_BRANCH}\n"
  printf "at $(date).\n"
  printf "************************************************************\n"
}

# Main function for assembling configurations to test
main() {
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
 
  if [ $# -ne 1 ]; then
      printf "$0: usage: $0 <machine>\n"
      exit 1
  else
    MACHINE_NAME="$1"
  fi
 
  HOST_NAME="${MACHINE_NAME}.hpc.nrel.gov"
 
  # Set configurations to test for each machine
  if [ "${MACHINE_NAME}" == 'peregrine' ]; then
    declare -a LIST_OF_BUILD_TYPES=('Release')
    declare -a LIST_OF_TRILINOS_BRANCHES=('develop')
    declare -a LIST_OF_COMPILERS=('gcc' 'intel')
    declare -a LIST_OF_GCC_COMPILERS=('5.2.0')
    declare -a LIST_OF_INTEL_COMPILERS=('17.0.2')
    declare -a LIST_OF_TPLS=('openfast')
    OPENFAST_BRANCH=develop
    TIOGA_BRANCH=develop # develop points to nalu-api in Spack
    NALU_TESTING_DIR=/projects/windsim/exawind/NaluNightlyTesting
  elif [ "${MACHINE_NAME}" == 'merlin' ]; then
    declare -a LIST_OF_BUILD_TYPES=('Release')
    declare -a LIST_OF_TRILINOS_BRANCHES=('develop')
    declare -a LIST_OF_COMPILERS=('gcc' 'intel')
    declare -a LIST_OF_GCC_COMPILERS=('4.9.2')
    declare -a LIST_OF_INTEL_COMPILERS=('17.0.2')
    #declare -a LIST_OF_TPLS=('openfast')
    OPENFAST_BRANCH=develop
    TIOGA_BRANCH=develop # develop points to nalu-api in Spack
    NALU_TESTING_DIR=${HOME}/NaluNightlyTesting
  elif [ "${MACHINE_NAME}" == 'mac' ]; then
    declare -a LIST_OF_BUILD_TYPES=('Release')
    declare -a LIST_OF_TRILINOS_BRANCHES=('master' 'develop')
    declare -a LIST_OF_COMPILERS=('gcc' 'clang')
    declare -a LIST_OF_GCC_COMPILERS=('7.2.0')
    declare -a LIST_OF_CLANG_COMPILERS=('9.0.0-apple')
    #declare -a LIST_OF_TPLS=('openfast')
    OPENFAST_BRANCH=develop
    TIOGA_BRANCH=develop # develop points to nalu-api in Spack
    NALU_TESTING_DIR=${HOME}/NaluNightlyTesting
  else
    printf "\nMachine name not recognized.\n"
  fi
 
  NALU_DIR=${NALU_TESTING_DIR}/Nalu
  NALUSPACK_DIR=${NALU_TESTING_DIR}/NaluSpack
  cmd "eval export SPACK_ROOT=${NALU_TESTING_DIR}/spack"
 
  printf "============================================================\n"
  printf "HOST_NAME: ${HOST_NAME}\n"
  printf "NALU_TESTING_DIR: ${NALU_TESTING_DIR}\n"
  printf "NALU_DIR: ${NALU_DIR}\n"
  printf "NALUSPACK_DIR: ${NALU_DIR}\n"
  printf "SPACK_ROOT: ${SPACK_ROOT}\n"
  printf "Testing configurations:\n"
  printf "LIST_OF_BUILD_TYPES: ${LIST_OF_BUILD_TYPES[*]}\n"
  printf "LIST_OF_TRILINOS_BRANCHES: ${LIST_OF_TRILINOS_BRANCHES[*]}\n"
  printf "LIST_OF_COMPILERS: ${LIST_OF_COMPILERS[*]}\n"
  printf "LIST_OF_GCC_COMPILERS: ${LIST_OF_GCC_COMPILERS[*]}\n"
  printf "LIST_OF_INTEL_COMPILERS: ${LIST_OF_INTEL_COMPILERS[*]}\n"
  printf "LIST_OF_TPLS: ${LIST_OF_TPLS[*]}\n"
  printf "OPENFAST_BRANCH: ${OPENFAST_BRANCH}\n"
  printf "============================================================\n"
 
  if [ ! -d "${NALU_TESTING_DIR}" ]; then
    printf "============================================================\n"
    printf "Top level testing directory doesn't exist.\n"
    printf "Creating everything from scratch...\n"
    printf "============================================================\n"
 
    printf "Creating top level testing directory...\n"
    cmd "mkdir -p ${NALU_TESTING_DIR}"
 
    printf "\nCloning Spack repo...\n"
    cmd "git clone https://github.com/spack/spack.git ${SPACK_ROOT}"
    # Nalu v1.2.0 matching sha-1 for Spack
    # cmd "cd ${SPACK_ROOT} && git checkout d3e4e88bae2b3ddf71bf56da18fe510e74e020b2"
 
    printf "\nConfiguring Spack...\n"
    cmd "git clone https://github.com/NaluCFD/NaluSpack.git ${NALUSPACK_DIR}"
    # Nalu v1.2.0 matching tag for NaluSpack
    #cmd "cd ${NALUSPACK_DIR} && git checkout v1.2.0"
    cmd "cd ${NALUSPACK_DIR}/spack_config && ./setup_spack.sh"
 
    # Checkout Nalu and meshes submodule outside of Spack so ctest can build it itself
    printf "\nCloning Nalu repo...\n"
    cmd "git clone --recursive https://github.com/NaluCFD/Nalu.git ${NALU_DIR}"
    # Nalu v1.2.0 tag
    #cmd "cd ${NALU_DIR} && git checkout v1.2.0"
 
    printf "\nMaking job output directory...\n"
    cmd "mkdir -p ${NALU_TESTING_DIR}/jobs"
 
    printf "============================================================\n"
    printf "Done setting up testing directory.\n"
    printf "============================================================\n"
  fi
 
  printf "\nLoading Spack...\n"
  cmd "source ${SPACK_ROOT}/share/spack/setup-env.sh"

  printf "\n"
  printf "============================================================\n"
  printf "Starting testing loops...\n"
  printf "============================================================\n"
 
  # Test Nalu for the list of trilinos branches
  for TRILINOS_BRANCH in "${LIST_OF_TRILINOS_BRANCHES[@]}"; do
    # Test Nalu for the list of compilers
    for COMPILER_NAME in "${LIST_OF_COMPILERS[@]}"; do
 
      # Move specific compiler version to generic compiler version
      if [ "${COMPILER_NAME}" == 'gcc' ]; then
        declare -a COMPILER_VERSIONS=("${LIST_OF_GCC_COMPILERS[@]}")
      elif [ "${COMPILER_NAME}" == 'intel' ]; then
        declare -a COMPILER_VERSIONS=("${LIST_OF_INTEL_COMPILERS[@]}")
      elif [ "${COMPILER_NAME}" == 'clang' ]; then
        declare -a COMPILER_VERSIONS=("${LIST_OF_CLANG_COMPILERS[@]}")
      fi
 
      # Test Nalu for the list of compiler versions
      for COMPILER_VERSION in "${COMPILER_VERSIONS[@]}"; do
        printf "\nRemoving previous test log for uploading to CDash...\n"
        cmd "rm ${NALU_TESTING_DIR}/jobs/nalu-test-log.txt"
        (test_loop_body) 2>&1 | tee -i ${NALU_TESTING_DIR}/jobs/nalu-test-log.txt
      done
    done
  done

  printf "============================================================\n"
  printf "Done with testing loops.\n"
  printf "============================================================\n"
  printf "============================================================\n"
  printf "Final Steps.\n"
  printf "============================================================\n"
 
  if [ "${MACHINE_NAME}" == 'merlin' ]; then
    if [ ! -z "${TMPDIR}" ]; then
      printf "\nCleaning TMPDIR directory...\n"
      cmd "cd /dev/shm && rm -rf /dev/shm/* &> /dev/null"
      #cmd "cd ${TMPDIR} && rm -r ${TMPDIR}/* &> /dev/null"
      cmd "unset TMPDIR"
    fi
  fi

  #if [ "${MACHINE_NAME}" != 'mac' ]; then
  #  printf "\nSetting permissions...\n"
  #  cmd "chmod -R a+rX,go-w ${NALU_TESTING_DIR}"
  #  cmd "chmod g+w ${NALU_TESTING_DIR}"
  #  cmd "chmod g+w ${NALU_TESTING_DIR}/spack"
  #  cmd "chmod g+w ${NALU_TESTING_DIR}/spack/opt"
  #  cmd "chmod g+w ${NALU_TESTING_DIR}/spack/opt/spack"
  #  cmd "chmod -R g+w ${NALU_TESTING_DIR}/spack/opt/spack/.spack-db"
  #fi

  printf "============================================================\n"
  printf "Done!\n"
  printf "$(date)\n"
  printf "============================================================\n"
}

main "$@"
