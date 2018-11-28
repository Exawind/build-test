# .bash_profile

#Example .bash_profile for using Spack on Peregrine

# Get the aliases and functions
if [ -f ~/.bashrc ]; then
	. ~/.bashrc
fi

# User specific environment and startup programs

#Module stuff
module unuse /nopt/nrel/apps/modules/centos7/modulefiles
module use /nopt/nrel/ecom/hpacf/compilers/modules
module use /nopt/nrel/ecom/hpacf/utilities/modules
module use /nopt/nrel/ecom/hpacf/software/modules/gcc-7.3.0
module purge
module load gcc/7.3.0
module load python
module load git
