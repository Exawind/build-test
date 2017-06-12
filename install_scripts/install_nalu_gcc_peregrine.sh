#!/bin/bash -l

#PBS -N nalu_build_gcc
#PBS -l nodes=1:ppn=24,walltime=4:00:00
#PBS -A windFlowModeling
#PBS -q short
#PBS -o $PBS_JOBNAME.log
#PBS -j oe
#PBS -W umask=002

#Script for installing Nalu on Peregrine using Spack with GCC compiler

set -e

{
module purge
module load gcc/5.2.0
module load python/2.7.8
} &> /dev/null

TRILINOS="
^trilinos~alloptpkgs~xsdkflags~metis~mumps~superlu-dist+superlu~hypre+hdf5~suite-sparse~python~shared~debug+boost+tpetra~epetra~epetraext+exodus+pnetcdf+zlib+stk+teuchos+belos+zoltan+zoltan2~amesos+amesos2~ifpack+ifpack2+muelu~fortran~ml+gtest~aztec~sacado~x11+instantiate~instantiate_cmplx~dtk@master
"

TPLS="
^openmpi@1.10.3 \
^boost@1.60.0 \
^cmake@3.6.1 \
^parallel-netcdf@1.6.1 \
^hdf5@1.8.16 \
^netcdf@4.3.3.1 \
^superlu@4.3
"

spack install binutils %gcc
. ${SPACK_ROOT}/share/spack/setup-env.sh
spack load binutils
spack install nalu %gcc@5.2.0 ${TRILINOS} ${TPLS}
