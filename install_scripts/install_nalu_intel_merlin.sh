#!/bin/bash -l

#PBS -N nalu_build_intel
#PBS -l nodes=1:ppn=24,walltime=4:00:00
#PBS -A windFlowModeling
#PBS -q batch
#PBS -o $PBS_JOBNAME.log
#PBS -j oe
#PBS -W umask=002

#Script for installing Nalu on Merlin using Spack with Intel compiler

set -e

cd ${HOME}

module purge

TPLS="
^boost@1.60.0 \
^cmake@3.6.1 \
^parallel-netcdf@1.6.1 \
^yaml-cpp@0.5.3 \
^hdf5@1.8.16 \
^netcdf@4.3.3.1 \
^pkg-config@0.29.2 \
^zlib@1.2.11 \
^hwloc@1.11.6 \
^m4@1.4.17 \
^superlu@4.3
"

# For temporary intel compiler files
mkdir -p /scratch/${USER}/.tmp
export TMPDIR=/scratch/${USER}/.tmp
# For different versions of trilinos add a '^nalu-trilinos+debug@develop'
# for a debug version of the trilinos development branch for example
spack install nalu %intel ^nalu-trilinos@master ^openmpi@1.10.3 ${TPLS}
