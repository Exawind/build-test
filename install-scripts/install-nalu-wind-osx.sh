#!/bin/bash
 
cmd() {
  echo "+ $@"
  eval "$@"
}
 
#Assuming cmake and pkg-config installed with homebrew on OSX 10.12 (sierra)
#Look at ${SPACK_ROOT}/etc/spack/packages.yaml to see where the
#external locations are defined for cmake and pkg-config and where the TPL
#version preferences are listed (if you build with Apple Clang, you could probably delete
#the entries for cmake and pkg-config in $SPACK_ROOT/etc/spack/packages.yaml because
#Apple Clang should be able to build them)
 
EXAWIND_DIR=${HOME}/exawind
cmd "mkdir -p ${EXAWIND_DIR}"
cmd "cd ${EXAWIND_DIR} && git clone https://github.com/spack/spack.git"
cmd "cd ${EXAWIND_DIR} && git clone https://github.com/exawind/build-test.git"
cmd "export SPACK_ROOT=${EXAWIND_DIR}/spack"
cmd "source ${SPACK_ROOT}/share/spack/setup-env.sh"
cmd "cd ${EXAWIND_DIR}/build-test/configs && ./setup-spack.sh"
cmd "spack compilers"
cmd "nice spack install nalu-wind"
 
#Here you can install with some optional TPLs
#cmd "nice spack install nalu-wind+tioga+hypre+openfast"
 
#Here you can just install the dependencies and not nalu-wind itself
#cmd "nice spack install --only dependencies nalu-wind+tioga+hypre+openfast"
