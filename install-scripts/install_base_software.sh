#!/bin/bash -l

# Script for installation of ECP related software on Eagle, Peregrine, and Rhodes

set -e
TYPE=software

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

#el3 - mpich 3.3
DATE=2019-05-08

#el1 - mpich 3.3
#DATE=2019-01-10

#ed1 - ompi 1.10.7
#DATE=2019-01-02

#ed1 - ompi 3.1.3 mostly static builds
#DATE=2018-12-07

#ed1 - ompi 3.1.3
#DATE=2018-11-21
 
if [ "${MACHINE}" == 'eagle' ] || [ "${MACHINE}" == 'peregrine' ]; then
  INSTALL_DIR=/nopt/nrel/ecom/hpacf/${TYPE}/${DATE}
  GCC_COMPILER_VERSION="7.4.0"
  GCC_COMPILER_MODULE="gcc/7.4.0"
  INTEL_COMPILER_VERSION="18.0.4"
  INTEL_COMPILER_MODULE="intel-parallel-studio/cluster.2018.4"
  CLANG_COMPILER_VERSION="7.0.1"
elif [ "${MACHINE}" == 'rhodes' ]; then
  INSTALL_DIR=/opt/${TYPE}/${DATE}
  GCC_COMPILER_VERSION="7.4.0"
  GCC_COMPILER_MODULE="gcc/7.4.0"
  INTEL_COMPILER_VERSION="18.0.4"
  INTEL_COMPILER_MODULE="intel-parallel-studio/cluster.2018.4"
  CLANG_COMPILER_VERSION="7.0.1"
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

