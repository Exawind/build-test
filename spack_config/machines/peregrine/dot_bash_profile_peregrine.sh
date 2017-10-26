# .bash_profile

#Example .bash_profile for using Spack on Peregrine

# Get the aliases and functions
if [ -f ~/.bashrc ]; then
	. ~/.bashrc
fi

# User specific environment and startup programs

{
module purge
module load gcc/5.2.0
module load python/2.7.8
module unload mkl
} &> /dev/null

export SPACK_ROOT=${HOME}/spack
. ${SPACK_ROOT}/share/spack/setup-env.sh

