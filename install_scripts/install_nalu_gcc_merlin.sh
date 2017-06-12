#!/bin/bash -l

#PBS -N nalu_build_gcc
#PBS -l nodes=1:ppn=24,walltime=4:00:00
#PBS -A windFlowModeling
#PBS -q batch
#PBS -o $PBS_JOBNAME.log
#PBS -j oe
#PBS -W umask=002

#Script for installing Nalu on Merlin using Spack with GCC compiler

set -e

module purge

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

spack install nalu %gcc@4.8.5 ${TRILINOS} ${TPLS}
