#!/bin/bash -l

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

# Our base compiler on rhodes is gcc 4.8.5
COMPILER_NAME="gcc"
COMPILER_VERSION="4.8.5"

# Set installation directory
INSTALL_DIR=/opt/software/a

# Assuming we already have some necessary modules available
# from our login environment for installing a whole new set
# of software with Spack
cmd "module load unzip"
cmd "module load patch"
cmd "module load bzip2"
cmd "module load cmake"
cmd "module load git"

# Set spack location
export SPACK_ROOT=${INSTALL_DIR}/spack

if [ ! -d "${INSTALL_DIR}" ]; then
  printf "============================================================\n"
  printf "Software install directory doesn't exist.\n"
  printf "Creating everything from scratch...\n"
  printf "============================================================\n"

  printf "Creating top level install directory...\n"
  cmd "mkdir -p ${INSTALL_DIR}"

  printf "\nCloning Spack repo...\n"
  cmd "git clone https://github.com/spack/spack.git ${SPACK_ROOT}"

  printf "\nConfiguring Spack...\n"
  cmd "git clone https://github.com/NaluCFD/NaluSpack.git ${INSTALL_DIR}/NaluSpack"
  cmd "cd ${NALUSPACK_DIR}/spack_config && ./setup_spack.sh"

  printf "============================================================\n"
  printf "Done setting up install directory.\n"
  printf "============================================================\n"
fi

# Load Spack after we know Spack is setup
printf "\nLoading Spack...\n"
cmd "source ${SPACK_ROOT}/share/spack/setup-env.sh"

printf "\n============================================================\n"
printf "Installing base software with ${COMPILER_NAME}@${COMPILER_VERSION} at $(date).\n"
printf "============================================================\n"

#Rhodes has almost *nothing* installed on it besides python and gcc
#so we are relying on Spack heavily as a non-root package manager here.
#Kind of annoying to use Spack to build tools Spack needs.

printf "\nBootstrapping Spack with environment-modules...\n"
cmd "spack bootstrap"
cmd "source ${SPACK_ROOT}/share/spack/setup-env.sh"

printf "\nInstalling and loading essential tools using ${COMPILER_NAME}@${COMPILER_VERSION}...\n"
cmd "spack install unzip %${COMPILER_NAME}@${COMPILER_VERSION}"
cmd "spack install patch %${COMPILER_NAME}@${COMPILER_VERSION}"
cmd "spack install bzip2 %${COMPILER_NAME}@${COMPILER_VERSION}"
cmd "spack install binutils %${COMPILER_NAME}@${COMPILER_VERSION}"
cmd "spack install cmake %${COMPILER_NAME}@${COMPILER_VERSION}"
cmd "spack install git %${COMPILER_NAME}@${COMPILER_VERSION}"
#Don't seem to need binutils so far on rhodes
#cmd "spack load binutils %${COMPILER_NAME}@${COMPILER_VERSION}"

printf "\nInstalling other tools using ${COMPILER_NAME}@${COMPILER_VERSION}...\n"
cmd "spack install emacs %${COMPILER_NAME}@${COMPILER_VERSION}"
cmd "spack install vim %${COMPILER_NAME}@${COMPILER_VERSION}"
cmd "spack install tmux %${COMPILER_NAME}@${COMPILER_VERSION}"
cmd "spack install screen %${COMPILER_NAME}@${COMPILER_VERSION}"
cmd "spack install global %${COMPILER_NAME}@${COMPILER_VERSION}"
cmd "spack install gnuplot %${COMPILER_NAME}@${COMPILER_VERSION}"
cmd "spack install htop %${COMPILER_NAME}@${COMPILER_VERSION}"
cmd "spack install makedepend %${COMPILER_NAME}@${COMPILER_VERSION}"
cmd "spack install cppcheck %${COMPILER_NAME}@${COMPILER_VERSION}"
#cmd "spack install texlive scheme=full %${COMPILER_NAME}@${COMPILER_VERSION}"

