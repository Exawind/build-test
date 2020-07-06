#!/bin/bash -l

COMPILER=gcc

export SPACK_ROOT=/projects/hfm/exawind/nalu-wind-testing/spack
source ${SPACK_ROOT}/share/spack/setup-env.sh

if [ "${COMPILER}" == 'gcc' ]; then
  export OMPI_MCA_opal_cuda_support=1
  export EXAWIND_CUDA_WRAPPER=${HOME}/exawind/Trilinos/packages/kokkos/bin/nvcc_wrapper
  export CUDA_LAUNCH_BLOCKING=1
  export CUDA_MANAGED_FORCE_DEVICE_ALLOC=1
  export KOKKOS_ARCH="SKX;Volta70"
  export NVCC_WRAPPER_DEFAULT_COMPILER=${CXX}
  export OMPI_CXX=${EXAWIND_CUDA_WRAPPER}
  export CUDACXX=$(which nvcc)
  C_COMPILER=mpicc
  FORTRAN_COMPILER=mpifort
elif [ "${COMPILER}" == 'intel' ]; then
  CXX_COMPILER=mpiicpc
  C_COMPILER=mpiicc
  FORTRAN_COMPILER=mpiifort
  FLAGS="-O2 -xSKYLAKE-AVX512"
fi
  
set -e

cmd() {
  echo "+ $@"
  eval "$@"
}

# Set up environment on Eagle
cmd "module purge"
cmd "module unuse ${MODULEPATH}"
cmd "module use /nopt/nrel/ecom/hpacf/compilers/modules"
cmd "module use /nopt/nrel/ecom/hpacf/utilities/modules"
if [ "${COMPILER}" == 'gcc' ]; then
  cmd "module use /projects/hfm/exawind/nalu-wind-testing/spack/share/spack/modules/linux-centos7-x86_64/gcc-7.4.0"
elif [ "${COMPILER}" == 'intel' ]; then
  cmd "module use /nopt/nrel/ecom/hpacf/software/modules/intel-18.0.4"
fi
cmd "module load gcc/7.4.0"
cmd "module load python/2.7.16"
cmd "module load git"
cmd "module load binutils"
if [ "${COMPILER}" == 'gcc' ]; then
  cmd "module load openmpi"
  cmd "module load netlib-lapack"
elif [ "${COMPILER}" == 'intel' ]; then
  cmd "module load intel-parallel-studio/cluster.2018.4"
  cmd "module load intel-mpi/2018.4.274"
  cmd "module load intel-mkl/2018.4.274"
fi
cmd "module load yaml-cpp"
cmd "module load cmake"
cmd "module load cuda/9.2.88"
cmd "module load boost"
cmd "module list"

# Set tmpdir to the scratch filesystem so it doesn't run out of space
cmd "mkdir -p ${HOME}/.tmp"
cmd "export TMPDIR=${HOME}/.tmp"

# Clean before cmake configure
#set +e
#cmd "rm -rf CMakeFiles"
#cmd "rm -f CMakeCache.txt"
#set -e

cmd "which cmake"
if [ "${COMPILER}" == 'gcc' ]; then
  cmd "which orterun"
elif [ "${COMPILER}" == 'intel' ]; then
  cmd "which mpirun"
fi

