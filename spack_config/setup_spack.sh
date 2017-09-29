#!/bin/bash

#Script for copying the recommended configuration for Spack onto your system
#for building Nalu, be it on Peregrine, Merlin, Cori, or a Mac

if [ -z "${SPACK_ROOT}" ]; then
    echo "SPACK_ROOT must be set first"
    exit 1
fi

set -e

OS=`uname -s`

#Use kind of ridiculous logic to find the machine name
if [ ${OS} == 'Darwin' ]; then
  MACHINE=mac
  OSX=`sw_vers -productVersion`
  case "${OSX}" in
    10.12*)
      MACHINE=mac_sierra
    ;;
  esac
elif [ ${OS} == 'Linux' ]; then
  case "${NERSC_HOST}" in
    cori)
      MACHINE=cori
    ;;
    "")
      if [ -f "/etc/nrel" ]; then 
        MACHINE=merlin
      else
        MYHOSTNAME=`hostname -d`
        case "${MYHOSTNAME}" in
          hpc.nrel.gov)
            MACHINE=peregrine
          ;;
        esac
      fi
    ;;
  esac
fi

# Copy machine-specific configuration for Spack if we recognize the machine
if [ "${MACHINE}" == 'peregrine' ] || \
   [ "${MACHINE}" == 'merlin' ] || \
   [ "${MACHINE}" == 'cori' ] || \
   [ "${MACHINE}" == 'mac' ] || \
   [ "${MACHINE}" == 'mac_sierra' ]; then

  printf "Machine is detected as ${MACHINE}.\n"

  #All machines do this
  (set -x; cp machines/${MACHINE}/*.yaml ${SPACK_ROOT}/etc/spack/)

  #Extra stuff for peregrine
  if [ ${MACHINE} == 'peregrine' ]; then
    (set -x; cp machines/${MACHINE}/intel.cfg ${SPACK_ROOT}/etc/spack/intel.cfg)
  fi

  #Extra stuff for merlin
  if [ ${MACHINE} == 'merlin' ]; then
    (set -x; cp machines/${MACHINE}/intel.cfg ${SPACK_ROOT}/etc/spack/intel.cfg)
  fi

  #Extra stuff for cori
  #if [ ${MACHINE} == 'cori' ]; then
    #nothing at the moment
  #fi

  #Extra stuff for macs
  #if [ ${MACHINE} == 'mac' ] || [ "${MACHINE}" == 'mac_sierra' ]; then
    #nothing at the moment
  #fi

  #Use branch instead of tag so spack will checkout a real git repo instead of cache a tar.gz of a branch
  #Also temporarily need to change Nalu to depend on Trilinos develop branch
  if [ ${MACHINE} == 'mac' ] || [ "${MACHINE}" == 'mac_sierra' ]; then
    (set -x; sed -i "" -e "s/tag=/branch=/g" ${SPACK_ROOT}/var/spack/repos/builtin/packages/trilinos/package.py)
    (set -x; sed -i "" -e "s/@master/@develop/g" ${SPACK_ROOT}/var/spack/repos/builtin/packages/nalu/package.py)
  else
    (set -x; sed -i "s/tag=/branch=/g" ${SPACK_ROOT}/var/spack/repos/builtin/packages/trilinos/package.py)
    (set -x; sed -i "s/@master/@develop/g" ${SPACK_ROOT}/var/spack/repos/builtin/packages/nalu/package.py)
  fi
else
  printf "\nMachine name not found.\n"
fi

