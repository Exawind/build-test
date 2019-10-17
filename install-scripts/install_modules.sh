#!/bin/bash -l

# Script for installation of ECP related compilers, utilities, and software on Eagle and Rhodes

#TYPE=compilers
#TYPE=utilities
TYPE=software

DATE=2019-10-08

set -e

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

if [ "${MACHINE}" == 'eagle' ]; then
  BASE_DIR=/nopt/nrel/ecom/hpacf
elif [ "${MACHINE}" == 'rhodes' ]; then
  BASE_DIR=/opt
else
  printf "\nMachine name not recognized.\n"
  exit 1
fi

INSTALL_DIR=${BASE_DIR}/${TYPE}/${DATE}

if [ "${TYPE}" == 'compilers' ] || [ "${TYPE}" == 'utilities' ]; then
  GCC_COMPILER_VERSION="4.8.5"
elif [ "${TYPE}" == 'software' ]; then
  GCC_COMPILER_VERSION="7.4.0"
fi
GCC_COMPILER_MODULE="gcc/${GCC_COMPILER_VERSION}"
INTEL_COMPILER_VERSION="18.0.4"
INTEL_COMPILER_MODULE="intel-parallel-studio/cluster.2018.4"
CLANG_COMPILER_VERSION="7.0.1"
CLANG_COMPILER_MODULE="llvm/${CLANG_COMPILER_VERSION}"

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

for COMPILER_NAME in gcc clang intel
do
  if [ ${COMPILER_NAME} == 'gcc' ]; then
    COMPILER_VERSION="${GCC_COMPILER_VERSION}"
  elif [ ${COMPILER_NAME} == 'intel' ]; then
    COMPILER_VERSION="${INTEL_COMPILER_VERSION}"
  elif [ ${COMPILER_NAME} == 'clang' ]; then
    COMPILER_VERSION="${CLANG_COMPILER_VERSION}"
  fi

  COMPILER_ID="${COMPILER_NAME}@${COMPILER_VERSION}"

  # Reset TRILINOS_PERCEPT variable
  cmd "source ${BUILD_TEST_DIR}/configs/shared-constraints.sh"

  # Load necessary modules
  printf "\nLoading modules...\n"
  cmd "module purge"
  cmd "module unuse ${MODULEPATH}"
  if [ "${TYPE}" == 'compilers' ] || [ "${TYPE}" == 'utilities' ]; then
    cmd "module use ${BASE_DIR}/utilities/modules"
  elif [ "${TYPE}" == 'software' ]; then
    cmd "module use ${BASE_DIR}/compilers/modules-${DATE}"
    cmd "module use ${BASE_DIR}/utilities/modules-${DATE}"
    if [ ${COMPILER_NAME} == 'gcc' ]; then
      cmd "module load ${GCC_COMPILER_MODULE}"
    elif [ ${COMPILER_NAME} == 'intel' ]; then
      cmd "module load ${GCC_COMPILER_MODULE}"
      cmd "module load ${INTEL_COMPILER_MODULE}"
    elif [ ${COMPILER_NAME} == 'clang' ]; then
      cmd "module load ${CLANG_COMPILER_MODULE}"
    fi
  fi
  #for MODULE in unzip patch bzip2 cmake git texinfo flex bison wget bc python; do
  for MODULE in bzip2 cmake git texinfo flex bison wget python; do
    cmd "module load ${MODULE}"
  done
  cmd "source ${SPACK_ROOT}/share/spack/setup-env.sh"
  cmd "module list"

  if [ "${MACHINE}" == 'eagle' ]; then
    printf "\nMaking and setting TMPDIR to disk...\n"
    cmd "mkdir -p /scratch/${USER}/.tmp"
    cmd "export TMPDIR=/scratch/${USER}/.tmp"
  fi

  if [ "${TYPE}" == 'compilers' ]; then
    if [ ${COMPILER_NAME} == 'gcc' ]; then
      printf "\nInstalling ${TYPE} using ${COMPILER_ID}...\n"
      # LLVM 8 requires > GCC 4 and we currently build the compilers with the system GCC 4.8.5
      for PACKAGE in binutils gcc@9.1.0 gcc@8.3.0 gcc@7.4.0 gcc@6.5.0 gcc@5.5.0 gcc@4.9.4 gcc@4.8.5 llvm@7.0.1+omp_tsan llvm@6.0.1+omp_tsan pgi@19.4+nvidia pgi@18.10+nvidia numactl; do
        cmd "spack install ${PACKAGE} %${COMPILER_ID}"
      done
      cmd "spack install intel-parallel-studio@cluster.2019.3+advisor+inspector+mkl+mpi+vtune %${COMPILER_ID}"
      cmd "spack install intel-parallel-studio@cluster.2018.4+advisor+inspector+mkl+mpi+vtune %${COMPILER_ID}"
      cmd "spack install intel-parallel-studio@cluster.2017.7+advisor+inspector+mkl+mpi+vtune %${COMPILER_ID}"
    fi
  elif [ "${TYPE}" == 'utilities' ]; then
    if [ ${COMPILER_NAME} == 'gcc' ]; then
      printf "\nInstalling ${TYPE} using ${COMPILER_ID}...\n"
      for PACKAGE in environment-modules unzip bc patch bzip2 flex bison curl wget cmake emacs vim git tmux screen global python@2.7.16 python@3.7.3 htop makedepend cppcheck texinfo stow zsh strace gdb rsync xterm ninja@kitware pkg-config; do
        cmd "spack install ${PACKAGE} %${COMPILER_ID}"
      done
      cmd "spack install texlive scheme=full %${COMPILER_ID}"
      # Remove gtkplus dependency from ghostscript
      cmd "spack install image-magick %${COMPILER_ID}"
      cmd "spack install libxml2+python %${COMPILER_ID}"
      #cmd "spack install gnuplot+X ^pango+X %${COMPILER_ID}"
      cmd "spack install gnuplot+wx ^pango+X %${COMPILER_ID}"
      cmd "module load texinfo"
      cmd "module load texlive"
      cmd "module load flex"
      cmd "spack install flex@2.5.39 %${COMPILER_ID}"
      (set -x; spack install gnutls %${COMPILER_ID} ^/$(spack --color never find -L autoconf %${COMPILER_ID} | grep autoconf | cut -d " " -f1))
      if [ "${MACHINE}" != 'rhodes' ]; then
        cmd "spack install likwid %${COMPILER_ID}"
      fi
    fi
  elif [ "${TYPE}" == 'software' ]; then
    if [ ${COMPILER_NAME} == 'gcc' ]; then
      printf "\nInstalling ${TYPE} using ${COMPILER_ID}...\n"
      cmd "spack install osu-micro-benchmarks %${COMPILER_ID}"
      for PYTHON_VERSION in '3.7.4'; do
        cmd "spack install python@${PYTHON_VERSION} %${COMPILER_ID}"
        for PYTHON_LIBRARY in py-numpy py-matplotlib py-pandas py-nose py-autopep8 py-flake8 py-jedi py-pip py-pyyaml py-rope py-seaborn py-sphinx py-yapf py-scipy py-yt~astropy; do
          cmd "spack install ${PYTHON_LIBRARY} ^python@${PYTHON_VERSION} %${COMPILER_ID}"
        done
      done
      cmd "spack install --only dependencies nalu-wind+openfast+tioga+hypre+fftw+catalyst %${COMPILER_ID} ^python@3.7.4 ^llvm@8.0.0+omp_tsan"
      (set -x; spack install netcdf-fortran@4.4.3 %${COMPILER_ID} ^/$(spack --color never find -L netcdf@4.6.1 %${COMPILER_ID} ^hdf5+cxx+hl | grep netcdf | cut -d " " -f1))
      cmd "spack install percept %${COMPILER_ID}"
      cmd "spack install masa %${COMPILER_ID}"
      cmd "spack install valgrind %${COMPILER_ID}"
      if [ "${MACHINE}" == 'eagle' ]; then
        cmd "spack install amrvis+mpi dims=3 %${COMPILER_ID}"
        cmd "spack install amrvis+mpi+profiling dims=2 %${COMPILER_ID}"
        cmd "spack install cuda@10.1.168 %${COMPILER_ID}"
        cmd "spack install cuda@10.0.130 %${COMPILER_ID}"
        cmd "spack install cuda@9.2.88 %${COMPILER_ID}"
        cmd "spack install cudnn@7.5.1-10.1-x86_64 %${COMPILER_ID}"
        cmd "spack install libfabric %${COMPILER_ID}"
      fi
      #cmd "spack install paraview+mpi+python+osmesa %${COMPILER_ID}"
      #cmd "spack install petsc %${COMPILER_ID}"
    elif [ ${COMPILER_NAME} == 'intel' ]; then
      printf "\nInstalling ${TYPE} using ${COMPILER_ID}...\n"
      cmd "spack install --only dependencies nalu-wind+openfast+tioga+hypre+fftw %${COMPILER_ID} ^intel-mpi ^intel-mkl"
      cmd "spack install osu-micro-benchmarks %${COMPILER_ID} ^intel-mpi"
    elif [ ${COMPILER_NAME} == 'clang' ]; then
      printf "\nInstalling ${TYPE} using ${COMPILER_ID}...\n"
      cmd "spack install --only dependencies nalu-wind+openfast+tioga+hypre+fftw %${COMPILER_ID}"
      cmd "spack install osu-micro-benchmarks %${COMPILER_ID}"
    fi
  fi

  cmd "unset TMPDIR"

  printf "\nDone installing ${TYPE} with ${COMPILER_ID} at $(date).\n"
