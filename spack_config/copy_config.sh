#!/bin/bash

#Script for copying the recommended configuration for Spack onto your system
#for building Nalu, be it on Peregrine, or a Mac

if [ -z "${SPACK_ROOT}" ]; then
    echo "SPACK_ROOT must be set first"
    exit 1
fi

set -ex

OS=`uname -s`

if [ ${OS} == 'Linux' ]; then
  MACHINE=`hostname -d`
elif [ ${OS} == 'Darwin' ]; then
  MACHINE=`hostname -f`
fi

if [ ${MACHINE} == 'hpc.nrel.gov' ]; then
  # Copy Peregrine-specific configuration for Spack
  cp config.yaml ${SPACK_ROOT}/etc/spack/
  #sed -i "s|    #- USERSCRATCH.*|    - /scratch/${USER}|g" ${SPACK_ROOT}/etc/spack/config.yaml
  cp packages.yaml ${SPACK_ROOT}/etc/spack/
  cp compilers.yaml ${SPACK_ROOT}/etc/spack/
  cp -R openmpi ${SPACK_ROOT}/var/spack/repos/builtin/packages/
fi

# Copy Nalu-specific configuration for Spack
cp -R nalu ${SPACK_ROOT}/var/spack/repos/builtin/packages/
cp -R nalu-trilinos ${SPACK_ROOT}/var/spack/repos/builtin/packages/
