#!/bin/bash

#Script for copying the recommended configuration for Spack onto your system
#for building Nalu, be it on Peregrine, Merlin, or a Mac

if [ -z "${SPACK_ROOT}" ]; then
    echo "SPACK_ROOT must be set first"
    exit 1
fi

set -ex

OS=`uname -s`

if [ ${OS} == 'Linux' ]; then
  MYHOSTNAME=`hostname -d`
  if [ ${MYHOSTNAME} == 'localdomain' ]; then
    MACHINE=merlin
  elif [ ${MYHOSTNAME} == 'hpc.nrel.gov' ]; then
    MACHINE=peregrine
  elif [ -z "${MYHOSTNAME}" ]; then
    MYHOSTNAME=`hostname -f`
    if [ ${MYHOSTNAME} == 'merlin' ]; then
      MACHINE=merlin
    fi
  fi
elif [ ${OS} == 'Darwin' ]; then
  MACHINE=`hostname -f`
fi

if [ -z "${MACHINE}" ]; then
  echo "MACHINE name not found"
else
  echo "MYHOSTNAME is ${MYHOSTNAME}"
  echo "MACHINE is ${MACHINE}"
fi

if [ ${MACHINE} == 'hpc.nrel.gov' ]; then
  # Copy Peregrine-specific configuration for Spack
  cp config.yaml.peregrine ${SPACK_ROOT}/etc/spack/config.yaml
  #sed -i "s|    #- USERSCRATCH.*|    - /scratch/${USER}|g" ${SPACK_ROOT}/etc/spack/config.yaml
  cp packages.yaml.peregrine ${SPACK_ROOT}/etc/spack/packages.yaml
  cp compilers.yaml.peregrine ${SPACK_ROOT}/etc/spack/compilers.yaml
  cp -R openmpi ${SPACK_ROOT}/var/spack/repos/builtin/packages/
elif [ ${MACHINE} == 'merlin' ]; then 
  # Copy Merlin-specific configuration for Spack
  cp config.yaml.merlin ${SPACK_ROOT}/etc/spack/config.yaml
  #sed -i "s|    #- USERSCRATCH.*|    - /scratch/${USER}|g" ${SPACK_ROOT}/etc/spack/config.yaml
  cp packages.yaml.merlin ${SPACK_ROOT}/etc/spack/packages.yaml
  cp compilers.yaml.merlin ${SPACK_ROOT}/etc/spack/compilers.yaml
  cp intel.cfg.merlin ${SPACK_ROOT}/etc/spack/intel.cfg
fi

# Copy Nalu-specific configuration for Spack
cp -R nalu ${SPACK_ROOT}/var/spack/repos/builtin/packages/
cp -R nalu-trilinos ${SPACK_ROOT}/var/spack/repos/builtin/packages/
cp -R openfast ${SPACK_ROOT}/var/spack/repos/builtin/packages/
cp -R tioga ${SPACK_ROOT}/var/spack/repos/builtin/packages/
