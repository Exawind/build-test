#!/bin/bash -l

# Script for installing all the base software in /opt on Rhodes

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
INSTALL_DIR=/opt/software/b

#Rhodes has almost *nothing* installed on it besides python and gcc
#so we are relying on Spack heavily as a non-root package manager here.
#Kind of annoying to use Spack to build tools Spack needs, but after
#the initial bootstrapping, we can now just rely on pure modules sans Spack
#to set up our environment and tools we need to build with Spack.

#Pure modules sans Spack (assuming the module init is alreay in .bashrc)
#export MODULE_PREFIX=/opt/software/module_prefix
#export PATH=${MODULE_PREFIX}/Modules/bin:${PATH}
#module() { eval $(${MODULE_PREFIX}/Modules/bin/modulecmd $(basename ${SHELL}) $*); }
#module use /opt/software/modules
cmd "module load unzip"
cmd "module load patch"
cmd "module load bzip2"
cmd "module load cmake"
cmd "module load git"
cmd "module load texinfo"
cmd "module load flex"
cmd "module load bison"
cmd "module load wget"
cmd "module load texlive"

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
  cmd "git clone https://github.com/exawind/build-test.git ${INSTALL_DIR}/build-test"
  cmd "cd ${INSTALL_DIR}/build-test/configs && ./setup-spack.sh"

  printf "============================================================\n"
  printf "Done setting up install directory.\n"
  printf "============================================================\n"
fi

# Load Spack after we know Spack is set up
printf "\nLoading Spack...\n"
cmd "source ${SPACK_ROOT}/share/spack/setup-env.sh"
cmd "source ${INSTALL_DIR}/build-test/configs/shared-constraints.sh"
cmd "export TRILINOS_BRANCH=develop"

printf "\n============================================================\n"
printf "Installing base software with ${COMPILER_NAME}@${COMPILER_VERSION} at $(date).\n"
printf "============================================================\n"

printf "\nBootstrapping Spack with environment-modules...\n"
#cmd "spack bootstrap"
cmd "spack install environment-modules %${COMPILER_NAME}@${COMPILER_VERSION}"
cmd "source ${SPACK_ROOT}/share/spack/setup-env.sh"

printf "\nInstalling and loading essential tools using ${COMPILER_NAME}@${COMPILER_VERSION}...\n"
cmd "spack install unzip %${COMPILER_NAME}@${COMPILER_VERSION}"
cmd "spack install bc %${COMPILER_NAME}@${COMPILER_VERSION}"
cmd "spack install patch %${COMPILER_NAME}@${COMPILER_VERSION}"
cmd "spack install bzip2 %${COMPILER_NAME}@${COMPILER_VERSION}"
cmd "spack install binutils %${COMPILER_NAME}@${COMPILER_VERSION}"
cmd "spack install cmake %${COMPILER_NAME}@${COMPILER_VERSION}"
cmd "spack install git %${COMPILER_NAME}@${COMPILER_VERSION}"
cmd "spack install flex %${COMPILER_NAME}@${COMPILER_VERSION}"
cmd "spack install bison %${COMPILER_NAME}@${COMPILER_VERSION}"
cmd "spack install texinfo %${COMPILER_NAME}@${COMPILER_VERSION}"
cmd "spack install wget %${COMPILER_NAME}@${COMPILER_VERSION}"
cmd "spack install curl %${COMPILER_NAME}@${COMPILER_VERSION}"

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
cmd "spack install likwid %${COMPILER_NAME}@${COMPILER_VERSION}"
cmd "spack install texlive scheme=full %${COMPILER_NAME}@${COMPILER_VERSION}"
cmd "spack install masa %${COMPILER_NAME}@${COMPILER_VERSION}"

# Install our own python
printf "\nInstalling Python using ${COMPILER_NAME}@${COMPILER_VERSION}...\n"
cmd "spack install python@2.7.14 %${COMPILER_NAME}@${COMPILER_VERSION}"
cmd "spack install python@3.6.5 %${COMPILER_NAME}@${COMPILER_VERSION}"
for PYTHON_VERSION in '2.7.14' '3.6.5'; do
  for PYTHON_LIBRARY in py-numpy py-matplotlib py-pandas py-scipy py-nose py-autopep8 py-flake8 py-jedi py-pip py-pyyaml py-rope py-seaborn py-sphinx py-yapf; do
    cmd "spack install ${PYTHON_LIBRARY} ^python@${PYTHON_VERSION} %${COMPILER_NAME}@${COMPILER_VERSION}"
  done
done

