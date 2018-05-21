#!/bin/bash -l

#PBS -N build_visit
#PBS -l nodes=1:ppn=24,walltime=6:00:00
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
cmd "module use /nopt/nrel/ecom/ecp/base/modules/gcc-6.2.0"
cmd "module load gcc/5.5.0"
cmd "module load python/2.7.14"
cmd "module load git/2.17.0"
cmd "module load binutils/2.29.1"
cmd "module load libxml2/2.9.4-py2"
cmd "module load makedepend/1.0.5"
cmd "module load netlib-lapack/3.8.0"
cmd "module list"

cmd "mkdir -p /scratch/${USER}/.tmp"
cmd "export TMPDIR=/scratch/${USER}/.tmp"

#cmd "export PAR_COMPILER=mpicc; export PAR_COMPILER_CXX=mpicxx; export PAR_INCLUDE=/nopt/nrel/apps/openmpi/1.10.0-serial-gcc-5.2.0/include; export PAR_LIBS=/nopt/nrel/apps/openmpi/1.10.0-serial-gcc-5.2.0/lib/libmpi.a; ./build_visit2_13_0 --makeflags -j24 --parallel --required --optional --all-io --nonio --no-fastbit --no-fastquery --prefix /projects/windsim/exawind/software/visit/a/install"

VISIT_DIR=/nopt/nrel/ecom/ecp/base/c/visit
cmd "cp build_visit2_13_0 ${VISIT_DIR}/ && cd ${VISIT_DIR} && ./build_visit2_13_0 --makeflags -j24 --parallel --required --optional --all-io --nonio --no-fastbit --no-fastquery --prefix ${VISIT_DIR}/install"

#Then manually create module file for visit

#Then add this to /nopt/nrel/ecom/ecp/base/c/visit/install/2.13.0/bin/internallauncher
#SETENV("PATH", self.joinpaths(["/nopt/nrel/ecom/ecp/base/c/visit/install/bin", "/nopt/nrel/ecom/ecp/base/c/visit/install/2.13.0/linux-x86_64/bin", GETENV("PATH")]))
#SETENV("LD_LIBRARY_PATH", self.joinpaths(["/nopt/nrel/ecom/ecp/base/c/visit/install/2.13.0/linux-x86_64/lib", GETENV("LD_LIBRARY_PATH")]))
#SETENV("LIBRARY_PATH", self.joinpaths(["/nopt/nrel/ecom/ecp/base/c/visit/install/2.13.0/linux-x86_64/lib", GETENV("LIBRARY_PATH")]))
#SETENV("VISIT_ROOT_DIR", "/nopt/nrel/ecom/ecp/base/c/visit/install")
