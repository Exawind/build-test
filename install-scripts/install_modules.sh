#!/bin/bash -l

# Script for installation of ECP related compilers and utilities on Eagle and Rhodes

TYPE=compilers
#TYPE=utilities

DATE=2019-05-08

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
  INSTALL_DIR=/nopt/nrel/ecom/hpacf/${TYPE}/${DATE}
  GCC_COMPILER_VERSION="4.8.5"
elif [ "${MACHINE}" == 'rhodes' ]; then
  INSTALL_DIR=/opt/${TYPE}/${DATE}
  GCC_COMPILER_VERSION="4.8.5"
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

for COMPILER_NAME in gcc
do
  if [ ${COMPILER_NAME} == 'gcc' ]; then
    COMPILER_VERSION="${GCC_COMPILER_VERSION}"
  fi
  printf "\nInstalling ${TYPE} with ${COMPILER_NAME}@${COMPILER_VERSION} at $(date).\n"

  # Load necessary modules
  printf "\nLoading modules...\n"
  cmd "module purge"
  cmd "module unuse ${MODULEPATH}"
  if [ "${MACHINE}" == 'eagle' ]; then
    cmd "module use /nopt/nrel/ecom/hpacf/utilities/modules"
    for MODULE in git python curl; do
      cmd "module load ${MODULE}"
    done
    printf "\nMaking and setting TMPDIR to disk...\n"
    cmd "mkdir -p /scratch/${USER}/.tmp"
    cmd "export TMPDIR=/scratch/${USER}/.tmp"
  elif [ "${MACHINE}" == 'rhodes' ]; then
    cmd "module use /opt/utilities/modules"
    for MODULE in unzip patch bzip2 cmake git texinfo flex bison wget bc python; do
      cmd "module load ${MODULE}"
    done
    cmd "source ${SPACK_ROOT}/share/spack/setup-env.sh"
  fi
  cmd "module list"

  if [ "${TYPE}" == 'compilers' ]; then
    if [ ${COMPILER_NAME} == 'gcc' ]; then
      printf "\nInstalling ${TYPE} using ${COMPILER_NAME}@${COMPILER_VERSION}...\n"
      # LLVM 8 requires > GCC 4 and we currently build the compilers with the system GCC 4.8.5
      for PACKAGE in binutils gcc@9.1.0 gcc@8.3.0 gcc@7.4.0 gcc@6.5.0 gcc@5.5.0 gcc@4.9.4 gcc@4.8.5 llvm llvm@7.0.1 llvm@6.0.1 numactl; do
        cmd "spack install ${PACKAGE} %${COMPILER_NAME}@${COMPILER_VERSION}"
      done
      cmd "spack install intel-parallel-studio@cluster.2019.3+advisor+inspector+mkl+mpi+vtune %${COMPILER_NAME}@${COMPILER_VERSION}"
      cmd "spack install intel-parallel-studio@cluster.2018.4+advisor+inspector+mkl+mpi+vtune %${COMPILER_NAME}@${COMPILER_VERSION}"
      cmd "spack install intel-parallel-studio@cluster.2017.7+advisor+inspector+mkl+mpi+vtune %${COMPILER_NAME}@${COMPILER_VERSION}"
      # The PGI compilers need a libnuma.so.1.0.0 copied into its lib directory and symlinked to libnuma.so and libnuma.so.1
      cmd "spack install pgi@19.4+nvidia %${COMPILER_NAME}@${COMPILER_VERSION}"
      cmd "spack install pgi@18.10+nvidia %${COMPILER_NAME}@${COMPILER_VERSION}"
    fi
  elif [ "${TYPE}" == 'utilities' ]; then
    if [ ${COMPILER_NAME} == 'gcc' ]; then
      printf "\nInstalling ${TYPE} using ${COMPILER_NAME}@${COMPILER_VERSION}...\n"
      for PACKAGE in environment-modules unzip bc patch bzip2 flex bison curl wget cmake emacs vim git tmux screen global python@2.7.16 python@3.7.3 htop makedepend cppcheck texinfo stow zsh strace gdb rsync xterm ninja@kitware gnuplot; do
        cmd "spack install ${PACKAGE} %${COMPILER_NAME}@${COMPILER_VERSION}"
      done
      cmd "spack install texlive scheme=full %${COMPILER_NAME}@${COMPILER_VERSION}"
      # Remove gtkplus dependency from ghostscript
      cmd "spack install image-magick %${COMPILER_NAME}@${COMPILER_VERSION}"
      cmd "spack install libxml2+python %${COMPILER_NAME}@${COMPILER_VERSION}"
      cmd "module load texinfo"
      cmd "module load texlive"
      cmd "module load flex"
      cmd "spack install flex@2.5.39 %${COMPILER_NAME}@${COMPILER_VERSION}"
      (set -x; spack install gnutls %${COMPILER_NAME}@${COMPILER_VERSION} ^/$(spack --color never find -L autoconf %${COMPILER_NAME}@${COMPILER_VERSION} | grep autoconf | cut -d " " -f1))
      if [ "${MACHINE}" != 'rhodes' ]; then
        cmd "spack install likwid %${COMPILER_NAME}@${COMPILER_VERSION}"
      fi
    fi
  fi

  cmd "unset TMPDIR"

  printf "\nDone installing ${TYPE} with ${COMPILER_NAME}@${COMPILER_VERSION} at $(date).\n"
done

#printf "\nSetting permissions...\n"
#if [ "${MACHINE}" == 'eagle' ]; then
#  cmd "chmod -R a+rX,go-w ${INSTALL_DIR}"
#  cmd "chgrp -R n-ecom ${INSTALL_DIR}"
#elif [ "${MACHINE}" == 'rhodes' ]; then
#  cmd "chgrp windsim /opt"
#  cmd "chgrp windsim /opt/${TYPE}"
#  cmd "chgrp -R windsim ${INSTALL_DIR}"
#  cmd "chmod a+rX,go-w /opt"
#  cmd "chmod a+rX,go-w /opt/${TYPE}"
#  cmd "chmod -R a+rX,go-w ${INSTALL_DIR}"
#fi

printf "\n$(date)\n"
printf "\nDone!\n"

# Last step for compilers
# Edit compilers.yaml.software to point to all compilers this script installed
# Edit intel-parallel-studio modules to set INTEL_LICENSE_FILE correctly
# Edit pgi modules to set PGROUPD_LICENSE_FILE correctly
# Copy libnuma.so.1.0.0 into PGI lib directory and symlink to libnuma.so and libnuma.so.1
# Run makelocalrc for all PGI compilers (I think this sets a GCC to use as a frontend)
# I did something like:
# makelocalrc -gcc /nopt/nrel/ecom/hpacf/compilers/2019-05-08/spack/opt/spack/linux-centos7-x86_64/gcc-4.8.5/gcc-7.4.0-srw2azby5tn7wozbchryvj5ak3zlfz3r/bin/gcc -gpp /nopt/nrel/ecom/hpacf/compilers/2019-05-08/spack/opt/spack/linux-centos7-x86_64/gcc-4.8.5/gcc-7.4.0-srw2azby5tn7wozbchryvj5ak3zlfz3r/bin/g++ -g77 /nopt/nrel/ecom/hpacf/compilers/2019-05-08/spack/opt/spack/linux-centos7-x86_64/gcc-4.8.5/gcc-7.4.0-srw2azby5tn7wozbchryvj5ak3zlfz3r/bin/gfortran -x
# Add set PREOPTIONS=-D__GCC_ATOMIC_TEST_AND_SET_TRUEVAL=1; to localrc
