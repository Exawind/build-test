#!/bin/bash

# Script for running nalu job on Mira
#qsub -A ExaWindFarm -t 30 -n 1 --mode script run.sh

cd /home/${USER}/Nalu/build/reg_tests/test_files/ablNeutralEdge && runjob --np 8 -p 16 --envs HDF5_DISABLE_VERSION_CHECK=2 --block $COBALT_PARTNAME --verbose=INFO : /home/${USER}/Nalu/build/naluX -i /home/${USER}/Nalu/reg_tests/test_files/ablNeutralEdge/ablNeutralEdge.i -o /home/${USER}/Nalu/build/reg_tests/test_files/ablNeutralEdge/ablNeutralEdge.log
