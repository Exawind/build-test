#!/bin/bash -l

#PBS -N nalu_build_intel
#PBS -l nodes=1:ppn=24,walltime=4:00:00
#PBS -A windFlowModeling
#PBS -q batch
#PBS -j oe
#PBS -W umask=002

#Script for installing Nalu on Merlin using Spack with Intel compiler

set -e

cd ${HOME}

module purge

export INTEL_LICENSE_FILE=28518@hpc-admin1.hpc.nrel.gov

for i in ICCCFG ICPCCFG IFORTCFG
do
  export $i=${SPACK_ROOT}/etc/spack/intel.cfg
done

TRILINOS="
^trilinos~alloptpkgs~xsdkflags~metis~mumps~superlu-dist+superlu~hypre+hdf5~suite-sparse~python~shared~debug+boost+tpetra~epetra~epetraext+exodus+pnetcdf+zlib+stk~teuchos+belos+zoltan+zoltan2~amesos+amesos2~ifpack+ifpack2+muelu~fortran~ml+gtest~aztec~sacado~x11+instantiate~instantiate_cmplx~dtk@master
"

TPLS="
^openmpi@1.10.3 \
^boost@1.60.0 \
^cmake@3.6.1 \
^parallel-netcdf@1.6.1 \
^hdf5@1.8.16 \
^netcdf@4.3.3.1 \
^pkg-config@0.29.2 \
^zlib@1.2.11 \
^hwloc@1.11.6 \
^m4@1.4.17 \
^superlu@4.3
"

export TMPDIR=/dev/shm
spack install nalu %intel@17.0.2 ${TRILINOS} ${TPLS}
