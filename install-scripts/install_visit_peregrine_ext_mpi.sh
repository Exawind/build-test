#!/bin/bash -l

#PBS -N build_visit
#PBS -l nodes=1:ppn=24,walltime=4:00:00,feature=haswell
#PBS -A ExaCT
#PBS -q short
#PBS -j oe
#PBS -W umask=002

cmd() {
  echo "+ $@"
  eval "$@"
}

set -e

cmd "module purge"
cmd "module use /nopt/nrel/ecom/ecp/base/modules/gcc-6.2.0"
cmd "module load gcc/6.2.0"
cmd "module load python/2.7.14"
cmd "module load git/2.17.0"
cmd "module load binutils/2.29.1"
cmd "module load libxml2/2.9.4-py2"
cmd "module load makedepend/1.0.5"
cmd "module load netlib-lapack/3.8.0"
cmd "module load openmpi/1.10.4"
cmd "module load libtool"
cmd "module list"

cmd "mkdir -p /scratch/${USER}/.tmp"
cmd "export TMPDIR=/scratch/${USER}/.tmp"

#Had to manually set nektar library type to static in its cmakelists
VISIT_DIR=${SCRATCH}/visit
(set -x; cp build_visit2_13_2 ${VISIT_DIR}/ && cd ${VISIT_DIR} && export PAR_COMPILER=${OPENMPI_ROOT_DIR}/bin/mpicc && export PAR_COMPILER_CXX=${OPENMPI_ROOT_DIR}/bin/mpicxx && export PAR_INCLUDE="-I${OPENMPI_ROOT_DIR}/include" && ./build_visit2_13_2 --makeflags -j24 --parallel --required --optional --all-io --nonio --no-fastbit --no-fastquery --static --mesa --no-adios --no-mpich --prefix ${VISIT_DIR}/install)
