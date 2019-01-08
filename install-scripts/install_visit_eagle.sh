#!/bin/bash -l

#PBS -N build_visit
#PBS -l nodes=1:ppn=24,walltime=4:00:00,feature=haswell
#PBS -A windsim
#PBS -q short
#PBS -j oe
#PBS -W umask=002

cmd() {
  echo "+ $@"
  eval "$@"
}

set -e

cmd "module purge"
cmd "module load gcc/4.9.4"
cmd "module load python"
cmd "module load git"
cmd "module load binutils"
cmd "module load libxml2/2.9.8-py2"
cmd "module load makedepend"
cmd "module load netlib-lapack"
cmd "module load libx11"
cmd "module load libxt"
cmd "module load libsm"
cmd "module load libice"
cmd "module load bzip2"
cmd "module list"

cmd "mkdir -p /scratch/${USER}/.tmp"
cmd "export TMPDIR=/scratch/${USER}/.tmp"

export MY_VISIT_DIR=/nopt/nrel/ecom/hpacf/software/2019-01-02/visit/server
export MY_PYTHON_LIB=${MY_VISIT_DIR}/visit/python/2.7.11/linux-x86_64_gcc-4.9/lib/libpython2.7.so

# External mpi but you need an older gcc in the compiler wrappers to build certain things in the build_visit script
#cmd "mkdir -p ${MY_VISIT_DIR} && cp build_visit2_13_2 ${MY_VISIT_DIR}/ && cd ${MY_VISIT_DIR} && export PAR_COMPILER=${OPENMPI_ROOT_DIR}/bin/mpicc && export PAR_COMPILER_CXX=${OPENMPI_ROOT_DIR}/bin/mpicxx && ./build_visit2_13_2 --makeflags -j36 --parallel --required --optional --all-io --nonio --no-fastbit --no-fastquery --prefix ${MY_VISIT_DIR}/install"

# Use visit's own mpich
cmd "mkdir -p ${MY_VISIT_DIR} && cp build_visit2_13_2 ${MY_VISIT_DIR}/ && cd ${MY_VISIT_DIR} && ./build_visit2_13_2 --makeflags -j36 --parallel --required --optional --all-io --nonio --no-fastbit --no-fastquery --prefix ${MY_VISIT_DIR}/install"

#Then add this to /nopt/nrel/ecom/hpacf/software/2019-01-02/visit/server/install/2.13.0/bin/internallauncher
##execfile('/nopt/Modules/default/init/python.py')
##module('purge')
##module('load gcc/4.9.4')
#SETENV("PATH", self.joinpaths(["/nopt/nrel/ecom/hpacf/software/2019-01-02/visit/server/install/bin", "/nopt/nrel/ecom/hpacf/software/2019-01-02/visit/server/install/2.13.2/linux-x86_64/bin", GETENV("PATH")]))
#SETENV("LD_LIBRARY_PATH", self.joinpaths(["/nopt/nrel/ecom/hpacf/software/2019-01-02/visit/server/install/2.13.2/linux-x86_64/lib", GETENV("LD_LIBRARY_PATH")]))
#SETENV("LD_LIBRARY_PATH", self.joinpaths(["/nopt/nrel/ecom/hpacf/software/2019-01-02/spack/opt/spack/linux-centos7-x86_64/gcc-7.3.0/netlib-lapack-3.8.0-e4xwkqx3xg7gdlz3rkoczxfcpqwkcvtw/lib64", GETENV("LD_LIBRARY_PATH")]))
#SETENV("LIBRARY_PATH", self.joinpaths(["/nopt/nrel/ecom/hpacf/software/2019-01-02/visit/server/install/2.13.2/linux-x86_64/lib", GETENV("LIBRARY_PATH")]))
#SETENV("VISIT_ROOT_DIR", "/nopt/nrel/ecom/hpacf/software/2019-01-02/visit/server/install")
