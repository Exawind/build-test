#!/bin/bash

#Script for copying the recommended configuration for Spack onto your system
#for building Nalu-Wind, be it on any systems listed below

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
    10.13*)
      MACHINE=mac_high_sierra
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
        case "${NREL_CLUSTER}" in
          eagle)
            MACHINE=eagle
          ;;
          peregrine)
            MACHINE=peregrine
          ;;
        esac
        MYHOSTNAME=$(hostname -d)
        case "${MYHOSTNAME}" in
          mcp.alcf.anl.gov)
            MACHINE=mira
          ;;
          fst.alcf.anl.gov)
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
          theta*)
            MACHINE=theta
          ;;
        esac
        MYHOSTNAME=$(hostname -s)
        case "${MYHOSTNAME}" in
          rhodes)
            MACHINE=rhodes
          ;;
        esac
      fi
    ;;
  esac
fi

# Copy machine-specific configuration for Spack if we recognize the machine
if [ "${MACHINE}" == 'peregrine' ] || \
   [ "${MACHINE}" == 'eagle' ] || \
   [ "${MACHINE}" == 'rhodes' ] || \
   [ "${MACHINE}" == 'merlin' ] || \
   [ "${MACHINE}" == 'cori' ] || \
   [ "${MACHINE}" == 'mira' ] || \
   [ "${MACHINE}" == 'theta' ] || \
   [ "${MACHINE}" == 'mutrino' ] || \
   [ "${MACHINE}" == 'ices' ] || \
   [ "${MACHINE}" == 'mac' ] || \
   [ "${MACHINE}" == 'mac_sierra' ] || \
   [ "${MACHINE}" == 'mac_high_sierra' ]; then

  printf "Machine is detected as ${MACHINE}.\n"

  #All machines do this
  (set -x; cp machines/${MACHINE}/*.yaml ${SPACK_ROOT}/etc/spack/)
  (set -x; cp custom-package-files/parallel-netcdf/package.py ${SPACK_ROOT}/var/spack/repos/builtin/packages/parallel-netcdf/package.py)

  #Extra stuff for eagle
  if [ ${MACHINE} == 'eagle' ]; then
    (set -x; cp custom-package-files/mpich/package.py ${SPACK_ROOT}/var/spack/repos/builtin/packages/mpich/package.py)
    (set -x; cp custom-package-files/trilinos/package.py ${SPACK_ROOT}/var/spack/repos/builtin/packages/trilinos/package.py)
    (set -x; cp custom-package-files/nalu-wind/package.py ${SPACK_ROOT}/var/spack/repos/builtin/packages/nalu-wind/package.py)
    (set -x; cp machines/${MACHINE}/compilers.yaml.software ${SPACK_ROOT}/etc/spack/compilers.yaml)
    (set -x; cp machines/${MACHINE}/modules.yaml.software ${SPACK_ROOT}/etc/spack/modules.yaml)
  fi

  #Extra stuff for peregrine
  if [ ${MACHINE} == 'peregrine' ]; then
    (set -x; cp machines/${MACHINE}/compilers.yaml.software ${SPACK_ROOT}/etc/spack/compilers.yaml)
    (set -x; cp machines/${MACHINE}/modules.yaml.software ${SPACK_ROOT}/etc/spack/modules.yaml)
  fi

  #Extra stuff for rhodes
  if [ ${MACHINE} == 'rhodes' ]; then
    (set -x; cp machines/${MACHINE}/compilers.yaml.software ${SPACK_ROOT}/etc/spack/compilers.yaml)
    (set -x; cp machines/${MACHINE}/modules.yaml.software ${SPACK_ROOT}/etc/spack/modules.yaml)
  fi

  #Extra stuff for merlin
  #if [ ${MACHINE} == 'merlin' ]; then
    #nothing at the moment
  #fi

  #Extra stuff for cori
  #if [ ${MACHINE} == 'cori' ]; then
    #nothing at the moment
  #fi

  #Extra stuff for mutrino
  if [ ${MACHINE} == 'mutrino' ]; then
    (set -x; cp -R machines/${MACHINE}/netcdf ${SPACK_ROOT}/var/spack/repos/builtin/packages/)
  fi

  #Extra stuff for mira
  if [ ${MACHINE} == 'mira' ]; then
    (set -x; cp -R machines/${MACHINE}/libsigsegv ${SPACK_ROOT}/var/spack/repos/builtin/packages/)
    (set -x; cp -R machines/${MACHINE}/nalu ${SPACK_ROOT}/var/spack/repos/builtin/packages/)
    (set -x; cp -R machines/${MACHINE}/nalu-wind ${SPACK_ROOT}/var/spack/repos/builtin/packages/)
    (set -x; cp -R machines/${MACHINE}/netcdf ${SPACK_ROOT}/var/spack/repos/builtin/packages/)
    (set -x; cp -R machines/${MACHINE}/parallel-netcdf ${SPACK_ROOT}/var/spack/repos/builtin/packages/)
    (set -x; cp -R machines/${MACHINE}/superlu ${SPACK_ROOT}/var/spack/repos/builtin/packages/)
    (set -x; cp -R machines/${MACHINE}/trilinos ${SPACK_ROOT}/var/spack/repos/builtin/packages/)
    (set -x; cp -R machines/${MACHINE}/yaml-cpp ${SPACK_ROOT}/var/spack/repos/builtin/packages/)
  fi

  #Extra stuff for theta
  # SuperLU tries to run a KNL executable on the haswell login nodes without this custom SuperLU version
  if [ ${MACHINE} == 'theta' ]; then
    (set -x; cp -R machines/${MACHINE}/superlu ${SPACK_ROOT}/var/spack/repos/builtin/packages/)
  fi

  #Extra stuff for ices
  #if [ ${MACHINE} == 'ices' ]; then
    #nothing at the moment
  #fi

  #Extra stuff for macs
  #if [ ${MACHINE} == 'mac' ] || [ "${MACHINE}" == 'mac_sierra' ] || [ "${MACHINE}" == 'mac_high_sierra' ]; then
    #nothing at the moment
  #fi

  #Use branch instead of tag so spack will checkout a real git repo instead of caching a tar.gz of a branch
  #if [ ${MACHINE} == 'mac' ] || [ "${MACHINE}" == 'mac_sierra' ] || [ "${MACHINE}" == 'mac_high_sierra' ]; then
  #  (set -x; sed -i "" -e "s/tag=/branch=/g" ${SPACK_ROOT}/var/spack/repos/builtin/packages/trilinos/package.py)
  #else
  #  (set -x; sed -i "s/tag=/branch=/g" ${SPACK_ROOT}/var/spack/repos/builtin/packages/trilinos/package.py)
  #fi
else
  printf "\nMachine name not found.\n"
fi

