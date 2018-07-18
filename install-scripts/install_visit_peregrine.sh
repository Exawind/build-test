#!/bin/bash -l

#PBS -N build_visit
#PBS -l nodes=1:ppn=24,walltime=6:00:00,feature=haswell
#PBS -A windsim
#PBS -q batch-h
#PBS -j oe
#PBS -W umask=002

cmd() {
  echo "+ $@"
  eval "$@"
}

set -e

cmd "module purge"
cmd "module use /nopt/nrel/ecom/ecp/base/a/spack/share/spack/modules/linux-centos7-x86_64/gcc-6.2.0"
cmd "module load gcc/6.2.0"
cmd "module load python/2.7.15"
cmd "module load git/2.17.1"
cmd "module load binutils"
cmd "module load libxml2"
cmd "module load makedepend"
cmd "module load netlib-lapack"
cmd "module list"

cmd "mkdir -p /scratch/${USER}/.tmp"
cmd "export TMPDIR=/scratch/${USER}/.tmp"

export MY_VISIT_DIR=/nopt/nrel/ecom/ecp/base/a/visit
export MY_PYTHON_LIB=${MY_VISIT_DIR}/visit/python/2.7.11/linux-x86_64_gcc-4.8/lib/libpython2.7.so

cmd "mkdir -p ${MY_VISIT_DIR} && cp build_visit2_13_2 ${MY_VISIT_DIR}/ && cd ${MY_VISIT_DIR} && ./build_visit2_13_2 --makeflags -j24 --parallel --required --optional --all-io --nonio --no-fastbit --no-fastquery --prefix ${MY_VISIT_DIR}/install"

#Then add this to /nopt/nrel/ecom/ecp/base/a/visit/install/2.13.0/bin/internallauncher
#SETENV("PATH", self.joinpaths(["/nopt/nrel/ecom/ecp/base/a/visit/install/bin", "/nopt/nrel/ecom/ecp/base/a/visit/install/2.13.0/linux-x86_64/bin", GETENV("PATH")]))
#SETENV("LD_LIBRARY_PATH", self.joinpaths(["/nopt/nrel/ecom/ecp/base/a/visit/install/2.13.0/linux-x86_64/lib", GETENV("LD_LIBRARY_PATH")]))
#SETENV("LIBRARY_PATH", self.joinpaths(["/nopt/nrel/ecom/ecp/base/a/visit/install/2.13.0/linux-x86_64/lib", GETENV("LIBRARY_PATH")]))
#SETENV("VISIT_ROOT_DIR", "/nopt/nrel/ecom/ecp/base/a/visit/install")
