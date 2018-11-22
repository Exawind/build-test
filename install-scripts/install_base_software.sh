#!/bin/bash -l

#PBS -N install-base-software
#PBS -l nodes=1:ppn=24,walltime=4:00:00,feature=haswell
#PBS -A windsim
#PBS -q short
#PBS -j oe
#PBS -W umask=002

# Script for installation of ECP related software on Eagle, Peregrine, and Rhodes

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
 
if [ "${MACHINE}" == 'eagle' ]; then
  INSTALL_DIR=/nopt/nrel/ecom/hpacf/software/${DATE}
  GCC_COMPILER_VERSION="7.3.0"
  INTEL_COMPILER_VERSION="19.0.1"
  CLANG_COMPILER_VERSION="7.0.0"
elif [ "${MACHINE}" == 'peregrine' ]; then
  INSTALL_DIR=/nopt/nrel/ecom/hpacf/software/${DATE}
  GCC_COMPILER_VERSION="7.3.0"
  INTEL_COMPILER_VERSION="19.0.1"
  CLANG_COMPILER_VERSION="7.0.0"
elif [ "${MACHINE}" == 'rhodes' ]; then
  INSTALL_DIR=/opt/software/${DATE}
  GCC_COMPILER_VERSION="7.3.0"
  INTEL_COMPILER_VERSION="19.0.1"
  CLANG_COMPILER_VERSION="7.0.0"
else
  printf "\nMachine name not recognized.\n"
  exit 1
fi

TRILINOS_BRANCH=develop
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
  cmd "git clone https://github.com/exawind/build-test.git ${BUILD_TEST_DIR}"
  cmd "cd ${BUILD_TEST_DIR}/configs && ./setup-spack.sh"
  cmd "cp ${BUILD_TEST_DIR}/configs/machines/${MACHINE}/compilers.yaml.base ${SPACK_ROOT}/etc/spack/compilers.yaml"
  cmd "mkdir -p ${SPACK_ROOT}/etc/spack/licenses/intel"
  cmd "cp ${HOME}/save/license.lic ${SPACK_ROOT}/etc/spack/licenses/intel/"

  printf "============================================================\n"
  printf "Done setting up install directory.\n"
  printf "============================================================\n"
fi

printf "\nLoading Spack...\n"
cmd "source ${SPACK_ROOT}/share/spack/setup-env.sh"

