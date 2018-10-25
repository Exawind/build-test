#!/bin/bash -l

module purge
module unuse /nopt/nrel/apps/modules/centos7/modulefiles
module unuse /nopt/nrel/ecom/ecp/base/modules/gcc-6.2.0
module use /scratch/jrood/eagle2/eagle_software/spack/share/spack/modules/linux-centos7-x86_64
module use /scratch/jrood/eagle2/eagle_compilers/spack/share/spack/modules/linux-centos7-x86_64/gcc-6.2.0
module purge
