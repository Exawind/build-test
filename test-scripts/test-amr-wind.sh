#!/bin/bash -l

# Script for running nightly regression tests for AMR-Wind on a particular set 
# of machines with a list of configurations for each machine using Spack
# to satisfy dependencies and submitting results to CDash

# Control over printing and executing commands
print_cmds=true
execute_cmds=true

# Function for printing and executing commands
cmd() {
  if ${print_cmds}; then echo "+ $@"; fi
  if ${execute_cmds}; then eval "$@"; fi
}

# Function for testing a single configuration
test_configuration() {
  COMPILER_ID="${COMPILER_NAME}@${COMPILER_VERSION}"
  printf "************************************************************\n"
  printf "Testing AMR-Wind with:\n"
  printf "${COMPILER_ID}\n"
  printf "at $(date)\n"
  printf "************************************************************\n"
  printf "\n"

  # Logic for building up some constraints for use on Spack commands
  MPI_ID=''
  MPI_CONSTRAINTS=''
  BLAS_ID=''
  BLAS_CONSTRAINTS=''
  if [ "${COMPILER_NAME}" == 'gcc' ] || [ "${COMPILER_NAME}" == 'clang' ]; then
    MPI_ID="openmpi"
  elif [ "${COMPILER_NAME}" == 'intel' ]; then
    # For intel, we want to build against intel-mpi and intel-mkl
    MPI_ID="intel-mpi"
    BLAS_ID="intel-mkl"
  fi

  #CUDA version used for tests on Eagle
  CUDA_VERSION="10.0.130"

  cmd "cd ${AMR_WIND_TESTING_ROOT_DIR}"

  printf "\nLoading modules...\n"
  if [ "${MACHINE_NAME}" == 'rhodes' ]; then
    cmd "module purge"
    cmd "module unuse ${MODULEPATH}"
    cmd "module use /opt/compilers/modules-2019-05-08"
    cmd "module use /opt/utilities/modules-2019-05-08"
    cmd "module load unzip"
    cmd "module load patch"
    cmd "module load bzip2"
    cmd "module load git"
    cmd "module load flex"
    cmd "module load bison"
    cmd "module load wget"
    cmd "module load bc"
    cmd "module load cmake"
    cmd "module load cppcheck"
    cmd "module load binutils"
    cmd "module load rsync"
    cmd "module load python/3.7.3"
    cmd "module load py-matplotlib/2.2.3-py3"
    cmd "module load py-six/1.12.0-py3"
    cmd "module load py-numpy/1.16.3-py3"
    cmd "module load py-cycler/0.10.0-py3"
    cmd "module load py-dateutil/2.7.5-py3"
    cmd "module load py-bottleneck/1.2.1-py3"
    cmd "module load py-cython/0.29.5-py3"
    cmd "module load py-nose/1.3.7-py3"
    cmd "module load py-numexpr/2.6.9-py3"
    cmd "module load py-packaging/17.1-py3"
    cmd "module load py-pandas/0.24.1-py3"
    cmd "module load py-pillow/5.4.1-py3"
    cmd "module load py-pytz/2018.4-py3"
    cmd "module load py-setuptools/40.8.0-py3"
    cmd "module load py-kiwisolver/1.0.1-py3"
    cmd "module load py-pyparsing/2.3.1-py3"
    cmd "module load texlive"
    if [ "${COMPILER_NAME}" == 'gcc' ]; then
      cmd "module load ${COMPILER_NAME}/${COMPILER_VERSION}"
    elif [ "${COMPILER_NAME}" == 'clang' ]; then
      cmd "module load llvm/${COMPILER_VERSION}"
    elif [ "${COMPILER_NAME}" == 'intel' ]; then
      cmd "module load ${INTEL_COMPILER_MODULE}"
    fi
  elif [ "${MACHINE_NAME}" == 'eagle' ]; then
    cmd "module purge"
    cmd "module unuse ${MODULEPATH}"
    cmd "module use /nopt/nrel/ecom/hpacf/compilers/modules-2019-05-23"
    cmd "module use /nopt/nrel/ecom/hpacf/utilities/modules-2019-05-23"
    cmd "module use /nopt/nrel/ecom/hpacf/software/modules-2019-05-23/gcc-7.4.0"
    cmd "module load python"
    cmd "module load git"
    cmd "module load binutils"
    cmd "module load cuda/${CUDA_VERSION}"
    cmd "module load cmake"
    cmd "module load rsync"
    if [ "${COMPILER_NAME}" == 'gcc' ]; then
      cmd "module load ${COMPILER_NAME}/${COMPILER_VERSION}"
    elif [ "${COMPILER_NAME}" == 'intel' ]; then
      cmd "module load ${INTEL_COMPILER_MODULE}"
    fi
  fi

  # Set the TMPDIR to disk so it doesn't run out of space
  if [ "${MACHINE_NAME}" == 'eagle' ]; then
    printf "\nMaking and setting TMPDIR to disk...\n"
    cmd "mkdir -p /scratch/${USER}/.tmp"
    cmd "export TMPDIR=/scratch/${USER}/.tmp"
  fi

  # Uninstall packages we want to track; it's an error if they don't exist yet, but a soft error
  #printf "\nUninstalling MASA (this is fine to error when tests are first run or building MASA has previously failed)...\n"
  #cmd "spack uninstall -a -y masa %${COMPILER_ID} || true"

  # Update packages we want to track; it's an error if they don't exist yet, but a soft error
  #printf "\nUpdating MASA (this is fine to error when tests are first run)...\n"
  #cmd "spack cd masa %${COMPILER_ID} && pwd && git fetch --all && git reset --hard origin/master && git clean -df && git status -uno || true"

  cmd "cd ${AMR_WIND_TESTING_ROOT_DIR}" # Change directories to avoid any stale file handles

  if [ "${MACHINE_NAME}" != 'mac' ]; then
    cmd "module list"
  fi

  #printf "\nInstalling AMR-Wind dependencies using ${COMPILER_ID}...\n"
  #(set -x; spack install ${MPI_ID} %${COMPILER_ID})
  (set -x; spack install masa %${COMPILER_ID} cxxflags='-std=c++11')

  # Refresh available modules (this is only really necessary on the first run of this script
  # because cmake and openmpi will already have been built and module files registered in subsequent runs)
  cmd "source ${SPACK_ROOT}/share/spack/setup-env.sh"

  printf "\nLoading Spack modules into environment for CMake and MPI to use during CTest...\n"
  if [ "${MACHINE_NAME}" == 'mac' ]; then
    #cmd "export PATH=$(spack location -i cmake %${COMPILER_ID})/bin:${PATH}"
    cmd "export PATH=$(spack location -i ${MPI_ID} %${COMPILER_ID})/bin:${PATH}"
  else
    cmd "spack load ${MPI_ID} %${COMPILER_ID}"
  fi

  printf "\nSetting variables to pass to CTest...\n"
  CMAKE_CONFIGURE_ARGS=''

  # Turn on verification and find MASA
  MASA_DIR=$(spack location -i masa %${COMPILER_ID})
  CMAKE_CONFIGURE_ARGS="-DAMR_WIND_ENABLE_MASA:BOOL=ON -DMASA_DIR:PATH=${MASA_DIR} ${CMAKE_CONFIGURE_ARGS}"
  printf "MASA_DIR=${MASA_DIR}\n"

  # Set the extra identifiers for CDash build description
  EXTRA_BUILD_NAME="-${COMPILER_NAME}-${COMPILER_VERSION}"

  if [ ! -z "${AMR_WIND_DIR}" ]; then
    printf "\nCleaning AMR-Wind directory...\n"
    cmd "cd ${AMR_WIND_DIR} && git reset --hard origin/development && git clean -df && git status -uno"
    cmd "cd ${AMR_WIND_DIR}/submods/amrex && git reset --hard origin/development && git clean -df && git status -uno"
    cmd "mkdir -p ${AMR_WIND_DIR}/build || true"
    cmd "cd ${AMR_WIND_DIR}/build && rm -rf ${AMR_WIND_DIR}/build/*"
    # Update all the submodules recursively in case the previous ctest update failed because of submodule updates
    cmd "cd ${AMR_WIND_DIR} && git submodule update --init --recursive"
    cmd "ln -sfn ${HOME}/exawind/AMR-WindGoldFiles ${AMR_WIND_DIR}/test/AMR-WindGoldFiles"
    if [ "${USE_LATEST_AMREX}" == 'true' ]; then
      CTEST_ARGS="-DUSE_LATEST_AMREX:BOOL=TRUE ${CTEST_ARGS}"
      EXTRA_BUILD_NAME="${EXTRA_BUILD_NAME}-amrex_dev"
    fi
  fi

  #if [ "${OPENMP_ENABLED}" == 'true' ]; then
  #  printf "\nSetting OpenMP stuff...\n"
  #  cmd "export OMP_NUM_THREADS=1"
  #  cmd "export OMP_PROC_BIND=false"
  #fi

  # Run static analysis and let ctest know we have static analysis output
  if [ "${MACHINE_NAME}" == 'rhodes' ] && [ "${COMPILER_ID}" == 'gcc@7.4.0' ]; then
    printf "\nRunning cppcheck static analysis (AMR-Wind not updated until after this step)...\n"
    cmd "rm ${LOGS_DIR}/amr-wind-static-analysis.txt || true"
    cmd "cppcheck --enable=all --quiet -j 32 -DAMREX_SPACEDIM=3 -DBL_SPACEDIM=3 --max-configs=16 --output-file=${LOGS_DIR}/amr-wind-static-analysis.txt ${AMR_WIND_DIR}/amr-wind || true"
    cmd "printf \"%s warnings\n\" \"$(wc -l < ${LOGS_DIR}/amr-wind-static-analysis.txt | xargs echo -n)\" >> ${LOGS_DIR}/amr-wind-static-analysis.txt"
    CTEST_ARGS="-DHAVE_STATIC_ANALYSIS_OUTPUT:BOOL=TRUE -DSTATIC_ANALYSIS_LOG=${LOGS_DIR}/amr-wind-static-analysis.txt ${CTEST_ARGS}"
  fi

  # Unset the TMPDIR variable after building but before testing during ctest nightly script
  if [ "${MACHINE_NAME}" == 'eagle' ]; then
    CTEST_ARGS="-DUNSET_TMPDIR_VAR:BOOL=TRUE ${CTEST_ARGS}"
  fi

  # Turn on all warnings unless we're gcc 4.9.4
  #if [ "${COMPILER_ID}" == 'gcc@4.9.4' ]; then
  #  CMAKE_CONFIGURE_ARGS="-DENABLE_ALL_WARNINGS:BOOL=FALSE ${CMAKE_CONFIGURE_ARGS}"
  #else
  #  CMAKE_CONFIGURE_ARGS="-DENABLE_ALL_WARNINGS:BOOL=TRUE ${CMAKE_CONFIGURE_ARGS}"
  #fi

  # Default cmake build type
  CMAKE_BUILD_TYPE=RelWithDebInfo
  #VERIFICATION=ON

  # Turn on address sanitizer for clang build on rhodes
  if [ "${COMPILER_NAME}" == 'clang' ] && [ "${MACHINE_NAME}" == 'rhodes' ]; then
    printf "\nSetting up address sanitizer in Clang...\n"
    printf "\nSetting up address sanitizer blacklist and compile flags...\n"
    (set -x; printf "src:/opt/compilers/2019-05-08/spack/var/spack/stage/llvm-7.0.1-362a6wfkd7pmjvjpbfd7tpqpgfej7izt/llvm-7.0.1.src/projects/compiler-rt/lib/asan/asan_malloc_linux.cc" > ${AMR_WIND_DIR}/build/asan_blacklist.txt)
    export CXXFLAGS="-fsanitize=address -fno-omit-frame-pointer -fsanitize-blacklist=${AMR_WIND_DIR}/build/asan_blacklist.txt"
    printf "export CXXFLAGS=${CXXFLAGS}\n"
    printf "\nCurrently ignoring container overflows...\n"
    cmd "export ASAN_OPTIONS=detect_container_overflow=0"
    printf "\nWriting asan.supp suppressions file...\n"
    (set -x; printf "leak:libopen-pal\nleak:libmpi\nleak:libmasa\nleak:libc++\nleak:hwloc_bitmap_alloc" > ${AMR_WIND_DIR}/build/asan.supp)
    cmd "export LSAN_OPTIONS=suppressions=${AMR_WIND_DIR}/build/asan.supp"
    # Can't run ASAN with optimization
    CMAKE_BUILD_TYPE=Debug
    #VERIFICATION=OFF
    #CMAKE_CONFIGURE_ARGS="-DCMAKE_CXX_FLAGS:STRING=-fsanitize=address\ -fno-omit-frame-pointer ${CMAKE_CONFIGURE_ARGS}"
    #CMAKE_CONFIGURE_ARGS="-DCMAKE_LINKER=clang++ -DCMAKE_CXX_LINK_EXECUTABLE=clang++ -DCMAKE_CXX_FLAGS:STRING=\'-fsanitize=address -fno-omit-frame-pointer\' -DCMAKE_EXE_LINKER_FLAGS:STRING=-fsanitize=address ${CMAKE_CONFIGURE_ARGS}"
    #printf "Disabling OpenMP in AMR-Wind for address sanitizer...\n"
    #CMAKE_CONFIGURE_ARGS="-DENABLE_OPENMP:BOOL=FALSE ${CMAKE_CONFIGURE_ARGS}"
    #printf "\nTurning off CMA in OpenMPI for Clang to avoid the Read, expected, errno error...\n"
    #cmd "export OMPI_MCA_btl_vader_single_copy_mechanism=none"
  fi

  # Explicitly set compilers to MPI compilers
  if [ "${COMPILER_NAME}" == 'gcc' ] || [ "${COMPILER_NAME}" == 'clang' ]; then
    MPI_CXX_COMPILER=mpicxx
    MPI_C_COMPILER=mpicc
    MPI_FORTRAN_COMPILER=mpifort
  elif [ "${COMPILER_NAME}" == 'intel' ]; then
    MPI_CXX_COMPILER=mpiicpc
    MPI_C_COMPILER=mpiicc
    MPI_FORTRAN_COMPILER=mpiifort
  fi

  # Give CMake a hint to find Python3
  PYTHON_EXE=$(which python3)

  printf "\nListing cmake and compilers that will be used in ctest...\n"
  cmd "which ${MPI_CXX_COMPILER}"
  cmd "which ${MPI_C_COMPILER}"
  cmd "which ${MPI_FORTRAN_COMPILER}"
  cmd "which mpiexec"
  cmd "which cmake"

  # CMake configure arguments for compilers
  CMAKE_CONFIGURE_ARGS="-DAMR_WIND_ENABLE_MPI:BOOL=ON -DCMAKE_CXX_COMPILER:STRING=${MPI_CXX_COMPILER} -DCMAKE_C_COMPILER:STRING=${MPI_C_COMPILER} -DCMAKE_Fortran_COMPILER:STRING=${MPI_FORTRAN_COMPILER} ${CMAKE_CONFIGURE_ARGS}"

  # CMake configure arguments testing options
  CMAKE_CONFIGURE_ARGS="-DPYTHON_EXECUTABLE=${PYTHON_EXE} -DAMR_WIND_TEST_WITH_FCOMPARE:BOOL=ON ${CMAKE_CONFIGURE_ARGS}"

  # Set CUDA stuff for Eagle
  if [ "${MACHINE_NAME}" == 'eagle' ]; then
    EXTRA_BUILD_NAME="-nvcc-${CUDA_VERSION}${EXTRA_BUILD_NAME}"
    CMAKE_CONFIGURE_ARGS="-DMPIEXEC_EXECUTABLE:STRING=srun -DAMR_WIND_ENABLE_CUDA:BOOL=ON -DCUDA_ARCH:STRING=7.0 ${CMAKE_CONFIGURE_ARGS}"
  fi

  # Set essential arguments for ctest
  CTEST_ARGS="-DTESTING_ROOT_DIR=${AMR_WIND_TESTING_ROOT_DIR} -DAMR_WIND_DIR=${AMR_WIND_DIR} -DTEST_LOG=${LOGS_DIR}/amr-wind-test-log.txt -DHOST_NAME=${HOST_NAME} -DEXTRA_BUILD_NAME=${EXTRA_BUILD_NAME} ${CTEST_ARGS}"

  # Set essential arguments for the ctest cmake configure step
  CMAKE_CONFIGURE_ARGS="-DCMAKE_BUILD_TYPE=${CMAKE_BUILD_TYPE} ${CMAKE_CONFIGURE_ARGS}"

  # Allow for oversubscription in OpenMPI
  if [ "${COMPILER_NAME}" != 'intel' ]; then
    CMAKE_CONFIGURE_ARGS="-DMPIEXEC_PREFLAGS:STRING=--oversubscribe ${CMAKE_CONFIGURE_ARGS}"
  fi

  if [ "${MACHINE_NAME}" != 'mac' ]; then
    cmd "module list"
    printf "\n"
  fi

  cmd "cd ${AMR_WIND_DIR}/build"

  printf "\nRunning CTest at $(date)...\n"
  cmd "ctest ${CTEST_ARGS} -DCMAKE_CONFIGURE_ARGS=\"${CMAKE_CONFIGURE_ARGS}\" -VV -S ${AMR_WIND_DIR}/test/CTestNightlyScript.cmake"
  printf "Returned from CTest at $(date)\n"

  printf "\nGoing to delete these gold files older than 30 days:\n"
  cmd "cd ${GOLDS_DIR} && find . -mtime +30 -not -path '*/\.*'"
  printf "\nDeleting the files...\n"
  cmd "cd ${GOLDS_DIR} && find . -mtime +30 -not -path '*/\.*' -delete"
  printf "\n"

  # Here we create a CMake project on the fly to have it write its OS/compiler info to a file
  printf "Organizing gold files from multiple tests into a single directory...\n"
  if [ ! -z "${AMR_WIND_DIR}" ]; then
    cmd "mkdir -p ${AMR_WIND_DIR}/build/id/build"
  fi
  printf "\nWriting CMake ID project CMakeLists.txt...\n"
  ID_CMAKE_LISTS=${AMR_WIND_DIR}/build/id/CMakeLists.txt
  cat >${ID_CMAKE_LISTS} <<'EOL'
cmake_minimum_required(VERSION 3.11)
project(ID CXX)
file(WRITE ${CMAKE_BINARY_DIR}/id.txt ${CMAKE_SYSTEM_NAME}/${CMAKE_CXX_COMPILER_ID}/${CMAKE_CXX_COMPILER_VERSION})
EOL
  printf "\nRunning CMake on ID project...\n"
  unset CMAKE_CXX
  if [ "${MACHINE_NAME}" == 'mac' ] && [ "${COMPILER_NAME}" == 'gcc' ]; then
    CMAKE_CXX="CXX=g++-7"
  elif [ "${COMPILER_NAME}" == 'intel' ]; then
    CMAKE_CXX="CXX=icpc"
  fi
  cmd "cd ${AMR_WIND_DIR}/build/id/build && ${CMAKE_CXX} cmake .."
  ID_FILE=$(cat ${AMR_WIND_DIR}/build/id/build/id.txt)

  printf "\nID_FILE contains: ${ID_FILE}\n"

  printf "\nCopying fcompare golds to organized directory...\n"
  cmd "mkdir -p ${AMR_WIND_TESTING_ROOT_DIR}/temp_golds/${ID_FILE}"
  (set -x; rsync -avm --include="*/" --include="plt00010**" --exclude="*" ${AMR_WIND_DIR}/build/test/test_files/ ${AMR_WIND_TESTING_ROOT_DIR}/temp_golds/${ID_FILE}/)
  # This only works on Linux
  #(set -x; cd ${AMR_WIND_DIR}/build/test/test_files && find . -type d -name *plt00010* -exec cp -R --parents {} ${AMR_WIND_TESTING_ROOT_DIR}/temp_golds/${ID_FILE}/ \;)
  printf "\nCopying fextrema golds to organized directory...\n"
  (set -x; rsync -avm --include="*/" --include="*.ext.gold" --include="*.ext" --exclude="*" ${AMR_WIND_DIR}/build/test/test_files/ ${AMR_WIND_TESTING_ROOT_DIR}/temp_golds/${ID_FILE}/)
  # This only works on Linux
  #(set -x; cd ${AMR_WIND_DIR}/build/test/test_files && find . -type f -name *.ext -exec cp -R --parents {} ${AMR_WIND_TESTING_ROOT_DIR}/temp_golds/${ID_FILE}/ \;)

  printf "\n"
  printf "************************************************************\n"
  printf "Done testing AMR-Wind with:\n"
  printf "${COMPILER_ID}\n"
  printf "at $(date)\n"
  printf "************************************************************\n"
}

