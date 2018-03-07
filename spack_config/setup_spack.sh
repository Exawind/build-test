#!/bin/bash

#Script for copying the recommended configuration for Spack onto your system
#for building Nalu, be it on Peregrine, Merlin, Cori, or a Mac

if [ -z "${SPACK_ROOT}" ]; then
    echo "SPACK_ROOT must be set first"
    exit 1
fi

set -e

OS=$(uname -s)

#Use kind of ridiculous logic to find the machine name
if [ ${OS} == 'Darwin' ]; then
  MACHINE=mac
  OSX=$(sw_vers -productVersion)
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
        MYHOSTNAME=$(hostname -d)
        case "${MYHOSTNAME}" in
          hpc.nrel.gov)
            MACHINE=peregrine
          ;;
          mcp.alcf.anl.gov)
            MACHINE=mira
          ;;
          ices.utexas.edu)
            MACHINE=ices
          ;;
        esac
        MYHOSTNAME=$(hostname)
        case "${MYHOSTNAME}" in
          mutrino)
            MACHINE=mutrino
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
   [ "${MACHINE}" == 'mira' ] || \
   [ "${MACHINE}" == 'mutrino' ] || \
   [ "${MACHINE}" == 'ices' ] || \
   [ "${MACHINE}" == 'mac' ] || \
   [ "${MACHINE}" == 'mac_sierra' ]; then

  printf "Machine is detected as ${MACHINE}.\n"

  #All machines do this
  (set -x; cp machines/${MACHINE}/*.yaml ${SPACK_ROOT}/etc/spack/)
  (set -x; cp -R custom_package_files/nalu ${SPACK_ROOT}/var/spack/repos/builtin/packages/)
  (set -x; cp -R custom_package_files/openfast ${SPACK_ROOT}/var/spack/repos/builtin/packages/)
  (set -x; cp -R custom_package_files/catalyst-ioss-adapter ${SPACK_ROOT}/var/spack/repos/builtin/packages/)

  #Extra stuff for peregrine
  if [ ${MACHINE} == 'peregrine' ]; then
    (set -x; cp machines/${MACHINE}/intel.cfg ${SPACK_ROOT}/etc/spack/intel.cfg)
  fi

  #Extra stuff for merlin
  if [ ${MACHINE} == 'merlin' ]; then
    (set -x; cp machines/${MACHINE}/intel.cfg ${SPACK_ROOT}/etc/spack/intel.cfg)
  fi

  #Extra stuff for cori
  if [ ${MACHINE} == 'cori' ]; then
    (set -x; cp -R machines/${MACHINE}/netcdf ${SPACK_ROOT}/var/spack/repos/builtin/packages/)
  fi

  #Extra stuff for mutrino
  if [ ${MACHINE} == 'mutrino' ]; then
    (set -x; cp -R machines/${MACHINE}/netcdf ${SPACK_ROOT}/var/spack/repos/builtin/packages/)
  fi

  #Extra stuff for mira
  if [ ${MACHINE} == 'mira' ]; then
    (set -x; cp -R machines/${MACHINE}/nalu ${SPACK_ROOT}/var/spack/repos/builtin/packages/)
    (set -x; cp -R machines/${MACHINE}/trilinos ${SPACK_ROOT}/var/spack/repos/builtin/packages/)
    (set -x; cp -R machines/${MACHINE}/superlu ${SPACK_ROOT}/var/spack/repos/builtin/packages/)
    (set -x; cp -R machines/${MACHINE}/openfast ${SPACK_ROOT}/var/spack/repos/builtin/packages/)
    (set -x; cp -R machines/${MACHINE}/libxml2 ${SPACK_ROOT}/var/spack/repos/builtin/packages/)
  fi

  #Extra stuff for ices
  #if [ ${MACHINE} == 'ices' ]; then
    #nothing at the moment
  #fi
  #Extra stuff for macs
  #if [ ${MACHINE} == 'mac' ] || [ "${MACHINE}" == 'mac_sierra' ]; then
    #nothing at the moment
  #fi

  #Use branch instead of tag so spack will checkout a real git repo instead of caching a tar.gz of a branch
  if [ ${MACHINE} == 'mac' ] || [ "${MACHINE}" == 'mac_sierra' ]; then
    (set -x; sed -i "" -e "s/tag=/branch=/g" ${SPACK_ROOT}/var/spack/repos/builtin/packages/trilinos/package.py)
  else
    (set -x; sed -i "s/tag=/branch=/g" ${SPACK_ROOT}/var/spack/repos/builtin/packages/trilinos/package.py)
  fi
else
  printf "\nMachine name not found.\n"
fi

