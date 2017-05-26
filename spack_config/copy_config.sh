#!/bin/bash

#Script for copying the recommended configuration for Spack onto your system
#for building Nalu, be it on Peregrine, Merlin, Cori, or a Mac

if [ -z "${SPACK_ROOT}" ]; then
    echo "SPACK_ROOT must be set first"
    exit 1
fi

set -ex

OS=`uname -s`

# Find machine name
if [ ${OS} == 'Linux' ]; then
  MYHOSTNAME=`hostname -d`
  case "${MYHOSTNAME}" in
    localdomain)
      MACHINE=merlin
    ;;
    hpc.nrel.gov)
      MACHINE=peregrine
    ;;
    "")
      MYHOSTNAME=`hostname -f`
      case "${MYHOSTNAME}" in
        merlin)
          MACHINE=merlin
        ;;
        *cori*)
          MACHINE=cori
        ;;
      esac
  esac
elif [ ${OS} == 'Darwin' ]; then
  MACHINE=`hostname -s`
fi

# Copy machine-specific configuration for Spack if we recognize the machine
if [ -z "${MACHINE}" ]; then
  echo "MACHINE name not found"
else
  echo "MYHOSTNAME is ${MYHOSTNAME}"
  echo "MACHINE is ${MACHINE}"
  if [ ${MACHINE} == 'peregrine' ] || [ ${MACHINE} == 'merlin' ] || [ ${MACHINE} == 'cori' ]; then
    cp config.yaml.${MACHINE} ${SPACK_ROOT}/etc/spack/config.yaml
    cp packages.yaml.${MACHINE} ${SPACK_ROOT}/etc/spack/packages.yaml
    cp compilers.yaml.${MACHINE} ${SPACK_ROOT}/etc/spack/compilers.yaml
    #sed -i "s|    #- USERSCRATCH.*|    - /scratch/${USER}|g" ${SPACK_ROOT}/etc/spack/config.yaml
    if [ ${MACHINE} == 'merlin' ]; then
      cp intel.cfg.${MACHINE} ${SPACK_ROOT}/etc/spack/intel.cfg
    fi
  fi
fi

# Copy Nalu-specific configuration for Spack
cp -R nalu ${SPACK_ROOT}/var/spack/repos/builtin/packages/
cp -R nalu-trilinos ${SPACK_ROOT}/var/spack/repos/builtin/packages/
cp -R openfast ${SPACK_ROOT}/var/spack/repos/builtin/packages/
cp -R tioga ${SPACK_ROOT}/var/spack/repos/builtin/packages/
