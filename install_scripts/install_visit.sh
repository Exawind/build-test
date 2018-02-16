#!/bin/bash -l

#PBS -N build_visit
#PBS -l nodes=1:ppn=24,walltime=4:00:00
#PBS -A windsim
#PBS -q short
#PBS -j oe
#PBS -W umask=002

cmd() {
  echo "+ $@"
  eval "$@"
}

set -e

#export SPACK_ROOT=${HOME}/spack
#source ${SPACK_ROOT}/share/spack/setup-env.sh
cmd "module purge"
cmd "module use /nopt/nrel/apps/modules/candidate/modulefiles"
cmd "module use /projects/windsim/exawind/BaseSoftware/spack/share/spack/modules/linux-centos6-x86_64"
cmd "module load gcc/5.2.0"
#cmd "module load openmpi-gcc/1.10.0-5.2.0"
cmd "module load python/2.7.14"
cmd "module load git/2.6.3"
cmd "module load binutils/2.28"
cmd "module load libxml2/2.9.4"
cmd "module load makedepend/1.0.5"
cmd "module list"

cmd "mkdir -p /scratch/${USER}/.tmp"
cmd "export TMPDIR=/scratch/${USER}/.tmp"

cmd "cd /projects/windsim/exawind/software/visit/a"
#cmd "export PAR_COMPILER=mpicc; export PAR_COMPILER_CXX=mpicxx; export PAR_INCLUDE=/nopt/nrel/apps/openmpi/1.10.0-serial-gcc-5.2.0/include; export PAR_LIBS=/nopt/nrel/apps/openmpi/1.10.0-serial-gcc-5.2.0/lib/libmpi.a; ./build_visit2_13_0 --makeflags -j24 --parallel --required --optional --all-io --nonio --no-fastbit --no-fastquery --prefix /projects/windsim/exawind/software/visit/a/install"
# Using its own builtin mpich
cmd "./build_visit2_13_0 --makeflags -j24 --parallel --required --optional --all-io --nonio --no-fastbit --no-fastquery --prefix /projects/windsim/exawind/software/visit/a/install"
