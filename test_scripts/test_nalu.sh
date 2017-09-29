#!/bin/bash -l

# Script for running nightly regression tests for Nalu on a particular set 
# of machines using Spack and submitting results to CDash

printf "$(date)\n"
printf "======================================================\n"
printf "Job is running on ${HOSTNAME}\n"
printf "======================================================\n"
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
  printf "======================================================\n"
fi
printf "\n"

if [ $# -ne 1 ]; then
    printf "$0: usage: $0 <machine>\n"
    exit 1
else
  MACHINE_NAME="$1"
fi

HOST_NAME="${MACHINE_NAME}.hpc.nrel.gov"

# Set configurations to test for each machine
if [ ${MACHINE_NAME} == 'peregrine' ]; then
  declare -a LIST_OF_BUILD_TYPES=("Release")
  declare -a LIST_OF_TRILINOS_BRANCHES=("develop")
  declare -a LIST_OF_COMPILERS=("gcc" "intel")
  declare -a LIST_OF_GCC_COMPILERS=("5.2.0")
  declare -a LIST_OF_INTEL_COMPILERS=("17.0.2")
  NALU_TESTING_DIR=/projects/windFlowModeling/ExaWind/NaluNightlyTesting
elif [ ${MACHINE_NAME} == 'merlin' ]; then
  declare -a LIST_OF_BUILD_TYPES=("Release")
  declare -a LIST_OF_TRILINOS_BRANCHES=("develop")
  declare -a LIST_OF_COMPILERS=("gcc" "intel")
  declare -a LIST_OF_GCC_COMPILERS=("4.9.2")
  declare -a LIST_OF_INTEL_COMPILERS=("17.0.2")
  NALU_TESTING_DIR=${HOME}/NaluNightlyTesting
elif [ ${MACHINE_NAME} == 'mac' ]; then
  declare -a LIST_OF_BUILD_TYPES=("Release")
  declare -a LIST_OF_TRILINOS_BRANCHES=("develop")
  declare -a LIST_OF_COMPILERS=("gcc")
  declare -a LIST_OF_GCC_COMPILERS=("7.2.0")
  declare -a LIST_OF_CLANG_COMPILERS=("5.0.0")
  NALU_TESTING_DIR=${HOME}/NaluNightlyTesting
else
  printf "\nMachine name not recognized.\n\n"
fi

NALU_DIR=${NALU_TESTING_DIR}/Nalu
NALUSPACK_DIR=${NALU_TESTING_DIR}/NaluSpack
export SPACK_ROOT=${NALU_TESTING_DIR}/spack

# Create and set up the entire testing directory if it doesn't exist
if [ ! -d "${NALU_TESTING_DIR}" ]; then
  printf "\n\nTop level testing directory doesn't exist. Creating everything from scratch...\n\n"

  # Make top level testing directory
  printf "\n\nCreating top level testing directory...\n\n"
  (set -x; mkdir -p ${NALU_TESTING_DIR})

  # Create and set up nightly directory with Spack installation
  printf "\n\nCloning Spack repo...\n\n"
  (set -x; git clone https://github.com/LLNL/spack.git ${SPACK_ROOT})

  # Configure Spack for Peregrine
  printf "\n\nConfiguring Spack...\n\n"
  (set -x; git clone https://github.com/NaluCFD/NaluSpack.git ${NALUSPACK_DIR})
  (cd ${NALUSPACK_DIR}/spack_config && ./setup_spack.sh)

  # Checkout Nalu and meshes submodule outside of Spack so ctest can build it itself
  printf "\n\nCloning Nalu repo...\n\n"
  (set -x; git clone --recursive https://github.com/NaluCFD/Nalu.git ${NALU_DIR})

  # Create a jobs directory
  printf "\n\nMaking job output directory...\n\n"
  (set -x; mkdir -p ${NALU_TESTING_DIR}/jobs)
fi

# Load Spack
printf "\n\nLoading Spack...\n\n"
source ${SPACK_ROOT}/share/spack/setup-env.sh

# Test Nalu for the list of trilinos branches
for TRILINOS_BRANCH in "${LIST_OF_TRILINOS_BRANCHES[@]}"; do
  # Test Nalu for the list of compilers
  for COMPILER_NAME in "${LIST_OF_COMPILERS[@]}"; do

    # Move specific compiler version to generic compiler version
    if [ ${COMPILER_NAME} == 'gcc' ]; then
      declare -a COMPILER_VERSIONS=("${LIST_OF_GCC_COMPILERS[@]}")
    elif [ ${COMPILER_NAME} == 'intel' ]; then
      declare -a COMPILER_VERSIONS=("${LIST_OF_INTEL_COMPILERS[@]}")
    elif [ ${COMPILER_NAME} == 'clang' ]; then
      declare -a COMPILER_VERSIONS=("${LIST_OF_CLANG_COMPILERS[@]}")
    fi

    # Test Nalu for the list of compiler versions
    for COMPILER_VERSION in "${COMPILER_VERSIONS[@]}"; do

      printf "\n\nTesting Nalu with:\n"
      printf "${COMPILER_NAME}@${COMPILER_VERSION}\n"
      printf "trilinos@${TRILINOS_BRANCH}\n"
      printf "at $(date).\n\n"

      # Define TRILINOS and GENERAL_CONSTRAINTS from a single location for all scripts
      unset GENERAL_CONSTRAINTS
      source ${NALU_TESTING_DIR}/NaluSpack/spack_config/shared_constraints.sh
      printf "\n\nUsing constraints: ${GENERAL_CONSTRAINTS}\n\n"

      # Change to Nalu testing directory
      cd ${NALU_TESTING_DIR}

      # Load necessary modules
      printf "\n\nLoading modules...\n\n"
      if [ ${MACHINE_NAME} == 'peregrine' ]; then
        {
        module purge
        module load gcc/5.2.0
        module load python/2.7.8
        module unload mkl
        } &> /dev/null
      elif [ ${MACHINE_NAME} == 'merlin' ]; then
        module purge
        module load GCCcore/4.9.2
      fi
 
      # Uninstall Trilinos; it's an error if it doesn't exist yet, but we skip it
      printf "\n\nUninstalling Trilinos...\n\n"
      (set -x; spack uninstall -y ${TRILINOS}@${TRILINOS_BRANCH} %${COMPILER_NAME}@${COMPILER_VERSION} ${GENERAL_CONSTRAINTS})

      if [ ${MACHINE_NAME} == 'peregrine' ]; then
        if [ ${COMPILER_NAME} == 'gcc' ]; then
          # Fix for Peregrine's broken linker for gcc
          printf "\n\nInstalling binutils...\n\n"
          (set -x; spack install binutils %${COMPILER_NAME}@${COMPILER_VERSION})
          printf "\n\nReloading Spack...\n\n"
          source ${SPACK_ROOT}/share/spack/setup-env.sh
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
      elif [ ${MACHINE_NAME} == 'merlin' ]; then
        if [ ${COMPILER_NAME} == 'intel' ]; then
          # For Intel compiler to include rpath to its own libraries
          export INTEL_LICENSE_FILE=28518@hpc-admin1.hpc.nrel.gov
          for i in ICCCFG ICPCCFG IFORTCFG
          do
            export $i=${SPACK_ROOT}/etc/spack/intel.cfg
          done
        fi
      fi

      # Set the TMPDIR to disk so it doesn't run out of space
      if [ ${MACHINE_NAME} == 'peregrine' ]; then
        printf "\n\nMaking and setting TMPDIR to disk...\n\n"
        (set -x; mkdir -p /scratch/${USER}/.tmp)
        export TMPDIR=/scratch/${USER}/.tmp
      elif [ ${MACHINE_NAME} == 'merlin' ]; then
        export TMPDIR=/dev/shm
      fi

      # Update Trilinos
      printf "\n\nUpdating Trilinos...\n\n"
      (set -x; spack cd ${TRILINOS}@${TRILINOS_BRANCH} %${COMPILER_NAME}@${COMPILER_VERSION} ${GENERAL_CONSTRAINTS} && pwd && git fetch --all && git reset --hard origin/${TRILINOS_BRANCH} && git clean -df && git status -uno)

      # Install all Nalu dependencies
      printf "\n\nInstalling Nalu dependencies using ${COMPILER_NAME}@${COMPILER_VERSION}...\n\n"
      (set -x; spack install --keep-stage --only dependencies nalu %${COMPILER_NAME}@${COMPILER_VERSION} ^${TRILINOS}@${TRILINOS_BRANCH} ${GENERAL_CONSTRAINTS})

      # Delete all the staged files except Trilinos
      STAGE_DIR=$(spack location -S)
      if [ ! -z "${STAGE_DIR}" ]; then
        #Haven't been able to find another robust way to rm with exclude
        (set -x; cd ${STAGE_DIR} && rm -rf a* b* c* d* e* f* g* h* i* j* k* l* m* n* o* p* q* r* s* u* v* w* x* y* z*)
        #find ${STAGE_DIR}/ -maxdepth 0 -type d -not -name "trilinos*" -exec rm -r {} \;
      fi

      if [ ${MACHINE_NAME} == 'peregrine' ]; then
        if [ ${COMPILER_NAME} == 'intel' ]; then
          printf "\n\nLoading Intel compiler module for CTest...\n\n"
          module load comp-intel/2017.0.2
        fi
      fi

      # Load spack built cmake and openmpi into path
      printf "\n\nLoading Spack modules into environment...\n\n"
      # Refresh available modules (this is only really necessary on the first run of this script
      # because cmake and openmpi will already have been built and module files registered in subsequent runs)
      source ${SPACK_ROOT}/share/spack/setup-env.sh
      if [ ${MACHINE_NAME} == 'mac' ]; then
        export PATH=$(spack location -i cmake %${COMPILER_NAME}@${COMPILER_VERSION})/bin:${PATH}
        export PATH=$(spack location -i openmpi %${COMPILER_NAME}@${COMPILER_VERSION})/bin:${PATH}
      else
        spack load cmake %${COMPILER_NAME}@${COMPILER_VERSION}
        spack load openmpi %${COMPILER_NAME}@${COMPILER_VERSION}
      fi

      # Set the Trilinos and Yaml directories to pass to ctest
      printf "\n\nSetting variables to pass to CTest...\n\n"
      TRILINOS_DIR=$(spack location -i ${TRILINOS}@${TRILINOS_BRANCH} %${COMPILER_NAME}@${COMPILER_VERSION} ${GENERAL_CONSTRAINTS})
      YAML_DIR=$(spack location -i yaml-cpp %${COMPILER_NAME}@${COMPILER_VERSION})

      for BUILD_TYPE in "${LIST_OF_BUILD_TYPES[@]}"; do

        # Set the extra identifiers for CDash build description
        #BUILD_TYPE_LOWERCASE="$(tr [A-Z] [a-z] <<< "${BUILD_TYPE}")"
        #EXTRA_BUILD_NAME="-${COMPILER_NAME}-${COMPILER_VERSION}-trlns_${TRILINOS_BRANCH}-${BUILD_TYPE_LOWERCASE}"
        EXTRA_BUILD_NAME="-${COMPILER_NAME}-${COMPILER_VERSION}-trlns_${TRILINOS_BRANCH}"

        # Clean build directory; check if NALU_DIR is blank first
        if [ ! -z "${NALU_DIR}" ]; then
          printf "\n\nCleaning build directory...\n\n"
          (set -x; rm -rf ${NALU_DIR}/build/*)
        fi

        # Set warning flags for build
        WARNINGS="-Wall"
        export CXXFLAGS="${WARNINGS}"
        export CFLAGS="${WARNINGS}"
        export FFLAGS="${WARNINGS}"

        # Run ctest
        printf "\n\nRunning CTest at $(date)...\n\n"
        # Change to Nalu build directory
        cd ${NALU_DIR}/build
        (set -x; \
          export OMP_NUM_THREADS=1; \
          export OMP_PROC_BIND=false; \
          ctest \
          -DNIGHTLY_DIR=${NALU_TESTING_DIR} \
          -DYAML_DIR=${YAML_DIR} \
          -DTRILINOS_DIR=${TRILINOS_DIR} \
          -DHOST_NAME=${HOST_NAME} \
          -DBUILD_TYPE=${BUILD_TYPE} \
          -DEXTRA_BUILD_NAME=${EXTRA_BUILD_NAME} \
          -VV -S ${NALU_DIR}/reg_tests/CTestNightlyScript.cmake)
        printf "\n\nReturned from CTest at $(date)...\n\n"
      done

      # Remove spack built cmake and openmpi from path
      printf "\n\nUnloading Spack modules from environment...\n\n"
      if [ ${MACHINE_NAME} != 'mac' ]; then
        spack unload cmake %${COMPILER_NAME}@${COMPILER_VERSION}
        spack unload openmpi %${COMPILER_NAME}@${COMPILER_VERSION}
      elif [ ${MACHINE_NAME} == 'peregrine' ]; then
        if [ ${COMPILER_NAME} == 'gcc' ]; then
          spack unload binutils %${COMPILER_NAME}@${COMPILER_VERSION}
        fi
        #unset TMPDIR
      fi

      printf "\n\nDone testing Nalu with:\n"
      printf "${COMPILER_NAME}@${COMPILER_VERSION}\n"
      printf "trilinos@${TRILINOS_BRANCH}\n"
      printf "at $(date).\n\n"

    done
  done
done

# Clean TMPDIR before exiting
if [ ${MACHINE_NAME} == 'merlin' ]; then
  if [ ! -z "${TMPDIR}" ]; then
    printf "\n\nCleaning TMPDIR directory...\n\n"
    (set -x; rm -rf /dev/shm/* &> /dev/null)
    #(set -x; rm -r ${TMPDIR}/* &> /dev/null)
    unset TMPDIR
  fi
fi

#if [ ${MACHINE_NAME} != 'mac' ]; then
#  printf "\n\nSetting permissions...\n\n"
#  (set -x; chmod -R a+rX,go-w ${NALU_TESTING_DIR})
#  (set -x; chmod g+w ${NALU_TESTING_DIR})
#  (set -x; chmod g+w ${NALU_TESTING_DIR}/spack)
#  (set -x; chmod g+w ${NALU_TESTING_DIR}/spack/opt)
#  (set -x; chmod g+w ${NALU_TESTING_DIR}/spack/opt/spack)
#  (set -x; chmod -R g+w ${NALU_TESTING_DIR}/spack/opt/spack/.spack-db)
#fi

printf "\n$(date)\n"
printf "\n\nDone!\n\n"