done

printf "\nSetting permissions...\n"
if [ "${MACHINE}" == 'eagle' ]; then
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

# Last step for compilers
# Edit compilers.yaml.software to point to all compilers this script installed
# Edit intel-parallel-studio modules to set INTEL_LICENSE_FILE correctly
# Edit pgi modules to set PGROUPD_LICENSE_FILE correctly
# It's possible the PGI compiler needs a libnuma.so.1.0.0 copied into its lib directory and symlinked to libnuma.so and libnuma.so.1
# Copy libnuma.so.1.0.0 into PGI lib directory and symlink to libnuma.so and libnuma.so.1
# Run makelocalrc for all PGI compilers (I think this sets a GCC to use as a frontend)
# I did something like:
# makelocalrc -gcc /nopt/nrel/ecom/hpacf/compilers/2019-05-08/spack/opt/spack/linux-centos7-x86_64/gcc-4.8.5/gcc-7.4.0-srw2azby5tn7wozbchryvj5ak3zlfz3r/bin/gcc -gpp /nopt/nrel/ecom/hpacf/compilers/2019-05-08/spack/opt/spack/linux-centos7-x86_64/gcc-4.8.5/gcc-7.4.0-srw2azby5tn7wozbchryvj5ak3zlfz3r/bin/g++ -g77 /nopt/nrel/ecom/hpacf/compilers/2019-05-08/spack/opt/spack/linux-centos7-x86_64/gcc-4.8.5/gcc-7.4.0-srw2azby5tn7wozbchryvj5ak3zlfz3r/bin/gfortran -x
# Add set PREOPTIONS=-D__GCC_ATOMIC_TEST_AND_SET_TRUEVAL=1; to localrc

# Other final manual customizations:
# - Rename necessary module files and set defaults
