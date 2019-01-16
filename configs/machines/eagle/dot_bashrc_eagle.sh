# Source global definitions
if [ -f /etc/bashrc ]; then
	. /etc/bashrc
fi

#Spack stuff
export SPACK_ROOT=${HOME}/spack
source ${SPACK_ROOT}/share/spack/setup-env.sh

#Module stuff
MODULES=modules
module purge
module unuse ${MODULEPATH}
module use /nopt/nrel/ecom/hpacf/compilers/${MODULES}
module use /nopt/nrel/ecom/hpacf/utilities/${MODULES}
module use /nopt/nrel/ecom/hpacf/software/${MODULES}/gcc-7.3.0
module load gcc
module load python
module load git
