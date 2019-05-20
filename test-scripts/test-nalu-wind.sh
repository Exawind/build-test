#!/bin/bash -l

# Script for running nightly regression tests for Nalu-Wind on a particular set 
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
  printf "Testing Nalu-Wind with:\n"
  printf "${COMPILER_ID}\n"
  printf "OPENMP_ENABLED: ${OPENMP_ENABLED}\n"
  printf "trilinos@${TRILINOS_BRANCH}\n"
  printf "openfast@${OPENFAST_BRANCH}\n"
  printf "tioga@${TIOGA_BRANCH}\n"
  printf "LIST_OF_TPLS: ${LIST_OF_TPLS}\n"
  printf "at $(date)\n"
  printf "************************************************************\n"
  printf "\n"

  # Logic for building up some constraints for use on Spack commands
  GENERAL_CONSTRAINTS=''
  MPI_ID=''
  MPI_CONSTRAINTS=''
  BLAS_ID=''
  BLAS_CONSTRAINTS=''
  if [ "${COMPILER_NAME}" == 'gcc' ] || [ "${COMPILER_NAME}" == 'clang' ]; then
    # OpenMPI 3.1.3 hangs at run time unless it was built with GCC > 7.3.0
    # so we use an older OpenMPI for GCC 4.9.4.
    MPI_ID="openmpi"
    if [ "${COMPILER_VERSION}" == '4.9.4' ]; then
      MPI_ID="openmpi@1.10.7"
    fi
    if [ "${MACHINE_NAME}" == 'eagle' ]; then
      MPI_ID="openmpi@3.1.3"
    fi
  elif [ "${COMPILER_NAME}" == 'intel' ]; then
    # For intel, we want to build against intel-mpi and intel-mkl
    MPI_ID="intel-mpi"
    BLAS_ID="intel-mkl"
  fi
  if [ ! -z "${MPI_ID}" ]; then
    # Avoid listing plain openmpi without a version number
    if [ "${MPI_ID}" == 'openmpi' ]; then
      MPI_CONSTRAINTS=''
    else
      MPI_CONSTRAINTS="^${MPI_ID}"
    fi
  fi
  if [ ! -z "${BLAS_ID}" ]; then
    BLAS_CONSTRAINTS=" ^${BLAS_ID}"
  fi
  GENERAL_CONSTRAINTS="${MPI_CONSTRAINTS}${BLAS_CONSTRAINTS}"
  printf "Using constraints: ${GENERAL_CONSTRAINTS}\n\n"

  if [ "${MACHINE_NAME}" == 'rhodes' ]; then
    TRILINOS="trilinos"
  else
    # Define TRILINOS constraints and preferred variants from a single location for all scripts.
    cmd "source ${BUILD_TEST_DIR}/configs/shared-constraints.sh"
  fi

  cmd "cd ${NALU_WIND_TESTING_ROOT_DIR}"

  printf "\nLoading modules...\n"
  if [ "${MACHINE_NAME}" == 'rhodes' ]; then
    cmd "module purge"
    cmd "module unuse ${MODULEPATH}"
    cmd "module use /opt/compilers/modules"
    cmd "module use /opt/utilities/modules"
    cmd "module load unzip"
    cmd "module load patch"
    cmd "module load bzip2"
    cmd "module load git"
    cmd "module load flex"
    cmd "module load bison"
    cmd "module load wget"
    cmd "module load bc"
    cmd "module load python"
    cmd "module load cppcheck"
    cmd "module load binutils"
    if [ "${COMPILER_NAME}" == 'gcc' ]; then
      cmd "module load ${COMPILER_NAME}/${COMPILER_VERSION}"
    elif [ "${COMPILER_NAME}" == 'clang' ]; then
      cmd "module load llvm/${COMPILER_VERSION}"
    elif [ "${COMPILER_NAME}" == 'intel' ]; then
      cmd "module load ${INTEL_COMPILER_MODULE}"
    fi
  elif [ "${MACHINE_NAME}" == 'peregrine' ] || [ "${MACHINE_NAME}" == 'eagle' ]; then
    cmd "module purge"
    cmd "module unuse ${MODULEPATH}"
    cmd "module use /nopt/nrel/ecom/hpacf/compilers/modules"
    cmd "module use /nopt/nrel/ecom/hpacf/utilities/modules"
    cmd "module load python/2.7.15"
    cmd "module load git"
    cmd "module load cppcheck"
    cmd "module load binutils"
    if [ "${COMPILER_NAME}" == 'gcc' ]; then
      cmd "module load ${COMPILER_NAME}/${COMPILER_VERSION}"
    elif [ "${COMPILER_NAME}" == 'intel' ]; then
      cmd "module load ${INTEL_COMPILER_MODULE}"
    fi
    if [ "${MACHINE_NAME}" == 'eagle' ]; then
      cmd "module load cuda"
    fi
  fi

  # Enable or disable OpenMP in Trilinos
  if [ "${OPENMP_ENABLED}" == 'true' ]; then
    printf "\nOpenMP is enabled in Trilinos...\n"
  elif [ "${OPENMP_ENABLED}" == 'false' ]; then
    printf "\nOpenMP is disabled in Trilinos...\n"
    if [ "${MACHINE_NAME}" == 'rhodes' ]; then
      TRILINOS="${TRILINOS}~openmp"
    else
      TRILINOS=$(sed 's/+openmp/~openmp/g' <<<"${TRILINOS}")
    fi
  fi

  if [ "${MACHINE_NAME}" == 'mac' ]; then
    # Can't build STK as shared on Mac
    printf "\nDisabling shared build in Trilinos because STK doesn't build as shared on Mac...\n"
    TRILINOS=$(sed 's/+shared/~shared/g' <<<"${TRILINOS}")
  elif [ "${MACHINE_NAME}" == 'eagle' ]; then
    # Can't build Trilinos as shared with CUDA
    printf "\nDisabling shared build in Trilinos because we're testing with CUDA on Eagle...\n"
    TRILINOS="${TRILINOS}~shared"
  fi


  # Set the TMPDIR to disk so it doesn't run out of space
  if [ "${MACHINE_NAME}" == 'peregrine' ] || [ "${MACHINE_NAME}" == 'eagle' ]; then
    printf "\nMaking and setting TMPDIR to disk...\n"
    cmd "mkdir -p /scratch/${USER}/.tmp"
    cmd "export TMPDIR=/scratch/${USER}/.tmp"
  fi

  # Uninstall packages we want to track; it's an error if they don't exist yet, but a soft error
  printf "\nUninstalling Trilinos (this is fine to error when tests are first run or building Trilinos has previously failed)...\n"
  cmd "spack uninstall -a -y trilinos@${TRILINOS_BRANCH} %${COMPILER_ID} || true"
  #printf "\nUninstalling OpenFAST (this is fine to error when tests are first run or building OpenFAST has previously failed)...\n"
  #cmd "spack uninstall -a -y openfast %${COMPILER_ID} || true"
  #printf "\nUninstalling TIOGA (this is fine to error when tests are first run or building TIOGA has previously failed)...\n"
  #cmd "spack uninstall -a -y tioga %${COMPILER_ID} || true"

  # Update packages we want to track; it's an error if they don't exist yet, but a soft error
  printf "\nUpdating Trilinos (this is fine to error when tests are first run)...\n"
  cmd "spack cd ${TRILINOS}@${TRILINOS_BRANCH} %${COMPILER_ID} ${GENERAL_CONSTRAINTS} && pwd && git fetch --all && git reset --hard origin/${TRILINOS_BRANCH} && git clean -df && git status -uno || true"
  #printf "\nUpdating OpenFAST (this is fine to error when tests are first run)...\n"
  #cmd "spack cd openfast@${OPENFAST_BRANCH} %${COMPILER_ID} && pwd && git fetch --all && git reset --hard origin/${OPENFAST_BRANCH} && git clean -df && git status -uno || true"
  #printf "\nUpdating TIOGA (this is fine to error when tests are first run)...\n"
  #cmd "spack cd tioga@${TIOGA_BRANCH} %${COMPILER_ID} && pwd && git fetch --all && git reset --hard origin/${TIOGA_BRANCH} && git clean -df && git status -uno || true"
  cmd "cd ${NALU_WIND_TESTING_ROOT_DIR}" # Change directories to avoid any stale file handles

  TPL_VARIANTS=''
  TPL_CONSTRAINTS=''
  TPLS=(${LIST_OF_TPLS//;/ })
  for TPL in ${TPLS[*]}; do
    TPL_VARIANTS+="+${TPL}"
    if [ "${TPL}" == 'openfast' ] ; then
      TPL_CONSTRAINTS="^openfast@${OPENFAST_BRANCH} ${TPL_CONSTRAINTS}"
    fi
    if [ "${TPL}" == 'tioga' ] ; then
      TPL_CONSTRAINTS="^tioga@${TIOGA_BRANCH} ${TPL_CONSTRAINTS}"
    fi
    # Currently don't need any extra constraints for catalyst
    #if [ "${TPL}" == 'catalyst' ] ; then
    #  TPL_CONSTRAINTS="${TPL_CONSTRAINTS}"
    #fi
    # Currently don't need any extra constraints for hypre
    #if [ "${TPL}" == 'hypre' ] ; then
    #  TPL_CONSTRAINTS="${TPL_CONSTRAINTS}"
    #fi
    # Currently don't need any extra constraints for fftw
    #if [ "${TPL}" == 'fftw' ] ; then
    #  TPL_CONSTRAINTS="${TPL_CONSTRAINTS}"
    #fi
    # Currently don't need any extra constraints for cuda
    #if [ "${TPL}" == 'cuda' ] ; then
    #  TPL_CONSTRAINTS="${TPL_CONSTRAINTS}"
    #fi
  done

  if [ "${MACHINE_NAME}" != 'mac' ]; then
    cmd "module list"
  fi

  printf "\nInstalling Nalu-Wind dependencies using ${COMPILER_ID}...\n"
  cmd "spack install --dont-restage --keep-stage --only dependencies nalu-wind ${TPL_VARIANTS} %${COMPILER_ID} ^${TRILINOS}@${TRILINOS_BRANCH} ${TPL_CONSTRAINTS} ${GENERAL_CONSTRAINTS}"

  STAGE_DIR=$(spack location -S)
  if [ ! -z "${STAGE_DIR}" ]; then
    #Haven't been able to find another robust way to rm with exclude
    printf "\nRemoving all staged directories except Trilinos...\n"
    cmd "cd ${STAGE_DIR} && rm -rf a* b* c* d* e* f* g* h* i* j* k* l* m* n* o* p* q* r* s* tar* ti* u* v* w* x* y* z*"
    #printf "\nRemoving all staged directories except Trilinos and OpenFAST...\n"
    #cmd "cd ${STAGE_DIR} && rm -rf a* b* c* d* e* f* g* h* i* j* k* l* m* n* openmpi* p* q* r* s* tar* u* v* w* x* y* z*"
    #find ${STAGE_DIR}/ -maxdepth 0 -type d -not -name "trilinos*" -exec rm -r {} \;
  fi

  # Refresh available modules (this is only really necessary on the first run of this script
  # because cmake and openmpi will already have been built and module files registered in subsequent runs)
  cmd "source ${SPACK_ROOT}/share/spack/setup-env.sh"

  printf "\nLoading Spack modules into environment for CMake and MPI to use during CTest...\n"
  if [ "${MACHINE_NAME}" == 'mac' ]; then
    cmd "export PATH=$(spack location -i cmake %${COMPILER_ID})/bin:${PATH}"
    cmd "export PATH=$(spack location -i ${MPI_ID} %${COMPILER_ID})/bin:${PATH}"
  else
    cmd "spack load cmake %${COMPILER_ID}"
    cmd "spack load ${MPI_ID} %${COMPILER_ID}"
  fi

  printf "\nSetting variables to pass to CTest...\n"
  TRILINOS_DIR=$(spack location -i ${TRILINOS}@${TRILINOS_BRANCH} %${COMPILER_ID} ${GENERAL_CONSTRAINTS})
  YAML_DIR=$(spack location -i yaml-cpp %${COMPILER_ID})
  printf "TRILINOS_DIR=${TRILINOS_DIR}\n"
  printf "YAML_DIR=${YAML_DIR}\n"
  CMAKE_CONFIGURE_ARGS=''
  for TPL in ${TPLS[*]}; do
    if [ "${TPL}" == 'openfast' ]; then
      OPENFAST_DIR=$(spack location -i openfast %${COMPILER_ID})
      CMAKE_CONFIGURE_ARGS="-DENABLE_OPENFAST:BOOL=ON -DOpenFAST_DIR:PATH=${OPENFAST_DIR} ${CMAKE_CONFIGURE_ARGS}"
      printf "OPENFAST_DIR=${OPENFAST_DIR}\n"
    fi
    if [ "${TPL}" == 'tioga' ]; then
      TIOGA_DIR=$(spack location -i tioga %${COMPILER_ID})
      CMAKE_CONFIGURE_ARGS="-DENABLE_TIOGA:BOOL=ON -DTIOGA_DIR:PATH=${TIOGA_DIR} ${CMAKE_CONFIGURE_ARGS}"
      printf "TIOGA_DIR=${TIOGA_DIR}\n"
    fi
    if [ "${TPL}" == 'catalyst' ]; then
      cmd "spack load paraview %${COMPILER_ID}"
      cmd "spack load trilinos-catalyst-ioss-adapter %${COMPILER_ID}"
      cmd "spack load py-numpy %${COMPILER_ID}"
      CATALYST_ADAPTER_DIR=$(spack location -i trilinos-catalyst-ioss-adapter %${COMPILER_ID})
      CMAKE_CONFIGURE_ARGS="-DENABLE_PARAVIEW_CATALYST:BOOL=ON -DPARAVIEW_CATALYST_INSTALL_PATH:PATH=${CATALYST_ADAPTER_DIR} ${CMAKE_CONFIGURE_ARGS}"
      printf "CATALYST_ADAPTER_DIR=${CATALYST_ADAPTER_DIR}\n"
    fi
    if [ "${TPL}" == 'hypre' ]; then
      HYPRE_DIR=$(spack location -i hypre %${COMPILER_ID})
      CMAKE_CONFIGURE_ARGS="-DENABLE_HYPRE:BOOL=ON -DHYPRE_DIR:PATH=${HYPRE_DIR} ${CMAKE_CONFIGURE_ARGS}"
      printf "HYPRE_DIR=${HYPRE_DIR}\n"
    fi
    if [ "${TPL}" == 'fftw' ]; then
      FFTW_DIR=$(spack location -i fftw %${COMPILER_ID})
      CMAKE_CONFIGURE_ARGS="-DENABLE_FFTW:BOOL=ON -DFFTW_DIR:PATH=${FFTW_DIR} ${CMAKE_CONFIGURE_ARGS}"
      printf "FFTW_DIR=${FFTW_DIR}\n"
    fi
    if [ "${TPL}" == 'cuda' ]; then
      CMAKE_CONFIGURE_ARGS="-DENABLE_CUDA:BOOL=ON ${CMAKE_CONFIGURE_ARGS}"
    fi
  done

  # Set the extra identifiers for CDash build description
  EXTRA_BUILD_NAME="-${COMPILER_NAME}-${COMPILER_VERSION}-tr_${TRILINOS_BRANCH}"

  if [ ! -z "${NALU_WIND_DIR}" ]; then
    printf "\nCleaning Nalu-Wind directory...\n"
    cmd "cd ${NALU_WIND_DIR} && git reset --hard origin/master && git clean -df && git status -uno"
    cmd "cd ${NALU_WIND_DIR}/build && rm -rf ${NALU_WIND_DIR}/build/*"
    # Update all the submodules recursively in case the previous ctest update failed because of submodule updates
    cmd "cd ${NALU_WIND_DIR} && git submodule update --init --recursive"
  fi

  if [ "${OPENMP_ENABLED}" == 'true' ]; then
    printf "\nEnabling and setting OpenMP stuff...\n"
    CMAKE_CONFIGURE_ARGS="-DENABLE_OPENMP:BOOL=TRUE ${CMAKE_CONFIGURE_ARGS}"
    cmd "export OMP_NUM_THREADS=1"
    cmd "export OMP_PROC_BIND=false"
  elif [ "${OPENMP_ENABLED}" == 'false' ]; then
    printf "\nDisabling OpenMP in Nalu-Wind...\n"
    CMAKE_CONFIGURE_ARGS="-DENABLE_OPENMP:BOOL=FALSE ${CMAKE_CONFIGURE_ARGS}"
  fi

  # CUDA stuff for testing on Eagle
  if [ "${MACHINE_NAME}" == 'eagle' ]; then
    printf "\nSetting environment variables for Kokkos/CUDA...\n"
    cmd "export OMPI_MCA_opal_cuda_support=1"
    cmd "export EXAWIND_CUDA_WRAPPER=${TRILINOS_DIR}/bin/nvcc_wrapper"
    cmd "export CUDA_LAUNCH_BLOCKING=1"
    cmd "export CUDA_MANAGED_FORCE_DEVICE_ALLOC=1"
    cmd "export KOKKOS_ARCH=SKX,Volta70"
    cmd "export NVCC_WRAPPER_DEFAULT_COMPILER=${CXX}"
    cmd "export OMPI_CXX=${EXAWIND_CUDA_WRAPPER}"
    cmd "export CUDACXX=$(which nvcc)"
  fi

  # Run static analysis and let ctest know we have static analysis output
  if [ "${MACHINE_NAME}" == 'peregrine' ] || \
     [ "${MACHINE_NAME}" == 'mac' ] || \
     [ "${MACHINE_NAME}" == 'rhodes' ]; then
    printf "\nRunning cppcheck static analysis (Nalu-Wind not updated until after this step)...\n"
    cmd "rm ${LOGS_DIR}/nalu-wind-static-analysis.txt"
    cmd "cppcheck --enable=all --quiet -j 8 --output-file=${LOGS_DIR}/nalu-wind-static-analysis.txt -I ${NALU_WIND_DIR}/include ${NALU_WIND_DIR}/src"
    cmd "printf \"%s warnings\n\" \"$(wc -l < ${LOGS_DIR}/nalu-wind-static-analysis.txt | xargs echo -n)\" >> ${LOGS_DIR}/nalu-wind-static-analysis.txt"
    CTEST_ARGS="-DHAVE_STATIC_ANALYSIS_OUTPUT:BOOL=TRUE -DSTATIC_ANALYSIS_LOG=${LOGS_DIR}/nalu-wind-static-analysis.txt ${CTEST_ARGS}"
  fi

  # Unset the TMPDIR variable after building but before testing during ctest nightly script
  if [ "${MACHINE_NAME}" == 'peregrine' ] || [ "${MACHINE_NAME}" == 'eagle' ]; then
    CTEST_ARGS="-DUNSET_TMPDIR_VAR:BOOL=TRUE ${CTEST_ARGS}"
  fi

  # Turn on all warnings unless we're gcc 4.9.4
  if [ "${COMPILER_ID}" == 'gcc@4.9.4' ]; then
    CMAKE_CONFIGURE_ARGS="-DENABLE_ALL_WARNINGS:BOOL=FALSE ${CMAKE_CONFIGURE_ARGS}"
  else
    CMAKE_CONFIGURE_ARGS="-DENABLE_ALL_WARNINGS:BOOL=TRUE ${CMAKE_CONFIGURE_ARGS}"
  fi

  # Turn on address sanitizer for clang build on rhodes
  if [ "${COMPILER_NAME}" == 'clang' ] && [ "${MACHINE_NAME}" == 'rhodes' ]; then
    printf "\nSetting up address sanitizer in Clang...\n"
    export CXXFLAGS="-fsanitize=address -fno-omit-frame-pointer"
    printf "export CXXFLAGS=${CXX_FLAGS}\n"
    cmd "export ASAN_OPTIONS=detect_container_overflow=0"
    printf "Writing asan.supp file...\n"
    (set -x; printf "leak:libopen-pal\nleak:libmpi\nleak:libnetcdf" > ${NALU_WIND_DIR}/build/asan.supp)
    cmd "export LSAN_OPTIONS=suppressions=${NALU_WIND_DIR}/build/asan.supp"
    #CMAKE_CONFIGURE_ARGS="-DCMAKE_CXX_FLAGS:STRING=-fsanitize=address\ -fno-omit-frame-pointer ${CMAKE_CONFIGURE_ARGS}"
    #CMAKE_CONFIGURE_ARGS="-DCMAKE_LINKER=clang++ -DCMAKE_CXX_LINK_EXECUTABLE=clang++ -DCMAKE_CXX_FLAGS:STRING=\'-fsanitize=address -fno-omit-frame-pointer\' -DCMAKE_EXE_LINKER_FLAGS:STRING=-fsanitize=address ${CMAKE_CONFIGURE_ARGS}"
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

  printf "\nListing cmake and compilers that will be used in ctest...\n"
  cmd "which cmake"
  cmd "which ${MPI_CXX_COMPILER}"
  cmd "which ${MPI_C_COMPILER}"
  cmd "which ${MPI_FORTRAN_COMPILER}"
  if [ "${MACHINE_NAME}" == 'eagle' ]; then
    cmd "which orterun"
    ORTERUN=$(which orterun)
    CMAKE_CONFIGURE_ARGS="-DMPIEXEC_EXECUTABLE:STRING=${ORTERUN} -DMPIEXEC_NUMPROC_FLAG:STRING=-np ${CMAKE_CONFIGURE_ARGS}"
  else
    cmd "which mpiexec"
  fi

  CMAKE_CONFIGURE_ARGS="-DCMAKE_CXX_COMPILER:STRING=${MPI_CXX_COMPILER} -DCMAKE_C_COMPILER:STRING=${MPI_C_COMPILER} -DCMAKE_Fortran_COMPILER:STRING=${MPI_FORTRAN_COMPILER} -DMPI_CXX_COMPILER:STRING=${MPI_CXX_COMPILER} -DMPI_C_COMPILER:STRING=${MPI_C_COMPILER} -DMPI_Fortran_COMPILER:STRING=${MPI_FORTRAN_COMPILER} ${CMAKE_CONFIGURE_ARGS}"

  # Set essential arguments for ctest
  CTEST_ARGS="-DTESTING_ROOT_DIR=${NALU_WIND_TESTING_ROOT_DIR} -DNALU_DIR=${NALU_WIND_TESTING_ROOT_DIR}/nalu-wind -DTEST_LOG=${LOGS_DIR}/nalu-wind-test-log.txt -DHOST_NAME=${HOST_NAME} -DEXTRA_BUILD_NAME=${EXTRA_BUILD_NAME} ${CTEST_ARGS}"

  # Set essential arguments for the ctest cmake configure step
  CMAKE_CONFIGURE_ARGS="-DTrilinos_DIR:PATH=${TRILINOS_DIR} -DYAML_DIR:PATH=${YAML_DIR} -DCMAKE_BUILD_TYPE=RelWithDebInfo ${CMAKE_CONFIGURE_ARGS}"

  # Set looser diff tolerance for GCC 7.3.0 cases that have more optimization flags on
  if [ "${COMPILER_ID}" == 'gcc@7.4.0' ] && [ "${MACHINE_NAME}" != 'mac' ]; then
    CMAKE_CONFIGURE_ARGS="-DTEST_TOLERANCE:STRING=0.0005 ${CMAKE_CONFIGURE_ARGS}"
  fi

  # Allow OpenMPI to consider hardware threads as cpus and allow for oversubscription
  if [ "${COMPILER_NAME}" != 'intel' ]; then
    CMAKE_CONFIGURE_ARGS="-DMPIEXEC_PREFLAGS:STRING=--oversubscribe ${CMAKE_CONFIGURE_ARGS}"
  fi

  printf "\nRunning CTest at $(date)...\n"
  cmd "cd ${NALU_WIND_DIR}/build"
  if [ "${MACHINE_NAME}" != 'mac' ]; then
    cmd "module list"
  fi
  cmd "ctest ${CTEST_ARGS} -DCMAKE_CONFIGURE_ARGS=\"${CMAKE_CONFIGURE_ARGS}\" -VV -S ${NALU_WIND_DIR}/reg_tests/CTestNightlyScript.cmake"
  printf "Returned from CTest at $(date)\n"

  printf "\nSaving norms...\n"
  (set -x; find ${NALU_WIND_DIR}/build/reg_tests/test_files -type f -name *.norm | tar -czf ${NORMS_DIR}/norms${EXTRA_BUILD_NAME}-$(date +%Y-%m-%d-%H-%M).tar.gz -T -)

  printf "\n"
  printf "************************************************************\n"
  printf "Done testing Nalu-Wind with:\n"
  printf "${COMPILER_ID}\n"
  printf "OPENMP_ENABLED: ${OPENMP_ENABLED}\n"
  printf "trilinos@${TRILINOS_BRANCH}\n"
  printf "openfast@${OPENFAST_BRANCH}\n"
  printf "tioga@${TIOGA_BRANCH}\n"
  printf "LIST_OF_TPLS: ${LIST_OF_TPLS}\n"
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
  if [ "${NREL_CLUSTER}" == 'peregrine' ]; then
    MACHINE_NAME=peregrine
  elif [ "${NREL_CLUSTER}" == 'eagle' ]; then
    MACHINE_NAME=eagle
  fi
  if [ $(hostname) == 'rhodes.hpc.nrel.gov' ]; then
    MACHINE_NAME=rhodes
  elif [ $(hostname) == 'jrood-31712s.nrel.gov' ]; then
    MACHINE_NAME=mac
  fi
    
  HOST_NAME="${MACHINE_NAME}.hpc.nrel.gov"
 
  # Set configurations to test for each machine
  declare -a CONFIGURATIONS
  #CONFIGURATION[n]='compiler_name:compiler_version:openmp_enabled:trilinos_branch:openfast_branch:tioga_branch:list_of_tpls'
  if [ "${MACHINE_NAME}" == 'rhodes' ]; then
    CONFIGURATIONS[0]='gcc:7.4.0:false:develop:develop:master:fftw;tioga;hypre;openfast'
    CONFIGURATIONS[1]='gcc:7.4.0:false:master:develop:master:fftw;tioga;hypre;openfast'
    CONFIGURATIONS[2]='gcc:4.9.4:false:develop:develop:master:fftw;tioga;hypre;openfast'
    CONFIGURATIONS[3]='intel:18.0.4:false:develop:develop:master:fftw;tioga;hypre;openfast'
    CONFIGURATIONS[4]='clang:7.0.1:false:develop:develop:master:fftw;tioga;hypre;openfast'
    NALU_WIND_TESTING_ROOT_DIR=/projects/ecp/exawind/nalu-wind-testing
    INTEL_COMPILER_MODULE=intel-parallel-studio/cluster.2018.4
  elif [ "${MACHINE_NAME}" == 'peregrine' ]; then
    CONFIGURATIONS[0]='gcc:7.3.0:false:develop:develop:master:fftw;tioga;hypre;openfast'
    CONFIGURATIONS[1]='intel:18.0.4:false:develop:develop:master:fftw;tioga;hypre;openfast'
    NALU_WIND_TESTING_ROOT_DIR=/projects/windsim/exawind/nalu-wind-testing
    INTEL_COMPILER_MODULE=intel-parallel-studio/cluster.2018.4
  elif [ "${MACHINE_NAME}" == 'eagle' ]; then
    CONFIGURATIONS[0]='gcc:7.3.0:false:develop:develop:master:cuda'
    NALU_WIND_TESTING_ROOT_DIR=/projects/hfm/exawind/nalu-wind-testing
    INTEL_COMPILER_MODULE=intel-parallel-studio/cluster.2018.4
  elif [ "${MACHINE_NAME}" == 'mac' ]; then
    CONFIGURATIONS[0]='gcc:7.3.0:false:develop:develop:master:fftw;tioga;hypre;openfast'
    CONFIGURATIONS[1]='clang:9.0.0-apple:false:develop:develop:master:fftw;tioga;hypre;openfast'
    NALU_WIND_TESTING_ROOT_DIR=${HOME}/nalu-wind-testing
  else
    printf "\nMachine name not recognized.\n"
  fi
 
  NALU_WIND_DIR=${NALU_WIND_TESTING_ROOT_DIR}/nalu-wind
  BUILD_TEST_DIR=${NALU_WIND_TESTING_ROOT_DIR}/build-test
  LOGS_DIR=${NALU_WIND_TESTING_ROOT_DIR}/logs
  NORMS_DIR=${NALU_WIND_TESTING_ROOT_DIR}/norms
  cmd "export SPACK_ROOT=${NALU_WIND_TESTING_ROOT_DIR}/spack"
 
  printf "============================================================\n"
  printf "HOST_NAME: ${HOST_NAME}\n"
  printf "NALU_WIND_TESTING_ROOT_DIR: ${NALU_WIND_TESTING_ROOT_DIR}\n"
  printf "NALU_WIND_DIR: ${NALU_WIND_DIR}\n"
  printf "BUILD_TEST_DIR: ${BUILD_TEST_DIR}\n"
  printf "LOGS_DIR: ${LOGS_DIR}\n"
  printf "NORMS_DIR: ${NORMS_DIR}\n"
  printf "SPACK_ROOT: ${SPACK_ROOT}\n"
  printf "Testing configurations:\n"
  printf " compiler_name:compiler_version:openmp_enabled:trilinos_branch:openfast_branch:tioga_branch:list_of_tpls\n"
  for CONFIGURATION in "${CONFIGURATIONS[@]}"; do
    printf " ${CONFIGURATION}\n"
  done
  printf "============================================================\n"
 
  if [ ! -d "${NALU_WIND_TESTING_ROOT_DIR}" ]; then
    set -e
    printf "============================================================\n"
    printf "Top level testing directory doesn't exist.\n"
    printf "Creating everything from scratch...\n"
    printf "============================================================\n"

    printf "Creating top level testing directory...\n"
    cmd "mkdir -p ${NALU_WIND_TESTING_ROOT_DIR}"
 
    printf "\nCloning Spack repo...\n"
    cmd "git clone https://github.com/spack/spack.git ${SPACK_ROOT}"
    # Nalu-Wind v1.2.0 matching sha-1 for Spack
    # cmd "cd ${SPACK_ROOT} && git checkout d3e4e88bae2b3ddf71bf56da18fe510e74e020b2"
 
    printf "\nConfiguring Spack...\n"
    cmd "git clone https://github.com/exawind/build-test.git ${BUILD_TEST_DIR}"
    # Nalu-Wind v1.2.0 matching tag for build-test
    #cmd "cd ${BUILD_TEST_DIR} && git checkout v1.2.0"
    cmd "cd ${BUILD_TEST_DIR}/configs && ./setup-spack.sh"
 
    # Checkout Nalu-Wind and meshes submodule outside of Spack so ctest can build it itself
    printf "\nCloning Nalu-Wind repo...\n"
    cmd "git clone --recursive https://github.com/exawind/nalu-wind.git ${NALU_WIND_DIR}"
    cmd "mkdir -p ${NALU_WIND_DIR}/build"
    # Nalu-Wind v1.2.0 tag
    #cmd "cd ${NALU_WIND_DIR} && git checkout v1.2.0"
 
    printf "\nMaking job output directory...\n"
    cmd "mkdir -p ${LOGS_DIR}"

    printf "\nMaking norm archive directory...\n"
    cmd "mkdir -p ${NORMS_DIR}"
 
    printf "============================================================\n"
    printf "Done setting up testing directory\n"
    printf "============================================================\n"
    set +e
  fi
 
  printf "\nLoading Spack...\n"
  cmd "source ${SPACK_ROOT}/share/spack/setup-env.sh"

  printf "\n"
  printf "============================================================\n"
  printf "Starting testing loops...\n"
  printf "============================================================\n"
 
  # Test Nalu-Wind for the list of configurations
  for CONFIGURATION in "${CONFIGURATIONS[@]}"; do
    CONFIG=(${CONFIGURATION//:/ })
    COMPILER_NAME=${CONFIG[0]}
    COMPILER_VERSION=${CONFIG[1]}
    OPENMP_ENABLED=${CONFIG[2]}
    TRILINOS_BRANCH=${CONFIG[3]}
    OPENFAST_BRANCH=${CONFIG[4]}
    TIOGA_BRANCH=${CONFIG[5]}
    LIST_OF_TPLS=${CONFIG[6]}
 
    printf "\nRemoving previous test log for uploading to CDash...\n"
    cmd "rm ${LOGS_DIR}/nalu-wind-test-log.txt"
    (test_configuration) 2>&1 | tee -i ${LOGS_DIR}/nalu-wind-test-log.txt
  done

  printf "============================================================\n"
  printf "Done with testing loops\n"
  printf "============================================================\n"
  printf "============================================================\n"
  printf "Final steps\n"
  printf "============================================================\n"
 
  if [ "${MACHINE_NAME}" == 'peregrine' ] || \
     [ "${MACHINE_NAME}" == 'eagle' ] || \
     [ "${MACHINE_NAME}" == 'rhodes' ]; then
    printf "\nSetting permissions...\n"
    cmd "chmod -R a+rX,go-w ${NALU_WIND_TESTING_ROOT_DIR}"
  fi

  if [ "${MACHINE_NAME}" == 'rhodes' ]; then
    printf "\nSetting group...\n"
    cmd "chgrp -R windsim ${NALU_WIND_TESTING_ROOT_DIR}"
  fi

  printf "============================================================\n"
  printf "Done!\n"
  printf "$(date)\n"
  printf "============================================================\n"
}

main "$@"