for COMPILER_NAME in gcc intel
do
  if [ ${COMPILER_NAME} == 'gcc' ]; then
    COMPILER_VERSION="${GCC_COMPILER_VERSION}"
  elif [ ${COMPILER_NAME} == 'intel' ]; then
    COMPILER_VERSION="${INTEL_COMPILER_VERSION}"
  elif [ ${COMPILER_NAME} == 'clang' ]; then
    COMPILER_VERSION="${CLANG_COMPILER_VERSION}"
  fi
  printf "\nInstalling base ${TYPE} with ${COMPILER_NAME}@${COMPILER_VERSION} at $(date).\n"

  # Reset TRILINOS_PERCEPT variable
  cmd "source ${BUILD_TEST_DIR}/configs/shared-constraints.sh"

  printf "\nLoading modules...\n"
  if [ "${MACHINE}" == 'eagle' ] || [ "${MACHINE}" == 'peregrine' ]; then
    cmd "module purge"
    cmd "module unuse ${MODULEPATH}"
    cmd "module use /nopt/nrel/ecom/hpacf/compilers/modules-${DATE}"
    cmd "module use /nopt/nrel/ecom/hpacf/utilities/modules-${DATE}"
    cmd "module load ${GCC_COMPILER_MODULE}"
    if [ ${COMPILER_NAME} == 'intel' ]; then
      cmd "module load ${INTEL_COMPILER_MODULE}"
    fi
    cmd "module load git"
    cmd "module load python"
    cmd "module load curl"
    cmd "module load binutils"
    printf "\nMaking and setting TMPDIR to disk...\n"
    cmd "mkdir -p /scratch/${USER}/.tmp"
    cmd "export TMPDIR=/scratch/${USER}/.tmp"
  elif [ "${MACHINE}" == 'rhodes' ]; then
    cmd "module unuse ${MODULEPATH}"
    cmd "module use /opt/compilers/modules-${DATE}"
    cmd "module use /opt/utilities/modules-${DATE}"
    cmd "module purge"
    cmd "module load ${GCC_COMPILER_MODULE}"
    if [ ${COMPILER_NAME} == 'intel' ]; then
      cmd "module load ${INTEL_COMPILER_MODULE}"
    fi
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
    cmd "source ${SPACK_ROOT}/share/spack/setup-env.sh"
  fi
  cmd "module list"

  if [ ${COMPILER_NAME} == 'gcc' ]; then
    # Install our own python
    printf "\nInstalling Python using ${COMPILER_NAME}@${COMPILER_VERSION}...\n"
    for PYTHON_VERSION in '2.7.16' '3.7.3'; do
      cmd "spack install python@${PYTHON_VERSION} %${COMPILER_NAME}@${COMPILER_VERSION}"
      for PYTHON_LIBRARY in py-numpy py-matplotlib py-pandas py-nose py-autopep8 py-flake8 py-jedi py-pip py-pyyaml py-rope py-seaborn py-sphinx py-yapf py-scipy py-yt~astropy; do
        cmd "spack install ${PYTHON_LIBRARY} ^python@${PYTHON_VERSION} %${COMPILER_NAME}@${COMPILER_VERSION}"
      done
    done

    printf "\nInstalling Nalu-Wind stuff using ${COMPILER_NAME}@${COMPILER_VERSION}...\n"
    cmd "spack install --only dependencies nalu-wind+openfast+tioga+hypre+fftw+catalyst %${COMPILER_NAME}@${COMPILER_VERSION}"

    (set -x; spack install netcdf-fortran@4.4.3 %${COMPILER_NAME}@${COMPILER_VERSION} ^/$(spack find -L netcdf@4.6.1 %${COMPILER_NAME}@${COMPILER_VERSION} ^hdf5+cxx+hl | grep netcdf | awk -F" " '{print $1}' | sed -r "s/\x1B\[([0-9]{1,2}(;[0-9]{1,2})?)?[mGK]//g"))
    # It seems something has changed in the percept repo, and I need to update percept in spack
    #cmd "spack install percept %${COMPILER_NAME}@${COMPILER_VERSION} ^${TRILINOS_PERCEPT}@12.12.1 ^netcdf@4.3.3.1 ^hdf5@1.8.16 ^boost@1.60.0 ^parallel-netcdf@1.6.1"
    cmd "spack install masa %${COMPILER_NAME}@${COMPILER_VERSION}"
    cmd "spack install valgrind %${COMPILER_NAME}@${COMPILER_VERSION}"
    cmd "spack install osu-micro-benchmarks %${COMPILER_NAME}@${COMPILER_VERSION}"
    if [ "${MACHINE}" == 'eagle' ]; then
      cmd "spack install amrvis+mpi dims=3 %${COMPILER_NAME}@${COMPILER_VERSION}"
      cmd "spack install amrvis+mpi+profiling dims=2 %${COMPILER_NAME}@${COMPILER_VERSION}"
      cmd "spack install cuda@10.0.130 %${COMPILER_NAME}@${COMPILER_VERSION}"
      cmd "spack install cuda@9.2.88 %${COMPILER_NAME}@${COMPILER_VERSION}"
      cmd "spack install cudnn %${COMPILER_NAME}@${COMPILER_VERSION}"
    fi
    #cmd "spack install paraview+mpi+python+osmesa %${COMPILER_NAME}@${COMPILER_VERSION}"
    #cmd "spack install petsc %${COMPILER_NAME}@${COMPILER_VERSION}"
  elif [ ${COMPILER_NAME} == 'intel' ]; then
    printf "\nInstalling Nalu-Wind stuff using ${COMPILER_NAME}@${COMPILER_VERSION}...\n"
    cmd "spack install --only dependencies nalu-wind+openfast+tioga+hypre+fftw %${COMPILER_NAME}@${COMPILER_VERSION} ^intel-mpi ^intel-mkl"
    cmd "spack install osu-micro-benchmarks %${COMPILER_NAME}@${COMPILER_VERSION} ^intel-mpi"
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

# Other final manual customizations:
# - Rename necessary module files and set defaults
# - Use downloadable Paraview for dav node; add module
# - Use downloadable Visit for dav node; add module
# - Add visit server module manually, and add ld_library_path stuff to internallauncher