# Install our own python
printf "\nInstalling Python using ${COMPILER_NAME}@${COMPILER_VERSION}...\n"
cmd "spack install python@2.7.14 %${COMPILER_NAME}@${COMPILER_VERSION}"
cmd "spack install python@3.6.3 %${COMPILER_NAME}@${COMPILER_VERSION}"
for PYTHON_VERSION in '2.7.14' '3.6.3'; do
  for PYTHON_LIBRARY in py-numpy py-matplotlib py-pandas py-scipy py-nose py-autopep8 py-flake8 py-jedi py-pip py-pyyaml py-rope py-seaborn py-sphinx py-yapf; do
    cmd "spack install ${PYTHON_LIBRARY} ^python@${PYTHON_VERSION} %${COMPILER_NAME}@${COMPILER_VERSION}"
  done
done

# Install our own compilers
printf "\nInstalling compilers using ${COMPILER_NAME}@${COMPILER_VERSION}...\n"
cmd "spack install gcc@7.3.0 %${COMPILER_NAME}@${COMPILER_VERSION}"
cmd "spack install gcc@6.4.0 %${COMPILER_NAME}@${COMPILER_VERSION}"
cmd "spack install gcc@5.5.0 %${COMPILER_NAME}@${COMPILER_VERSION}"
cmd "spack install gcc@4.9.4 %${COMPILER_NAME}@${COMPILER_VERSION}"
cmd "spack install llvm %${COMPILER_NAME}@${COMPILER_VERSION}"
#cmd "spack install intel-parallel-studio@cluster.2018.1+advisor+inspector+mkl+mpi+vtune threads=openmp %${COMPILER_NAME}@${COMPILER_VERSION}"

## Install Nalu with everything turned on
#cmd "spack install nalu+openfast+tioga+hypre+catalyst %${COMPILER_NAME}@${COMPILER_VERSION} ^${TRILINOS}@${TRILINOS_BRANCH}"
#cmd "spack install nalu+openfast+tioga+hypre+catalyst %${COMPILER_NAME}@${COMPILER_VERSION} build_type=Debug ^${TRILINOS}@${TRILINOS_BRANCH} build_type=Debug"

#printf "\nInstalling NetCDF Fortran using ${COMPILER_NAME}@${COMPILER_VERSION}...\n"
#(set -x; spack install netcdf-fortran@4.4.3 %${COMPILER_NAME}@${COMPILER_VERSION} ^/$(spack find -L netcdf %${COMPILER_NAME}@${COMPILER_VERSION} ^hdf5+cxx | grep netcdf | awk -F" " '{print $1}' | sed -r "s/\x1B\[([0-9]{1,2}(;[0-9]{1,2})?)?[mGK]//g"))
#
#printf "\nInstalling Percept using ${COMPILER_NAME}@${COMPILER_VERSION}...\n"
#cmd "spack install percept %${COMPILER_NAME}@${COMPILER_VERSION} ^${TRILINOS_PERCEPT}@12.12.1"
#
#printf "\nInstalling Valgrind using ${COMPILER_NAME}@${COMPILER_VERSION}...\n"
#cmd "spack install valgrind %${COMPILER_NAME}@${COMPILER_VERSION}"

# Set some version numbers
#COMPILER_NAME="intel"
#COMPILER_VERSION="18.0.1"

#Last thing to do is install VisIt with the build_visit script

printf "\n============================================================\n"
printf "Done installing base software with ${COMPILER_NAME}@${COMPILER_VERSION} at $(date).\n"
printf "============================================================\n"

printf "\nSetting permissions...\n"
cmd "chmod -R a+rX,go-w ${INSTALL_DIR}"
cmd "chmod g+w ${INSTALL_DIR}"
cmd "chmod g+w ${INSTALL_DIR}/spack"
cmd "chmod g+w ${INSTALL_DIR}/spack/opt"
cmd "chmod g+w ${INSTALL_DIR}/spack/opt/spack"
cmd "chmod -R g+w ${INSTALL_DIR}/spack/opt/spack/.spack-db"
printf "\n$(date)\n"
printf "\nDone!\n"
printf "============================================================\n"