# Some stuff needed for Visit build script
cmd "spack install libxrender %${COMPILER_NAME}@${COMPILER_VERSION}"
cmd "spack install libxml2+python %${COMPILER_NAME}@${COMPILER_VERSION}"
cmd "spack install libxrandr %${COMPILER_NAME}@${COMPILER_VERSION}"
cmd "spack install libxi %${COMPILER_NAME}@${COMPILER_VERSION}"
cmd "spack install libxft %${COMPILER_NAME}@${COMPILER_VERSION}"
cmd "spack install libxcursor %${COMPILER_NAME}@${COMPILER_VERSION}"
cmd "spack install libxt %${COMPILER_NAME}@${COMPILER_VERSION}"
cmd "spack install glib %${COMPILER_NAME}@${COMPILER_VERSION}"
cmd "spack install glproto %${COMPILER_NAME}@${COMPILER_VERSION}"
cmd "spack install libxt %${COMPILER_NAME}@${COMPILER_VERSION}"
cmd "spack install mesa %${COMPILER_NAME}@${COMPILER_VERSION}"
cmd "spack install mesa-glu %${COMPILER_NAME}@${COMPILER_VERSION}"
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

# Install our own compilers
printf "\nInstalling compilers using ${COMPILER_NAME}@${COMPILER_VERSION}...\n"
cmd "spack install gcc@7.3.0 %${COMPILER_NAME}@${COMPILER_VERSION}"
cmd "spack install gcc@6.4.0 %${COMPILER_NAME}@${COMPILER_VERSION}"
cmd "spack install gcc@5.5.0 %${COMPILER_NAME}@${COMPILER_VERSION}"
cmd "spack install gcc@4.9.4 %${COMPILER_NAME}@${COMPILER_VERSION}"
cmd "spack install llvm %${COMPILER_NAME}@${COMPILER_VERSION}"
cmd "spack install intel-parallel-studio@cluster.2018.1+advisor+inspector+mkl+mpi+vtune threads=openmp %${COMPILER_NAME}@${COMPILER_VERSION}"

# Install Nalu-Wind with everything turned on
printf "\nInstalling Nalu-Wind dependencies using ${COMPILER_NAME}@${COMPILER_VERSION}...\n"
cmd "spack install --only dependencies nalu-wind+openfast+tioga+hypre+catalyst %${COMPILER_NAME}@${COMPILER_VERSION} ^${TRILINOS}@${TRILINOS_BRANCH} ^openfast@develop"
cmd "spack install --only dependencies nalu-wind+openfast+tioga+hypre+catalyst %${COMPILER_NAME}@${COMPILER_VERSION} build_type=Debug ^${TRILINOS}@${TRILINOS_BRANCH} build_type=Debug ^openfast@develop"

# Turn off OpenMP
TRILINOS=$(sed 's/+openmp/~openmp/g' <<<"${TRILINOS}")
cmd "spack install --only dependencies nalu-wind+openfast+tioga+hypre+catalyst %${COMPILER_NAME}@${COMPILER_VERSION} ^${TRILINOS}@${TRILINOS_BRANCH} ^openfast@develop"
cmd "spack install --only dependencies nalu-wind+openfast+tioga+hypre+catalyst %${COMPILER_NAME}@${COMPILER_VERSION} build_type=Debug ^${TRILINOS}@${TRILINOS_BRANCH} build_type=Debug ^openfast@develop"

printf "\nInstalling NetCDF Fortran using ${COMPILER_NAME}@${COMPILER_VERSION}...\n"
(set -x; spack install netcdf-fortran@4.4.3 %${COMPILER_NAME}@${COMPILER_VERSION} ^/$(spack find -L netcdf %${COMPILER_NAME}@${COMPILER_VERSION} ^hdf5+cxx | grep netcdf | awk -F" " '{print $1}' | sed -r "s/\x1B\[([0-9]{1,2}(;[0-9]{1,2})?)?[mGK]//g"))

printf "\nInstalling Percept using ${COMPILER_NAME}@${COMPILER_VERSION}...\n"
cmd "spack install percept %${COMPILER_NAME}@${COMPILER_VERSION} ^${TRILINOS_PERCEPT}@12.12.1 ^boost@1.60.0"

printf "\nInstalling Valgrind using ${COMPILER_NAME}@${COMPILER_VERSION}...\n"
cmd "spack install valgrind %${COMPILER_NAME}@${COMPILER_VERSION}"

printf "\nInstalling Paraview with GUI using ${COMPILER_NAME}@${COMPILER_VERSION}...\n"
cmd "spack install paraview+mpi+python+qt@5.4.1 %${COMPILER_NAME}@${COMPILER_VERSION}"

#Modify necessary module files
#Last thing to do is install VisIt with the build_visit script

printf "\n============================================================\n"
printf "Done installing base software with ${COMPILER_NAME}@${COMPILER_VERSION} at $(date).\n"
printf "============================================================\n"

printf "\nSetting permissions...\n"
cmd "chmod a+rX,go-w /opt"
cmd "chmod -R a+rX,go-w /opt/software"
cmd "chmod -R a+rX,go-w ${INSTALL_DIR}"
printf "\n$(date)\n"
printf "\nDone!\n"
printf "============================================================\n"
