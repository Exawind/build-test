# .bash_profile

#Example .bash_profile for using Spack on Peregrine

# Get the aliases and functions
if [ -f ~/.bashrc ]; then
	. ~/.bashrc
fi

# User specific environment and startup programs

module purge
module use /nopt/nrel/ecom/ecp/base/modules/gcc-6.2.0
#module use /nopt/nrel/ecom/ecp/base/modules/intel-18.1.163
module load gcc/6.2.0
module load git/2.15.1
module load python/2.7.14

export SPACK_ROOT=${HOME}/spack
. ${SPACK_ROOT}/share/spack/setup-env.sh
