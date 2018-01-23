#!/bin/bash

# Script for running Nalu job on Mira
#qsub -A ExaWindFarm -t 30 -n 1 --mode script run.sh

#cd /home/rood/Nalu/build/reg_tests/test_files/ablNeutralEdge && runjob --np 8 -p 16 --envs HDF5_DISABLE_VERSION_CHECK=1 LD_LIBRARY_PATH=/soft/libraries/hdf5/1.8.17/cnk-gcc/current/lib:${LD_LIBRARY_PATH} --block $COBALT_PARTNAME --verbose=INFO : /home/rood/Nalu/build/naluX -i /home/rood/Nalu/reg_tests/test_files/ablNeutralEdge/ablNeutralEdge.i -o /home/rood/Nalu/reg_tests/test_files/ablNeutralEdge/ablNeutralEdge.log

cd /home/rood/Nalu/build/reg_tests/test_files/ablNeutralEdge && runjob --np 8 -p 16 --envs HDF5_DISABLE_VERSION_CHECK=2 --block $COBALT_PARTNAME --verbose=INFO : /home/rood/Nalu/build/naluX -i /home/rood/Nalu/reg_tests/test_files/ablNeutralEdge/ablNeutralEdge.i -o /home/rood/Nalu/build/reg_tests/test_files/ablNeutralEdge/ablNeutralEdge.log
