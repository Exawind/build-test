#!/bin/bash -l

#PBS -N nalu_build_gcc
#PBS -l nodes=1:ppn=24,walltime=6:00:00
#PBS -A windFlowModeling
#PBS -q batch-h
#PBS -o $PBS_JOBNAME.log
#PBS -j oe
#PBS -W umask=002

#Script for installing a shared Nalu installation using Spack with GCC and Intel compiler

set -ex

{
module purge
module load gcc/5.2.0
module load python/2.7.8
} &> /dev/null

# Set root location of installation
ROOT_DIR=/projects/windFlowModeling/ExaWind/NaluSharedInstallation
mkdir -p ${ROOT_DIR}
chmod a+rX,go-w ${ROOT_DIR}
cd ${ROOT_DIR}

# Set spack location
export SPACK_ROOT=${ROOT_DIR}/spack
export NALUSPACK_ROOT=${ROOT_DIR}/NaluSpack

# Set up directory with Spack installation
printf "\n\nCloning Spack repo...\n\n"
git clone https://github.com/LLNL/spack.git ${SPACK_ROOT}
printf "\n\nCloning NaluSpack repo...\n\n"
git clone https://github.com/NaluCFD/NaluSpack.git ${NALUSPACK_ROOT}
printf "\n\nConfiguring Spack...\n\n"
cd ${NALUSPACK_ROOT}/spack_config
./copy_config.sh
printf "\n\nReloading Spack...\n\n"
. ${SPACK_ROOT}/share/spack/setup-env.sh

# Define TRILINOS and TPLS from a single location for all scripts
printf "\n\nSourcing tpls.sh...\n\n"
source ${NALUSPACK_ROOT}/spack_config/tpls.sh
TPLS="${TPLS} ^cmake@3.6.1 ^m4@1.4.17"

# Intel necessities
mkdir -p /scratch/${USER}/.tmp
export TMPDIR=/scratch/${USER}/.tmp

printf "\n\nInstalling with GCC...\n\n"
spack install binutils %gcc@5.2.0
. ${SPACK_ROOT}/share/spack/setup-env.sh
spack load binutils
spack install nalu %gcc@5.2.0 ${TRILINOS} ${TPLS}
spack install netcdf-fortran@4.4.3 %gcc ^/$(spack find -L netcdf %gcc | grep netcdf | awk -F" " '{print $1}') ^m4@1.4.17
spack unload binutils

printf "\n\nInstalling with Intel...\n\n"
spack install nalu %intel@16.0.2 ${TRILINOS} ${TPLS}
spack install netcdf-fortran@4.4.3 %intel ^/$(spack find -L netcdf %intel | grep netcdf | awk -F" " '{print $1}') ^m4@1.4.17

printf "\n\nSetting permissions...\n\n"
chmod -R a+rX,go-w ${ROOT_DIR}
