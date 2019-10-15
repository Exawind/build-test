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
  OSX=$(sw_vers -productVersion)
  case "${OSX}" in
    10.12*)
      MACHINE=mac
    ;;
    10.13*)
      MACHINE=mac
    ;;
  esac
elif [ ${OS} == 'Linux' ]; then
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
fi

# Copy machine-specific configuration for Spack if we recognize the machine
if [ "${MACHINE}" == 'eagle' ] || \
   [ "${MACHINE}" == 'rhodes' ] || \
   [ "${MACHINE}" == 'mac' ]; then

  printf "Machine is detected as ${MACHINE}.\n"

  #All machines do this
  (set -x; cp machines/base/*.yaml ${SPACK_ROOT}/etc/spack/)
  (set -x; cp custom-package-files/parallel-netcdf/package.py ${SPACK_ROOT}/var/spack/repos/builtin/packages/parallel-netcdf/package.py)
  (set -x; cp custom-package-files/trilinos-catalyst-ioss-adapter/package.py ${SPACK_ROOT}/var/spack/repos/builtin/packages/trilinos-catalyst-ioss-adapter/package.py)

  #Extra stuff for eagle
  if [ ${MACHINE} == 'eagle' ]; then
    (set -x; mkdir ${SPACK_ROOT}/etc/spack/linux)
    (set -x; cp machines/${MACHINE}/packages.yaml.${MACHINE} ${SPACK_ROOT}/etc/spack/linux/packages.yaml)
    (set -x; cp custom-package-files/mpich/package.py ${SPACK_ROOT}/var/spack/repos/builtin/packages/mpich/package.py)
    (set -x; cp custom-package-files/ucx/package.py ${SPACK_ROOT}/var/spack/repos/builtin/packages/ucx/package.py)
    (set -x; cp custom-package-files/trilinos/package.py ${SPACK_ROOT}/var/spack/repos/builtin/packages/trilinos/package.py)
    (set -x; cp custom-package-files/nalu-wind/package.py ${SPACK_ROOT}/var/spack/repos/builtin/packages/nalu-wind/package.py)
    (set -x; cp machines/${MACHINE}/compilers.yaml.software ${SPACK_ROOT}/etc/spack/compilers.yaml)
    (set -x; cp machines/${MACHINE}/modules.yaml.software ${SPACK_ROOT}/etc/spack/modules.yaml)
  fi

  #Extra stuff for rhodes
  if [ ${MACHINE} == 'rhodes' ]; then
    (set -x; mkdir ${SPACK_ROOT}/etc/spack/linux)
    (set -x; cp machines/${MACHINE}/packages.yaml.${MACHINE} ${SPACK_ROOT}/etc/spack/linux/packages.yaml)
    (set -x; cp machines/${MACHINE}/compilers.yaml.software ${SPACK_ROOT}/etc/spack/compilers.yaml)
    (set -x; cp machines/${MACHINE}/modules.yaml.software ${SPACK_ROOT}/etc/spack/modules.yaml)
  fi

  if [ "${MACHINE}" == 'mac' ]; then
    (set -x; mkdir ${SPACK_ROOT}/etc/spack/darwin)
    (set -x; cp machines/${MACHINE}/packages.yaml.${MACHINE} ${SPACK_ROOT}/etc/spack/darwin/packages.yaml)
  fi

  #Extra stuff for mira
  #if [ ${MACHINE} == 'mira' ]; then
  #  (set -x; cp -R machines/${MACHINE}/libsigsegv ${SPACK_ROOT}/var/spack/repos/builtin/packages/)
  #  (set -x; cp -R machines/${MACHINE}/nalu ${SPACK_ROOT}/var/spack/repos/builtin/packages/)
  #  (set -x; cp -R machines/${MACHINE}/nalu-wind ${SPACK_ROOT}/var/spack/repos/builtin/packages/)
  #  (set -x; cp -R machines/${MACHINE}/netcdf ${SPACK_ROOT}/var/spack/repos/builtin/packages/)
  #  (set -x; cp -R machines/${MACHINE}/parallel-netcdf ${SPACK_ROOT}/var/spack/repos/builtin/packages/)
  #  (set -x; cp -R machines/${MACHINE}/superlu ${SPACK_ROOT}/var/spack/repos/builtin/packages/)
  #  (set -x; cp -R machines/${MACHINE}/trilinos ${SPACK_ROOT}/var/spack/repos/builtin/packages/)
  #  (set -x; cp -R machines/${MACHINE}/yaml-cpp ${SPACK_ROOT}/var/spack/repos/builtin/packages/)
  #fi
else
  printf "\nMachine name not found.\n"
fi

