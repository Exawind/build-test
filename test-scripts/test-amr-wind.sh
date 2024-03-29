#!/bin/bash -l

# Script for running nightly regression tests for AMR-Wind on a particular set 
# of machines with a list of configurations for each machine using Spack
# to satisfy dependencies and submitting results to CDash

# Function for printing and executing commands
cmd() {
  echo "+ $@"
  eval "$@"
}

# Function for testing a single configuration
test_configuration() {
  COMPILER_ID="${COMPILER_NAME}@${COMPILER_VERSION}"
  printf "************************************************************\n"
  printf "Testing AMR-Wind with:\n"
  printf "${COMPILER_ID}\n"
  printf "LIST_OF_TPLS: ${LIST_OF_TPLS}\n"
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
    if [ "${MACHINE_NAME}" == 'eagle' ]; then
      MPI_ID="mpt"
    fi
  elif [ "${COMPILER_NAME}" == 'intel' ]; then
    # For intel, we want to build against intel-mpi and intel-mkl
    MPI_ID="intel-mpi"
    BLAS_ID="intel-mkl"
  fi

  #CUDA version used for tests on Eagle
  CUDA_VERSION="10.2.89"

  cmd "cd ${AMR_WIND_TESTING_ROOT_DIR}"

  printf "\nLoading modules...\n"
  if [ "${MACHINE_NAME}" == 'rhodes' ]; then
    cmd "module purge"
    cmd "module unuse ${MODULEPATH}"
    cmd "module use /opt/compilers/modules-2020-07"
    cmd "module use /opt/utilities/modules-2020-07"
    cmd "module use /opt/software/modules-2020-07/gcc-8.4.0"
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
    cmd "module load python"
    cmd "module load py-matplotlib"
    cmd "module load py-six"
    cmd "module load py-numpy"
    cmd "module load py-cycler"
    cmd "module load py-python-dateutil"
    cmd "module load py-bottleneck"
    cmd "module load py-cython"
    cmd "module load py-nose"
    cmd "module load py-numexpr"
    cmd "module load py-packaging"
    cmd "module load py-pandas"
    cmd "module load py-pillow"
    cmd "module load py-pytz"
    cmd "module load py-setuptools"
    cmd "module load py-kiwisolver"
    cmd "module load py-pyparsing"
    cmd "module load texlive"
    if [ "${COMPILER_NAME}" == 'gcc' ]; then
      cmd "module load ${COMPILER_NAME}/${COMPILER_VERSION}"
    elif [ "${COMPILER_NAME}" == 'clang' ]; then
      cmd "module load gcc"
      cmd "module load llvm/${COMPILER_VERSION}"
    elif [ "${COMPILER_NAME}" == 'intel' ]; then
      cmd "module load gcc"
      cmd "module load ${INTEL_COMPILER_MODULE}"
    fi
  elif [ "${MACHINE_NAME}" == 'eagle' ]; then
    cmd "module purge"
    cmd "module unuse ${MODULEPATH}"
    cmd "module use /nopt/nrel/ecom/hpacf/compilers/modules-2020-07"
    cmd "module use /nopt/nrel/ecom/hpacf/utilities/modules-2020-07"
    cmd "module use /nopt/nrel/ecom/hpacf/software/modules-2020-07/gcc-8.4.0"
    cmd "module load git"
    cmd "module load binutils"
    cmd "module load cuda/${CUDA_VERSION}"
    cmd "module load cmake"
    cmd "module load rsync"
    cmd "module load python"
    cmd "module load py-matplotlib"
    cmd "module load py-six"
    cmd "module load py-numpy"
    cmd "module load py-python-dateutil"
    cmd "module load py-cycler"
    cmd "module load py-bottleneck"
    cmd "module load py-cython"
    cmd "module load py-nose"
    cmd "module load py-numexpr"
    cmd "module load py-packaging"
    cmd "module load py-pandas"
    cmd "module load py-pillow"
    cmd "module load py-pytz"
    cmd "module load py-setuptools"
    cmd "module load py-kiwisolver"
    cmd "module load py-pyparsing"
    cmd "module load texlive"
    if [ "${COMPILER_NAME}" == 'gcc' ]; then
      cmd "module load ${COMPILER_NAME}/${COMPILER_VERSION}"
      cmd "module load mpt"
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

  # Turn on TPLs
  TPLS=(${LIST_OF_TPLS//;/ })
  for TPL in ${TPLS[*]}; do
    if [ "${TPL}" == 'openfast' ]; then
      OPENFAST_DIR=$(spack location -i openfast %${COMPILER_ID})
      CMAKE_CONFIGURE_ARGS="-DAMR_WIND_ENABLE_OPENFAST:BOOL=ON -DOPENFAST_DIR:PATH=${OPENFAST_DIR} ${CMAKE_CONFIGURE_ARGS}"
      printf "OPENFAST_DIR=${OPENFAST_DIR}\n"
    fi
    if [ "${TPL}" == 'masa' ]; then
      (set -x; spack install masa %${COMPILER_ID} cxxflags='-std=c++11')
      MASA_DIR=$(spack location -i masa %${COMPILER_ID})
      CMAKE_CONFIGURE_ARGS="-DAMR_WIND_ENABLE_MASA:BOOL=ON -DMASA_DIR:PATH=${MASA_DIR} ${CMAKE_CONFIGURE_ARGS}"
      printf "MASA_DIR=${MASA_DIR}\n"
    fi
    if [ "${TPL}" == 'hypre' ]; then
      if [ "${MACHINE_NAME}" == 'eagle' ]; then
        cmd "spack install hypre+shared+cuda~int64 %${COMPILER_ID}"
        HYPRE_DIR=$(spack location -i hypre+shared+cuda~int64 %${COMPILER_ID})
      else
        HYPRE_DIR=$(spack location -i hypre %${COMPILER_ID})
      fi
      CMAKE_CONFIGURE_ARGS="-DAMR_WIND_ENABLE_HYPRE:BOOL=ON -DHYPRE_ROOT:PATH=${HYPRE_DIR} ${CMAKE_CONFIGURE_ARGS}"
      printf "HYPRE_DIR=${HYPRE_DIR}\n"
    fi
    if [ "${TPL}" == 'netcdf' ]; then
      #cmd "spack install netcdf-c %${COMPILER_ID}"
      NETCDF_DIR=$(spack location -i netcdf-c %${COMPILER_ID})
      CMAKE_CONFIGURE_ARGS="-DAMR_WIND_ENABLE_NETCDF:BOOL=ON -DNETCDF_DIR:PATH=${NETCDF_DIR} ${CMAKE_CONFIGURE_ARGS}"
      printf "NETCDF_DIR=${NETCDF_DIR}\n"
    fi
    #if [ "${TPL}" == 'tioga' ]; then
    #  TIOGA_DIR=$(spack location -i tioga %${COMPILER_ID})
    #  CMAKE_CONFIGURE_ARGS="-DENABLE_TIOGA:BOOL=ON -DTIOGA_DIR:PATH=${TIOGA_DIR} ${CMAKE_CONFIGURE_ARGS}"
    #  printf "TIOGA_DIR=${TIOGA_DIR}\n"
    #fi
  done

  # Set the extra identifiers for CDash build description
  EXTRA_BUILD_NAME="-${COMPILER_NAME}-${COMPILER_VERSION}"

  # Run static analysis and let ctest know we have static analysis output
  if [ "${MACHINE_NAME}" == 'rhodes' ] && [ "${COMPILER_ID}" == 'clang@10.0.0' ]; then
    cmd "cd ${AMR_WIND_DIR}/build && ln -s ${CPPCHECK_ROOT_DIR}/cfg/std.cfg"
    cmd "rm ${LOGS_DIR}/amr-wind-static-analysis.txt || true"
    printf "\nRunning cppcheck static analysis (AMR-Wind not updated until after this step)...\n"
    # Using a working directory for cppcheck makes analysis faster
    cmd "mkdir cppcheck-wd"
    # Cppcheck ignores -isystem directories, so we change them to regular -I include directories (with no spaces either)
    cmd "sed -i 's/isystem /I/g' compile_commands.json"
    cmd "cppcheck --template=gcc --inline-suppr --suppress=danglingTemporaryLifetime --suppress=unreadVariable --suppress=internalAstError --suppress=unusedFunction --suppress=unmatchedSuppression --std=c++14 --language=c++ --enable=all --project=compile_commands.json -j 32 --cppcheck-build-dir=cppcheck-wd -i ${AMR_WIND_DIR}/submods/amrex/Src -i ${AMR_WIND_DIR}/submods/googletest --output-file=cppcheck.txt"
    # Warnings in header files are unavoidable, so we filter out submodule headers after analysis
    cmd "awk -v nlines=2 '/submods\/amrex/ || /submods\/googletest/ {for (i=0; i<nlines; i++) {getline}; next} 1' < cppcheck.txt > cppcheck-warnings.txt"
    (set -x; cat cppcheck-warnings.txt | egrep 'information:|error:|performance:|portability:|style:|warning:' | sort | awk 'BEGIN{i=0}{print $0}{i++}END{print "Warnings: "i}' > ${LOGS_DIR}/amr-wind-static-analysis.txt)
    CTEST_ARGS="-DHAVE_STATIC_ANALYSIS_OUTPUT:BOOL=TRUE -DSTATIC_ANALYSIS_LOG=${LOGS_DIR}/amr-wind-static-analysis.txt ${CTEST_ARGS}"
  fi

  if [ ! -z "${AMR_WIND_DIR}" ]; then
    printf "\nCleaning AMR-Wind directory...\n"
    cmd "cd ${AMR_WIND_DIR} && git reset --hard origin/main && git clean -df && git status -uno"
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

  # Default cmake build type
  CMAKE_BUILD_TYPE=RelWithDebInfo

  # Turn on address sanitizer for clang build on rhodes
  if [ "${COMPILER_NAME}" == 'clang' ] && [ "${MACHINE_NAME}" == 'rhodes' ]; then
    printf "\nSetting up address sanitizer in Clang...\n"
    #printf "\nSetting up address sanitizer blacklist and compile flags...\n"
    #(set -x; printf "src:/opt/compilers/2019-05-08/spack/var/spack/stage/llvm-7.0.1-362a6wfkd7pmjvjpbfd7tpqpgfej7izt/llvm-7.0.1.src/projects/compiler-rt/lib/asan/asan_malloc_linux.cc" > ${AMR_WIND_DIR}/build/asan_blacklist.txt)
    #export CXXFLAGS="-fsanitize=address -fno-omit-frame-pointer -fsanitize-blacklist=${AMR_WIND_DIR}/build/asan_blacklist.txt"
    export CXXFLAGS="-fsanitize=address -fno-omit-frame-pointer"
    printf "export CXXFLAGS=${CXXFLAGS}\n"
    #printf "\nCurrently ignoring container overflows...\n"
    #cmd "export ASAN_OPTIONS=detect_container_overflow=0"
    printf "\nWriting asan.supp suppressions file...\n"
    (set -x; printf "leak:libstdc++.so\nleak:libopen-pal\nleak:libmpi\nleak:libmasa\nleak:libc++\nleak:hwloc_bitmap_alloc" > ${AMR_WIND_DIR}/build/asan.supp)
    cmd "export LSAN_OPTIONS=suppressions=${AMR_WIND_DIR}/build/asan.supp"
    # Can't run ASAN with optimization
    CMAKE_BUILD_TYPE=Debug
    CMAKE_CONFIGURE_ARGS="-DAMR_WIND_ENABLE_CLANG_TIDY:BOOL=ON ${CMAKE_CONFIGURE_ARGS}"
  fi

  # Explicitly set compilers to MPI compilers
  if [ "${COMPILER_NAME}" == 'gcc' ] || [ "${COMPILER_NAME}" == 'clang' ]; then
    CXX_COMPILER=mpicxx
    C_COMPILER=mpicc
    FORTRAN_COMPILER=mpifort
    if [ "${MACHINE_NAME}" == 'eagle' ]; then
      CXX_COMPILER=g++
      C_COMPILER=gcc
      FORTRAN_COMPILER=gfortran
    fi
  elif [ "${COMPILER_NAME}" == 'intel' ]; then
    CXX_COMPILER=mpiicpc
    C_COMPILER=mpiicc
    FORTRAN_COMPILER=mpiifort
  fi

  # Give CMake a hint to find Python3
  PYTHON_EXE=$(which python3)

  printf "\nListing cmake and compilers that will be used in ctest...\n"
  cmd "which ${CXX_COMPILER}"
  cmd "which ${C_COMPILER}"
  cmd "which ${FORTRAN_COMPILER}"
  cmd "which mpiexec"
  cmd "which cmake"

  # CMake configure arguments testing options
  CMAKE_CONFIGURE_ARGS="-DAMR_WIND_ENABLE_MPI:BOOL=ON -DCMAKE_CXX_COMPILER:STRING=${CXX_COMPILER} -DCMAKE_C_COMPILER:STRING=${C_COMPILER} -DCMAKE_Fortran_COMPILER:STRING=${FORTRAN_COMPILER} -DPYTHON_EXECUTABLE=${PYTHON_EXE} -DAMR_WIND_TEST_WITH_FCOMPARE:BOOL=ON -DCMAKE_BUILD_TYPE=${CMAKE_BUILD_TYPE} ${CMAKE_CONFIGURE_ARGS}"

  # Set CUDA stuff for Eagle
  if [ "${MACHINE_NAME}" == 'eagle' ]; then
    EXTRA_BUILD_NAME="-nvcc-${CUDA_VERSION}${EXTRA_BUILD_NAME}"
    CMAKE_CONFIGURE_ARGS="-DAMR_WIND_ENABLE_CUDA:BOOL=ON -DAMReX_CUDA_ARCH:STRING=7.0 -DBUILD_SHARED_LIBS:BOOL=FALSE -DGPUS_PER_NODE:STRING=2 ${CMAKE_CONFIGURE_ARGS}"
    CTEST_ARGS="-DUNSET_TMPDIR_VAR:BOOL=TRUE -DCTEST_DISABLE_OVERLAPPING_TESTS:BOOL=TRUE ${CTEST_ARGS}"
  fi

  # Set essential arguments for ctest
  CTEST_ARGS="-DTESTING_ROOT_DIR=${AMR_WIND_TESTING_ROOT_DIR} -DAMR_WIND_DIR=${AMR_WIND_DIR} -DTEST_LOG=${LOGS_DIR}/amr-wind-test-log.txt -DHOST_NAME=${HOST_NAME} -DEXTRA_BUILD_NAME=${EXTRA_BUILD_NAME} ${CTEST_ARGS}"

  # Allow for oversubscription in OpenMPI
  if [ "${COMPILER_NAME}" != 'intel' ] && [ "${MACHINE_NAME}" != 'eagle' ]; then
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
  #printf "\nCopying fextrema golds to organized directory...\n"
  #(set -x; rsync -avm --include="*/" --include="*.ext.gold" --include="*.ext" --exclude="*" ${AMR_WIND_DIR}/build/test/test_files/ ${AMR_WIND_TESTING_ROOT_DIR}/temp_golds/${ID_FILE}/)
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
  #CONFIGURATION[n]='compiler_name:compiler_version:use_latest_amrex'
  if [ "${MACHINE_NAME}" == 'rhodes' ]; then
    CONFIGURATIONS[0]='intel:18.0.4:false:netcdf;hypre;openfast'
    CONFIGURATIONS[1]='clang:10.0.0:false:netcdf;hypre;openfast;masa'
    CONFIGURATIONS[2]='gcc:8.4.0:true:netcdf;hypre;openfast;masa'
    CONFIGURATIONS[3]='gcc:8.4.0:false:netcdf;hypre;openfast;masa'
    NALU_WIND_TESTING_ROOT_DIR=/projects/ecp/exawind/nalu-wind-testing
    INTEL_COMPILER_MODULE=intel-parallel-studio/cluster.2018.4
  elif [ "${MACHINE_NAME}" == 'eagle' ]; then
    CONFIGURATIONS[0]='gcc:8.4.0:true:netcdf;hypre;openfast'
    CONFIGURATIONS[1]='gcc:8.4.0:false:netcdf;hypre;openfast'
    NALU_WIND_TESTING_ROOT_DIR=/projects/hfm/exawind/nalu-wind-testing
    INTEL_COMPILER_MODULE=intel-parallel-studio/cluster.2018.4
  #elif [ "${MACHINE_NAME}" == 'mac' ]; then
  #  CONFIGURATIONS[0]='gcc:7.4.0:false'
  #  CONFIGURATIONS[1]='clang:9.0.0-apple:false'
  #  NALU_WIND_TESTING_ROOT_DIR=${HOME}/nalu-wind-testing
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
  printf " compiler_name:compiler_version:use_latest_amrex\n"
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
    cmd "git clone --recursive -b main https://github.com/Exawind/amr-wind.git ${AMR_WIND_DIR}"
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
    USE_LATEST_AMREX=${CONFIG[2]}
    LIST_OF_TPLS=${CONFIG[3]}

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