for COMPILER_NAME in gcc #intel #clang
do
  if [ ${COMPILER_NAME} == 'gcc' ]; then
    COMPILER_VERSION="${GCC_COMPILER_VERSION}"
  elif [ ${COMPILER_NAME} == 'intel' ]; then
    COMPILER_VERSION="${INTEL_COMPILER_VERSION}"
  elif [ ${COMPILER_NAME} == 'clang' ]; then
    COMPILER_VERSION="${CLANG_COMPILER_VERSION}"
  fi
  printf "\nInstalling base software with ${COMPILER_NAME}@${COMPILER_VERSION} at $(date).\n"

  # Reset TRILINOS variable
  cmd "source ${INSTALL_DIR}/build-test/configs/shared-constraints.sh"

  printf "\nLoading modules...\n"
  if [ "${MACHINE}" == 'eagle' ]; then
    cmd "module purge"
    cmd "module load gcc/7.3.0"
    cmd "module list"
    printf "\nMaking and setting TMPDIR to disk...\n"
    cmd "mkdir -p ${HOME}/.tmp"
    cmd "export TMPDIR=${HOME}/.tmp"
  elif [ "${MACHINE}" == 'peregrine' ]; then
    cmd "module purge"
    cmd "module use /nopt/nrel/ecom/ecp/base/c/spack/share/spack/modules/linux-centos7-x86_64/gcc-6.2.0"
    cmd "module load gcc/6.2.0"
    cmd "module load git"
    cmd "module load python/2.7.15"
    cmd "module load curl"
    cmd "module load binutils"
    cmd "module load texinfo"
    cmd "module load texlive"
    cmd "module list"
    printf "\nMaking and setting TMPDIR to disk...\n"
    cmd "mkdir -p /scratch/${USER}/.tmp"
    cmd "export TMPDIR=/scratch/${USER}/.tmp"
  elif [ "${MACHINE}" == 'rhodes' ]; then
    module use /opt/software/modules
    cmd "module purge"
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
    cmd "module list"
    cmd "source ${SPACK_ROOT}/share/spack/setup-env.sh"
  fi

  if [ ${COMPILER_NAME} == 'gcc' ]; then
    #if [ "${MACHINE}" == 'rhodes' ]; then
      #printf "\nInstalling stuff needed for Visit ${COMPILER_NAME}@${COMPILER_VERSION}...\n"
      #cmd "spack install libxrender %${COMPILER_NAME}@${COMPILER_VERSION}"
      #cmd "spack install libxml2 %${COMPILER_NAME}@${COMPILER_VERSION}"
      #cmd "spack install libxrandr %${COMPILER_NAME}@${COMPILER_VERSION}"
      #cmd "spack install libxi %${COMPILER_NAME}@${COMPILER_VERSION}"
      #cmd "spack install libxft %${COMPILER_NAME}@${COMPILER_VERSION}"
      #cmd "spack install libxcursor %${COMPILER_NAME}@${COMPILER_VERSION}"
      #cmd "spack install libxt %${COMPILER_NAME}@${COMPILER_VERSION}"
      #cmd "spack install glib %${COMPILER_NAME}@${COMPILER_VERSION}"
      #cmd "spack install glproto %${COMPILER_NAME}@${COMPILER_VERSION}"
      #cmd "spack install libxt %${COMPILER_NAME}@${COMPILER_VERSION}"
      #cmd "spack install mesa %${COMPILER_NAME}@${COMPILER_VERSION}"
      #cmd "spack install mesa-glu %${COMPILER_NAME}@${COMPILER_VERSION}"
      #cmd "spack install xproto %${COMPILER_NAME}@${COMPILER_VERSION}"
      #cmd "spack install inputproto %${COMPILER_NAME}@${COMPILER_VERSION}"
      #cmd "spack install xextproto %${COMPILER_NAME}@${COMPILER_VERSION}"
      #cmd "spack install xcb-proto %${COMPILER_NAME}@${COMPILER_VERSION}"
      #cmd "spack install xtrans %${COMPILER_NAME}@${COMPILER_VERSION}"
      #cmd "spack install fontconfig %${COMPILER_NAME}@${COMPILER_VERSION}"
      #cmd "spack install freetype %${COMPILER_NAME}@${COMPILER_VERSION}"
      #cmd "spack install randrproto %${COMPILER_NAME}@${COMPILER_VERSION}"
      #cmd "spack install renderproto %${COMPILER_NAME}@${COMPILER_VERSION}"
      #cmd "spack install libx11 %${COMPILER_NAME}@${COMPILER_VERSION}"
      #cmd "spack install libxau %${COMPILER_NAME}@${COMPILER_VERSION}"
      #cmd "spack install libxcb %${COMPILER_NAME}@${COMPILER_VERSION}"
      #cmd "spack install libxcursor %${COMPILER_NAME}@${COMPILER_VERSION}"
      #cmd "spack install libxdamage %${COMPILER_NAME}@${COMPILER_VERSION}"
      #cmd "spack install libxdmcp %${COMPILER_NAME}@${COMPILER_VERSION}"
      #cmd "spack install libxext %${COMPILER_NAME}@${COMPILER_VERSION}"
      #cmd "spack install libxfixes %${COMPILER_NAME}@${COMPILER_VERSION}"
      #cmd "spack install libxft %${COMPILER_NAME}@${COMPILER_VERSION}"
      #cmd "spack install libxi %${COMPILER_NAME}@${COMPILER_VERSION}"
      #cmd "spack install libxpm %${COMPILER_NAME}@${COMPILER_VERSION}"
      #cmd "spack install libxrandr %${COMPILER_NAME}@${COMPILER_VERSION}"
      #cmd "spack install libxrender %${COMPILER_NAME}@${COMPILER_VERSION}"
      #cmd "spack install libxshmfence %${COMPILER_NAME}@${COMPILER_VERSION}"
      #cmd "spack install libxv %${COMPILER_NAME}@${COMPILER_VERSION}"
      #cmd "spack install libxvmc %${COMPILER_NAME}@${COMPILER_VERSION}"
    #fi

    # Install our own python
    printf "\nInstalling Python using ${COMPILER_NAME}@${COMPILER_VERSION}...\n"
    for PYTHON_VERSION in '2.7.15' '3.6.5'; do
      cmd "spack install python@${PYTHON_VERSION} %${COMPILER_NAME}@${COMPILER_VERSION}"
      for PYTHON_LIBRARY in py-numpy py-matplotlib py-pandas py-nose py-autopep8 py-flake8 py-jedi py-pip py-pyyaml py-rope py-seaborn py-sphinx py-yapf py-scipy py-yt; do
        cmd "spack install ${PYTHON_LIBRARY} ^python@${PYTHON_VERSION} %${COMPILER_NAME}@${COMPILER_VERSION}"
      done
    done

    printf "\nInstalling Nalu-Wind stuff using ${COMPILER_NAME}@${COMPILER_VERSION}...\n"
    cmd "spack install --only dependencies nalu-wind+openfast+tioga+hypre+catalyst %${COMPILER_NAME}@${COMPILER_VERSION} ^${TRILINOS}@${TRILINOS_BRANCH}"
    cmd "spack install --only dependencies --keep-stage nalu-wind+openfast+tioga+hypre+catalyst %${COMPILER_NAME}@${COMPILER_VERSION} build_type=Debug ^${TRILINOS}@${TRILINOS_BRANCH} build_type=Debug"
    TRILINOS=$(sed 's/+openmp/~openmp/g' <<<"${TRILINOS}")
    cmd "spack install --only dependencies nalu-wind+openfast+tioga+hypre+catalyst %${COMPILER_NAME}@${COMPILER_VERSION} ^${TRILINOS}@${TRILINOS_BRANCH}"
    cmd "spack install --only dependencies --keep-stage nalu-wind+openfast+tioga+hypre+catalyst %${COMPILER_NAME}@${COMPILER_VERSION} build_type=Debug ^${TRILINOS}@${TRILINOS_BRANCH} build_type=Debug"

    (set -x; spack --color never install netcdf-fortran@4.4.3 %${COMPILER_NAME}@${COMPILER_VERSION} ^/$(spack find -L netcdf@4.4.1.1 %${COMPILER_NAME}@${COMPILER_VERSION} ^hdf5+cxx+hl | grep netcdf | awk -F" " '{print $1}'))
    cmd "spack install percept %${COMPILER_NAME}@${COMPILER_VERSION} ^${TRILINOS_PERCEPT}@12.12.1 ^netcdf@4.3.3.1 ^hdf5@1.8.16 ^boost@1.60.0 ^parallel-netcdf@1.6.1"
    cmd "spack install masa %${COMPILER_NAME}@${COMPILER_VERSION}"
    cmd "spack install valgrind %${COMPILER_NAME}@${COMPILER_VERSION}"
    cmd "spack install paraview+mpi+python+osmesa %${COMPILER_NAME}@${COMPILER_VERSION}"
    cmd "spack install amrvis+mpi dims=3 %${COMPILER_NAME}@${COMPILER_VERSION}"
    cmd "spack install amrvis+mpi+profiling dims=2 %${COMPILER_NAME}@${COMPILER_VERSION}"
  elif [ ${COMPILER_NAME} == 'intel' ]; then
    printf "\nInstalling Nalu-Wind stuff using ${COMPILER_NAME}@${COMPILER_VERSION}...\n"
    cmd "spack install --only dependencies nalu-wind+openfast+tioga+hypre %${COMPILER_NAME}@${COMPILER_VERSION} ^${TRILINOS}@${TRILINOS_BRANCH} ^intel-mpi ^intel-mkl"
    TRILINOS=$(sed 's/+openmp/~openmp/g' <<<"${TRILINOS}")
    cmd "spack install --only dependencies nalu-wind+openfast+tioga+hypre %${COMPILER_NAME}@${COMPILER_VERSION} ^${TRILINOS}@${TRILINOS_BRANCH} ^intel-mpi ^intel-mkl"
  fi

  cmd "unset TMPDIR"

  printf "\nDone installing software with ${COMPILER_NAME}@${COMPILER_VERSION} at $(date).\n"
done

printf "\nSetting permissions...\n"
if [ "${MACHINE}" == 'eagle' ]; then
  cmd "chmod -R a+rX,go-w ${INSTALL_DIR}"
elif [ "${MACHINE}" == 'peregrine' ]; then
  cmd "chmod -R a+rX,go-w ${INSTALL_DIR}"
elif [ "${MACHINE}" == 'rhodes' ]; then
  cmd "chgrp windsim /opt"
  cmd "chgrp windsim /opt/software"
  cmd "chgrp -R windsim ${INSTALL_DIR}"
  cmd "chmod a+rX,go-w /opt"
  cmd "chmod a+rX,go-w /opt/software"
  cmd "chmod -R a+rX,go-w ${INSTALL_DIR}"
fi

printf "\n$(date)\n"
printf "\nDone!\n"

# Other final manual customizations:
# - Rename necessary module files and set defaults
# - Use downloadable Paraview for dav node; add module
# - Use downloadable Visit for dav node; add module
# - Add visit server module manually, and add ld_library_path stuff to internallauncher