#(set -x; cmake ${HOME}/exawind/Trilinos -G 'Unix Makefiles' -DCMAKE_INSTALL_PREFIX:PATH=${HOME}/exawind/Trilinos/install -DCMAKE_BUILD_TYPE:STRING=Release -DCMAKE_VERBOSE_MAKEFILE:BOOL=ON -DCMAKE_INSTALL_RPATH_USE_LINK_PATH:BOOL=FALSE -DCMAKE_INSTALL_RPATH:STRING='${HOME}/exawind/Trilinos/install/lib;${HOME}/exawind/Trilinos/install/lib64;/lustre/eaglefs/projects/hfm/exawind/nalu-wind-testing/spack/opt/spack/linux-centos7-x86_64/gcc-7.4.0/boost-1.68.0-sapv6yf36ygmp6ozbu33n4yhbml7kaia/lib;/lustre/eaglefs/projects/hfm/exawind/nalu-wind-testing/spack/opt/spack/linux-centos7-x86_64/gcc-7.4.0/bzip2-1.0.6-uiz6twgudbvgh5zktkbxscslrteqt7lh/lib;/lustre/eaglefs/projects/hfm/exawind/nalu-wind-testing/spack/opt/spack/linux-centos7-x86_64/gcc-7.4.0/zlib-1.2.11-l3pxi6wfiwbxeb7s4njasl74g53vwuez/lib;/lustre/eaglefs/projects/hfm/exawind/nalu-wind-testing/spack/opt/spack/linux-centos7-x86_64/gcc-7.4.0/hdf5-1.10.4-mbbc656zhrcyr4iz53egxrxnfutx2fuk/lib;/lustre/eaglefs/projects/hfm/exawind/nalu-wind-testing/spack/opt/spack/linux-centos7-x86_64/gcc-7.4.0/openmpi-3.1.4-kuzrpughgfurzixeep7le673td4jjwq5/lib;/lustre/eaglefs/projects/hfm/exawind/nalu-wind-testing/spack/opt/spack/linux-centos7-x86_64/gcc-7.4.0/hwloc-1.11.11-vlwsr53rwi2kxtflx626o3k7ek4i4qhr/lib;/lustre/eaglefs/projects/hfm/exawind/nalu-wind-testing/spack/opt/spack/linux-centos7-x86_64/gcc-7.4.0/libpciaccess-0.13.5-xvjwdhl6rgpjowyh6grt2wgabv7pzouv/lib;/lustre/eaglefs/projects/hfm/exawind/nalu-wind-testing/spack/opt/spack/linux-centos7-x86_64/gcc-7.4.0/libxml2-2.9.8-i6rsnvq6j7y2dwl4fvxi6hvironw5tvj/lib;/lustre/eaglefs/projects/hfm/exawind/nalu-wind-testing/spack/opt/spack/linux-centos7-x86_64/gcc-7.4.0/libiconv-1.15-azfmw4o7xnqelflpilxnix2fcnqwnsd4/lib;/lustre/eaglefs/projects/hfm/exawind/nalu-wind-testing/spack/opt/spack/linux-centos7-x86_64/gcc-7.4.0/xz-5.2.4-z4frkdzyxpfcd47ddrc56vp3jhrfpyh4/lib;/lustre/eaglefs/projects/hfm/exawind/nalu-wind-testing/spack/opt/spack/linux-centos7-x86_64/gcc-7.4.0/numactl-2.0.12-uixprmrwwcjiu7sydpmravnkatp2j7ol/lib;/nopt/slurm/current/lib;/lustre/eaglefs/projects/hfm/exawind/nalu-wind-testing/spack/opt/spack/linux-centos7-x86_64/gcc-7.4.0/matio-1.5.13-ee6wm5wmzeox5qx2nzrpir7vhnlbyjcz/lib;/lustre/eaglefs/projects/hfm/exawind/nalu-wind-testing/spack/opt/spack/linux-centos7-x86_64/gcc-7.4.0/netcdf-4.6.1-2iyrtgwxat4rz7mkcphz3qdsv3mp2cna/lib;/lustre/eaglefs/projects/hfm/exawind/nalu-wind-testing/spack/opt/spack/linux-centos7-x86_64/gcc-7.4.0/parallel-netcdf-1.8.0-ka7hw2wvax2dr5e2lhpahdwcsepxoxji/lib;/lustre/eaglefs/projects/hfm/exawind/nalu-wind-testing/spack/opt/spack/linux-centos7-x86_64/gcc-7.4.0/superlu-4.3-kutz7udvff4krok2ajm6t75dmrvrcr2z/lib;/nopt/nrel/apps/cuda/9.2.88/lib64;/lustre/eaglefs/projects/hfm/exawind/nalu-wind-testing/spack/opt/spack/linux-centos7-x86_64/gcc-7.4.0/glm-0.9.7.1-tjxyyz7hbgobt6u5ppo74gl32h5eievx/lib64;/lustre/eaglefs/projects/hfm/exawind/nalu-wind-testing/spack/opt/spack/linux-centos7-x86_64/gcc-7.4.0/netlib-lapack-3.8.0-c7ytzgkm3ne3oby4scffax4z2oeaasev/lib64' -DCMAKE_PREFIX_PATH:STRING='/lustre/eaglefs/projects/hfm/exawind/nalu-wind-testing/spack/opt/spack/linux-centos7-x86_64/gcc-7.4.0/cmake-3.13.4-x6agtwbf3be2fnrwckviyongxvpnkado;/lustre/eaglefs/projects/hfm/exawind/nalu-wind-testing/spack/opt/spack/linux-centos7-x86_64/gcc-7.4.0/netlib-lapack-3.8.0-c7ytzgkm3ne3oby4scffax4z2oeaasev;/lustre/eaglefs/projects/hfm/exawind/nalu-wind-testing/spack/opt/spack/linux-centos7-x86_64/gcc-7.4.0/boost-1.68.0-sapv6yf36ygmp6ozbu33n4yhbml7kaia;/lustre/eaglefs/projects/hfm/exawind/nalu-wind-testing/spack/opt/spack/linux-centos7-x86_64/gcc-7.4.0/matio-1.5.13-ee6wm5wmzeox5qx2nzrpir7vhnlbyjcz;/lustre/eaglefs/projects/hfm/exawind/nalu-wind-testing/spack/opt/spack/linux-centos7-x86_64/gcc-7.4.0/glm-0.9.7.1-tjxyyz7hbgobt6u5ppo74gl32h5eievx;/lustre/eaglefs/projects/hfm/exawind/nalu-wind-testing/spack/opt/spack/linux-centos7-x86_64/gcc-7.4.0/zlib-1.2.11-l3pxi6wfiwbxeb7s4njasl74g53vwuez;/nopt/nrel/apps/cuda/9.2.88;/lustre/eaglefs/projects/hfm/exawind/nalu-wind-testing/spack/opt/spack/linux-centos7-x86_64/gcc-7.4.0/openmpi-3.1.4-kuzrpughgfurzixeep7le673td4jjwq5;/lustre/eaglefs/projects/hfm/exawind/nalu-wind-testing/spack/opt/spack/linux-centos7-x86_64/gcc-7.4.0/netcdf-4.6.1-2iyrtgwxat4rz7mkcphz3qdsv3mp2cna;/lustre/eaglefs/projects/hfm/exawind/nalu-wind-testing/spack/opt/spack/linux-centos7-x86_64/gcc-7.4.0/parallel-netcdf-1.8.0-ka7hw2wvax2dr5e2lhpahdwcsepxoxji;/lustre/eaglefs/projects/hfm/exawind/nalu-wind-testing/spack/opt/spack/linux-centos7-x86_64/gcc-7.4.0/superlu-4.3-kutz7udvff4krok2ajm6t75dmrvrcr2z;/lustre/eaglefs/projects/hfm/exawind/nalu-wind-testing/spack/opt/spack/linux-centos7-x86_64/gcc-7.4.0/hdf5-1.10.4-mbbc656zhrcyr4iz53egxrxnfutx2fuk' -DBUILD_SHARED_LIBS:BOOL=OFF -DKOKKOS_ARCH:STRING='SKX;Volta70' -DMPI_USE_COMPILER_WRAPPERS:BOOL=ON -DMPI_CXX_COMPILER:FILEPATH=/lustre/eaglefs/projects/hfm/exawind/nalu-wind-testing/spack/opt/spack/linux-centos7-x86_64/gcc-7.4.0/openmpi-3.1.4-kuzrpughgfurzixeep7le673td4jjwq5/bin/mpic++ -DMPI_C_COMPILER:FILEPATH=/lustre/eaglefs/projects/hfm/exawind/nalu-wind-testing/spack/opt/spack/linux-centos7-x86_64/gcc-7.4.0/openmpi-3.1.4-kuzrpughgfurzixeep7le673td4jjwq5/bin/mpicc -DMPI_Fortran_COMPILER:FILEPATH=/lustre/eaglefs/projects/hfm/exawind/nalu-wind-testing/spack/opt/spack/linux-centos7-x86_64/gcc-7.4.0/openmpi-3.1.4-kuzrpughgfurzixeep7le673td4jjwq5/bin/mpif90 -DTrilinos_ENABLE_OpenMP:BOOL=OFF -DKokkos_ENABLE_OpenMP:BOOL=OFF -DTpetra_INST_OPENMP:BOOL=OFF -DTrilinos_ENABLE_CUDA:BOOL=ON -DTPL_ENABLE_CUDA:BOOL=ON -DCMAKE_CXX_FLAGS=--remove-duplicate-link-files -DKokkos_ENABLE_CUDA:BOOL=ON -DKokkos_ENABLE_Cuda_UVM:BOOL=ON -DTpetra_ENABLE_CUDA:BOOL=ON -DTpetra_INST_CUDA:BOOL=ON -DKokkos_ENABLE_Cuda_Lambda:BOOL=ON -DKOKKOS_ENABLE_CUDA_RELOCATABLE_DEVICE_CODE:BOOL=ON -DKOKKOS_ENABLE_DEPRECATED_CODE:BOOL=OFF -DTpetra_INST_SERIAL:BOOL=ON -DTrilinos_ENABLE_CXX11:BOOL=ON -DTrilinos_ENABLE_EXPLICIT_INSTANTIATION:BOOL=ON -DTpetra_INST_DOUBLE:BOOL=ON -DTpetra_INST_COMPLEX_DOUBLE:BOOL=OFF -DTrilinos_ENABLE_TESTS:BOOL=OFF -DTrilinos_ENABLE_ALL_OPTIONAL_PACKAGES:BOOL=OFF -DTrilinos_ASSERT_MISSING_PACKAGES:BOOL=OFF -DTrilinos_ALLOW_NO_PACKAGES:BOOL=OFF -DTrilinos_ENABLE_Epetra:BOOL=OFF -DTrilinos_ENABLE_Tpetra:BOOL=ON -DTrilinos_ENABLE_KokkosKernels:BOOL=ON -DTrilinos_ENABLE_ML:BOOL=OFF -DTrilinos_ENABLE_MueLu:BOOL=ON -DXpetra_ENABLE_Kokkos_Refactor:BOOL=ON -DMueLu_ENABLE_Kokkos_Refactor:BOOL=ON -DTrilinos_ENABLE_EpetraExt:BOOL=OFF -DTrilinos_ENABLE_AztecOO:BOOL=OFF -DTrilinos_ENABLE_Belos:BOOL=ON -DTrilinos_ENABLE_Ifpack2:BOOL=ON -DTrilinos_ENABLE_Amesos2:BOOL=ON -DAmesos2_ENABLE_SuperLU:BOOL=ON -DAmesos2_ENABLE_KLU2:BOOL=OFF -DTrilinos_ENABLE_Zoltan2:BOOL=ON -DTrilinos_ENABLE_Ifpack:BOOL=OFF -DTrilinos_ENABLE_Amesos:BOOL=OFF -DTrilinos_ENABLE_Zoltan:BOOL=ON -DTrilinos_ENABLE_STK:BOOL=ON -DTrilinos_ENABLE_Gtest:BOOL=ON -DTrilinos_ENABLE_SEACASExodus:BOOL=ON -DTrilinos_ENABLE_SEACASEpu:BOOL=ON -DTrilinos_ENABLE_SEACASExodiff:BOOL=ON -DTrilinos_ENABLE_SEACASNemspread:BOOL=ON -DTrilinos_ENABLE_SEACASNemslice:BOOL=ON -DTrilinos_ENABLE_SEACASIoss:BOOL=ON -DTPL_ENABLE_MPI:BOOL=ON -DTPL_ENABLE_Boost:BOOL=ON -DBoostLib_INCLUDE_DIRS:PATH=/lustre/eaglefs/projects/hfm/exawind/nalu-wind-testing/spack/opt/spack/linux-centos7-x86_64/gcc-7.4.0/boost-1.68.0-sapv6yf36ygmp6ozbu33n4yhbml7kaia/include -DBoostLib_LIBRARY_DIRS:PATH=/lustre/eaglefs/projects/hfm/exawind/nalu-wind-testing/spack/opt/spack/linux-centos7-x86_64/gcc-7.4.0/boost-1.68.0-sapv6yf36ygmp6ozbu33n4yhbml7kaia/lib -DBoost_INCLUDE_DIRS:PATH=/lustre/eaglefs/projects/hfm/exawind/nalu-wind-testing/spack/opt/spack/linux-centos7-x86_64/gcc-7.4.0/boost-1.68.0-sapv6yf36ygmp6ozbu33n4yhbml7kaia/include -DBoost_LIBRARY_DIRS:PATH=/lustre/eaglefs/projects/hfm/exawind/nalu-wind-testing/spack/opt/spack/linux-centos7-x86_64/gcc-7.4.0/boost-1.68.0-sapv6yf36ygmp6ozbu33n4yhbml7kaia/lib -DTPL_ENABLE_SuperLU:BOOL=ON -DSuperLU_LIBRARY_DIRS=/lustre/eaglefs/projects/hfm/exawind/nalu-wind-testing/spack/opt/spack/linux-centos7-x86_64/gcc-7.4.0/superlu-4.3-kutz7udvff4krok2ajm6t75dmrvrcr2z/lib -DSuperLU_INCLUDE_DIRS=/lustre/eaglefs/projects/hfm/exawind/nalu-wind-testing/spack/opt/spack/linux-centos7-x86_64/gcc-7.4.0/superlu-4.3-kutz7udvff4krok2ajm6t75dmrvrcr2z/include -DTPL_ENABLE_Netcdf:BOOL=ON -DNetCDF_ROOT:PATH=/lustre/eaglefs/projects/hfm/exawind/nalu-wind-testing/spack/opt/spack/linux-centos7-x86_64/gcc-7.4.0/netcdf-4.6.1-2iyrtgwxat4rz7mkcphz3qdsv3mp2cna -DTPL_Netcdf_PARALLEL:BOOL=ON -DTPL_Netcdf_Enables_Netcdf4:BOOL=ON -DTPL_ENABLE_Pnetcdf:BOOL=ON -DPNetCDF_ROOT:PATH=/lustre/eaglefs/projects/hfm/exawind/nalu-wind-testing/spack/opt/spack/linux-centos7-x86_64/gcc-7.4.0/parallel-netcdf-1.8.0-ka7hw2wvax2dr5e2lhpahdwcsepxoxji -DTPL_ENABLE_HDF5:BOOL=ON -DHDF5_ROOT:PATH=/lustre/eaglefs/projects/hfm/exawind/nalu-wind-testing/spack/opt/spack/linux-centos7-x86_64/gcc-7.4.0/hdf5-1.10.4-mbbc656zhrcyr4iz53egxrxnfutx2fuk -DHDF5_NO_SYSTEM_PATHS:BOOL=ON -DTPL_ENABLE_Zlib:BOOL=ON -DZlib_ROOT:PATH=/lustre/eaglefs/projects/hfm/exawind/nalu-wind-testing/spack/opt/spack/linux-centos7-x86_64/gcc-7.4.0/zlib-1.2.11-l3pxi6wfiwbxeb7s4njasl74g53vwuez -DTPL_ENABLE_BLAS:BOOL=ON -DBLAS_LIBRARY_NAMES=blas -DBLAS_LIBRARY_DIRS=/lustre/eaglefs/projects/hfm/exawind/nalu-wind-testing/spack/opt/spack/linux-centos7-x86_64/gcc-7.4.0/netlib-lapack-3.8.0-c7ytzgkm3ne3oby4scffax4z2oeaasev/lib64)

(set -x; nice make -j 16 install)
