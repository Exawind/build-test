#!/bin/bash

#PBS -N run_nalu_merlin
#PBS -l nodes=8:ppn=64,walltime=4:00:00
#PBS -A windsim
#PBS -q knl
#PBS -j oe
#PBS -W umask=002

set -e

echo ------------------------------------------------------
echo "Job is running on node ${HOSTNAME} at `date`"
echo ------------------------------------------------------
if [ ! -z "${PBS_JOBID}" ]; then
  echo PBS: Qsub is running on ${PBS_O_HOST}
  echo PBS: Originating queue is ${PBS_O_QUEUE}
  echo PBS: Executing queue is ${PBS_QUEUE}
  echo PBS: Working directory is ${PBS_O_WORKDIR}
  echo PBS: Execution mode is ${PBS_ENVIRONMENT}
  echo PBS: Job identifier is ${PBS_JOBID}
  echo PBS: Job name is ${PBS_JOBNAME}
  echo PBS: Node file is ${PBS_NODEFILE}
  echo PBS: Node file contains $(cat ${PBS_NODEFILE})
  echo PBS: Current home directory is ${PBS_O_HOME}
  echo PBS: PATH = ${PBS_O_PATH}
  echo ------------------------------------------------------
fi
printf "\n"

cd ${PBS_O_WORKDIR}

# Set Spack executable and compiler to use
COMPILER=intel
SPACK_ROOT=${HOME}/spack
SPACK=${SPACK_ROOT}/bin/spack

# Setup base environment
module purge
module load GCCcore/4.9.2

# Load necessary modules created by spack
module use ${SPACK_ROOT}/share/spack/modules/$(${SPACK} arch)
module load $(${SPACK} module find openmpi %${COMPILER})

ln -sf /opt/ohpc/pub/nrel/eb/software/GCCcore/4.9.2/lib64/libstdc++.so.6 libstdc++.so.6

export OMP_NUM_THREADS=1
export OMP_PROC_BIND=spread
export OMP_PLACES=threads

# Run the simulation
(set -x; which mpirun)
(set -x; mpirun \
         -report-bindings \
         -x OMP_NUM_THREADS \
         -x OMP_PROC_BIND \
         -x OMP_PLACES \
         --hostfile ${PBS_NODEFILE} \
         -np 504 \
         --map-by ppr:1:core \
         --bind-to core \
         ${HOME}/Nalu/build/naluX -i abl_3km_256.i -o abl_3km_256.log)

unlink libstdc++.so.6
