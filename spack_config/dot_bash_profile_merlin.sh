# .bash_profile

#Example .bash_profile for using Spack on Peregrine

# Get the aliases and functions
if [ -f ~/.bashrc ]; then
	. ~/.bashrc
fi

# User specific environment and startup programs

module purge

export SPACK_ROOT=${HOME}/spack
. ${SPACK_ROOT}/share/spack/setup-env.sh

export INTEL_LICENSE_FILE=28518@hpc-admin1.hpc.nrel.gov

for i in ICCCFG ICPCCFG IFORTCFG
do
  export $i=${SPACK_ROOT}/etc/spack/intel.cfg
done
