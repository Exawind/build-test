#!/bin/bash -l

#SBATCH -J nalu-wind-test
#SBATCH -o %x.o%j
#SBATCH -t 30
#SBATCH -N 1

# To run use the command `sbatch test.sh`
 
set -e

cmd() {
  echo "+ $@"
  eval "$@"
}

# Set up environment on Eagle
cmd "module purge"
cmd "module use /nopt/nrel/ecom/hpacf/2018-11-09/spack/share/spack/modules/linux-centos7-x86_64/gcc-7.3.0"
cmd "module load git"
cmd "module load python"
cmd "module load openmpi"
cmd "module load netlib-lapack"
cmd "module load gcc/7.3.0"
cmd "module load openfast"
cmd "module load hypre"
cmd "module load tioga"
cmd "module load yaml-cpp"
cmd "module load cmake"
cmd "module load trilinos"
cmd "module load boost"
cmd "module list"

cmd "which cmake"
cmd "which mpirun"

cmd "ctest -VV -R ductWedge"