# Main function for assembling configurations to test
main() {
  printf "============================================================\n"
  printf "$(date)\n"
  printf "============================================================\n"
  printf "Job is running on ${HOSTNAME}\n"
  printf "============================================================\n"

  # Decide what machine we are on
  if [ "${NREL_CLUSTER}" == 'eagle' ]; then
    MACHINE_NAME=eagle
  elif [ $(hostname) == 'rhodes.hpc.nrel.gov' ]; then
    MACHINE_NAME=rhodes
  elif [ $(hostname) == 'jrood-31712s.nrel.gov' ]; then
    MACHINE_NAME=mac
  fi
    
  HOST_NAME="${MACHINE_NAME}.hpc.nrel.gov"
 
  # Set configurations to test for each machine
  declare -a CONFIGURATIONS
  #CONFIGURATION[n]='compiler_name:compiler_version:mpi_enabled:openmp_enabled:use_latest_amrex'
  if [ "${MACHINE_NAME}" == 'rhodes' ]; then
    CONFIGURATIONS[0]='gcc:7.4.0:true:false:false'
    CONFIGURATIONS[1]='gcc:4.9.4:true:false:false'
    CONFIGURATIONS[2]='intel:18.0.4:true:false:false'
    CONFIGURATIONS[3]='clang:7.0.1:true:false:false'
    CONFIGURATIONS[4]='gcc:7.4.0:true:false:true'
    NALU_WIND_TESTING_ROOT_DIR=/projects/ecp/exawind/nalu-wind-testing
    INTEL_COMPILER_MODULE=intel-parallel-studio/cluster.2018.4
  elif [ "${MACHINE_NAME}" == 'eagle' ]; then
    CONFIGURATIONS[0]='gcc:7.4.0:true:false:false'
    CONFIGURATIONS[1]='gcc:7.4.0:true:false:true'
    NALU_WIND_TESTING_ROOT_DIR=/projects/hfm/exawind/nalu-wind-testing
    INTEL_COMPILER_MODULE=intel-parallel-studio/cluster.2018.4
  elif [ "${MACHINE_NAME}" == 'mac' ]; then
    CONFIGURATIONS[0]='gcc:7.4.0:true:false:false'
    CONFIGURATIONS[1]='clang:9.0.0-apple:true:false:false'
    NALU_WIND_TESTING_ROOT_DIR=${HOME}/nalu-wind-testing
  else
    printf "\nMachine name not recognized.\n"
    exit 1
  fi
 
  AMR_WIND_TESTING_ROOT_DIR=${NALU_WIND_TESTING_ROOT_DIR}/amr-wind-testing
  AMR_WIND_DIR=${AMR_WIND_TESTING_ROOT_DIR}/amr-wind
  BUILD_TEST_DIR=${NALU_WIND_TESTING_ROOT_DIR}/build-test
  LOGS_DIR=${NALU_WIND_TESTING_ROOT_DIR}/logs
  GOLDS_DIR=${AMR_WIND_TESTING_ROOT_DIR}/golds
  cmd "export SPACK_ROOT=${NALU_WIND_TESTING_ROOT_DIR}/spack"
 
  printf "============================================================\n"
  printf "HOST_NAME: ${HOST_NAME}\n"
  printf "AMR_WIND_TESTING_ROOT_DIR: ${AMR_WIND_TESTING_ROOT_DIR}\n"
  printf "AMR_WIND_DIR: ${AMR_WIND_DIR}\n"
  printf "BUILD_TEST_DIR: ${BUILD_TEST_DIR}\n"
  printf "LOGS_DIR: ${LOGS_DIR}\n"
  printf "GOLDS_DIR: ${GOLDS_DIR}\n"
  printf "SPACK_ROOT: ${SPACK_ROOT}\n"
  printf "Testing configurations:\n"
  printf " compiler_name:compiler_version:mpi_enabled:openmp_enabled:list_of_tpls\n"
  for CONFIGURATION in "${CONFIGURATIONS[@]}"; do
    printf " ${CONFIGURATION}\n"
  done
  printf "============================================================\n"
 
  if [ ! -d "${AMR_WIND_TESTING_ROOT_DIR}" ]; then
    set -e
    printf "============================================================\n"
    printf "Top level testing directory doesn't exist.\n"
    printf "Creating everything from scratch...\n"
    printf "============================================================\n"

    printf "Creating top level testing directory...\n"
    cmd "mkdir -p ${AMR_WIND_TESTING_ROOT_DIR}"
 
    #printf "\nCloning Spack repo...\n"
    #cmd "git clone https://github.com/spack/spack.git ${SPACK_ROOT}"
 
    #printf "\nConfiguring Spack...\n"
    #cmd "git clone https://github.com/exawind/build-test.git ${BUILD_TEST_DIR}"
    #cmd "cd ${BUILD_TEST_DIR}/configs && ./setup-spack.sh"
 
    printf "\nCloning AMR-Wind repo...\n"
    cmd "git clone --recursive -b development https://github.com/Exawind/amr-wind.git ${AMR_WIND_DIR}"
    cmd "mkdir -p ${AMR_WIND_DIR}/build || true"

    #printf "\nMaking job output directory...\n"
    #cmd "mkdir -p ${LOGS_DIR}"

    printf "\nMaking golds archive directory...\n"
    cmd "mkdir -p ${GOLDS_DIR}"
 
    printf "============================================================\n"
    printf "Done setting up testing directory\n"
    printf "============================================================\n"
    set +e
  fi
 
  printf "\nLoading Spack...\n"
  cmd "source ${SPACK_ROOT}/share/spack/setup-env.sh"

  printf "\nMaking common directory across all tests in which to organize and save gold files...\n"
  if [ ! -z "${AMR_WIND_TESTING_ROOT_DIR}" ]; then
    cmd "mkdir -p ${AMR_WIND_TESTING_ROOT_DIR}/temp_golds"
  fi

  printf "\n"
  printf "============================================================\n"
  printf "Starting testing loops...\n"
  printf "============================================================\n"
 
  # Test AMR-Wind for the list of configurations
  for CONFIGURATION in "${CONFIGURATIONS[@]}"; do
    CONFIG=(${CONFIGURATION//:/ })
    COMPILER_NAME=${CONFIG[0]}
    COMPILER_VERSION=${CONFIG[1]}
    OPENMP_ENABLED=${CONFIG[3]}
    USE_LATEST_AMREX=${CONFIG[4]}

    printf "\nRemoving previous test log for uploading to CDash...\n"
    cmd "rm ${LOGS_DIR}/amr-wind-test-log.txt"
    printf "\n"
    (test_configuration) 2>&1 | tee -i ${LOGS_DIR}/amr-wind-test-log.txt
  done

  printf "============================================================\n"
  printf "Done with testing loops\n"
  printf "============================================================\n"
  printf "============================================================\n"
  printf "Final steps\n"
  printf "============================================================\n"

  printf "\nSaving gold files...\n"
  (set -x; tar -czf ${GOLDS_DIR}/amr_wind_golds-$(date +%Y-%m-%d-%H-%M).tar.gz -C ${AMR_WIND_TESTING_ROOT_DIR}/temp_golds .)

  printf "\nRemoving temporary golds...\n"
  if [ ! -z "${AMR_WIND_TESTING_ROOT_DIR}" ]; then
    cmd "rm -rf ${AMR_WIND_TESTING_ROOT_DIR}/temp_golds"
  fi

  if [ "${MACHINE_NAME}" == 'eagle' ] || [ "${MACHINE_NAME}" == 'rhodes' ]; then
    printf "\nSetting permissions...\n"
    cmd "chmod -R a+rX,go-w ${AMR_WIND_TESTING_ROOT_DIR}"
  fi

  if [ "${MACHINE_NAME}" == 'rhodes' ]; then
    printf "\nSetting group...\n"
    cmd "chgrp -R windsim ${AMR_WIND_TESTING_ROOT_DIR}"
  fi

  printf "============================================================\n"
  printf "Done!\n"
  printf "$(date)\n"
  printf "============================================================\n"
}

main "$@"
