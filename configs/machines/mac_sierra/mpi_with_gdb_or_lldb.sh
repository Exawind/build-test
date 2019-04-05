#!/bin/bash

# How to get a stack trace with MPI and GDB or LLDB

COMPILER=clang
SPACK_EXE=${HOME}/spack/bin/spack

export PATH=$(${SPACK_EXE} location -i cmake %${COMPILER})/bin:${PATH}
export PATH=$(${SPACK_EXE} location -i openmpi %${COMPILER})/bin:${PATH}

# GDB non-interactive something like this
#mpiexec -n 2 gdb /Users/jrood/exawind/nalu-wind/build/naluX -ex "set width 1000" -ex "thread apply all bt" -ex run -ex bt -ex "set confirm off" -ex quit -ex "set args -i /Users/jrood/exawind/nalu-wind/reg_tests/test_files/ductElemWedge/ductElemWedge.i -o ductElemWedge.log"

# LLDB interactive with xterm per rank
mpiexec -n 2 xterm -e lldb -- /Users/jrood/exawind/nalu-wind/build/naluX -i /Users/jrood/exawind/nalu-wind/reg_tests/test_files/ductElemWedge/ductElemWedge.i -o ductElemWedge.log
# Then type "run" in each process and then "bt" for backtrace
