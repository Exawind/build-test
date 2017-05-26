from spack import *
import os
import sys

class NaluTrilinos(CMakePackage):
    """The Trilinos Project is an effort to develop algorithms and enabling
    technologies within an object-oriented software framework for the solution
    of large-scale, complex multi-physics engineering and scientific problems.
    A unique design feature of Trilinos is its focus on packages.
    """
    homepage = "https://trilinos.org/"
    base_url = "https://github.com/trilinos/Trilinos"

    version('master', git='https://github.com/trilinos/Trilinos.git', branch='master')
    version('develop', git='https://github.com/trilinos/Trilinos.git', branch='develop')

    variant('debug', default=False,
            description='Builds a RelWithDebInfo version of the libraries')

    depends_on('boost')
    depends_on('mpi')
    depends_on('netcdf')
    depends_on('parallel-netcdf')
    depends_on('superlu+fpic@4.3')
    depends_on('hdf5+mpi')
    depends_on('blas')
    depends_on('lapack')
    depends_on('zlib')

    def cmake_args(self):
        spec = self.spec
        blas = spec['blas'].libs
        lapack = spec['lapack'].libs
        options = []
        options.extend([
            '-DCMAKE_BUILD_TYPE:STRING=%s' % 
                ('RelWithDebInfo' if '+debug' in spec else 'RELEASE'),
            '-DTrilinos_ENABLE_CXX11=ON',
            '-DTrilinos_ENABLE_EXPLICIT_INSTANTIATION:BOOL=ON',
            '-DTpetra_INST_DOUBLE:BOOL=ON',
            '-DTpetra_INST_INT_LONG:BOOL=ON',
            '-DTpetra_INST_COMPLEX_DOUBLE=OFF',
            '-DTrilinos_ENABLE_TESTS:BOOL=OFF',
            '-DTrilinos_ENABLE_ALL_OPTIONAL_PACKAGES=OFF',
            '-DTrilinos_ALLOW_NO_PACKAGES:BOOL=OFF',
            '-DTPL_ENABLE_MPI=ON',
            '-DMPI_BASE_DIR:PATH=%s' % spec['mpi'].prefix,
            '-DTrilinos_ENABLE_Epetra:BOOL=OFF',
            '-DTrilinos_ENABLE_Tpetra:BOOL=ON',
            '-DTrilinos_ENABLE_ML:BOOL=OFF',
            '-DTrilinos_ENABLE_MueLu:BOOL=ON',
            '-DTrilinos_ENABLE_EpetraExt:BOOL=OFF',
            '-DTrilinos_ENABLE_AztecOO:BOOL=OFF',
            '-DTrilinos_ENABLE_Belos:BOOL=ON',
            '-DTrilinos_ENABLE_Ifpack2:BOOL=ON',
            '-DTrilinos_ENABLE_Amesos2:BOOL=ON',
            '-DTrilinos_ENABLE_Zoltan2:BOOL=ON',
            '-DTrilinos_ENABLE_Ifpack:BOOL=OFF',
            '-DTrilinos_ENABLE_Amesos:BOOL=OFF',
            '-DTrilinos_ENABLE_Zoltan:BOOL=ON',
            '-DTrilinos_ENABLE_STKMesh:BOOL=ON',
            '-DTrilinos_ENABLE_STKIO:BOOL=ON',
            '-DTrilinos_ENABLE_STKTransfer:BOOL=ON',
            '-DTrilinos_ENABLE_STKSearch:BOOL=ON',
            '-DTrilinos_ENABLE_STKUtil:BOOL=ON',
            '-DTrilinos_ENABLE_STKTopology:BOOL=ON',
            '-DTrilinos_ENABLE_STKUnit_tests:BOOL=ON',
            '-DTrilinos_ENABLE_STKUnit_test_utils:BOOL=ON',
            '-DTrilinos_ENABLE_Gtest:BOOL=ON',
            '-DTrilinos_ENABLE_STKClassic:BOOL=OFF',
            '-DTrilinos_ENABLE_SEACASExodus:BOOL=ON',
            '-DTrilinos_ENABLE_SEACASEpu:BOOL=ON',
            '-DTrilinos_ENABLE_SEACASExodiff:BOOL=ON',
            '-DTrilinos_ENABLE_SEACASNemspread:BOOL=ON',
            '-DTrilinos_ENABLE_SEACASNemslice:BOOL=ON',
            '-DTPL_ENABLE_SuperLU:BOOL=ON',
            '-DSuperLU_ROOT:PATH=%s' % spec['superlu'].prefix,
            '-DTPL_ENABLE_Netcdf:STRING=ON',
            '-DNetCDF_ROOT:PATH=%s' % spec['netcdf'].prefix,
            '-DTPL_Netcdf_Enables_Netcdf4:BOOL=ON',
            '-DTPL_Netcdf_PARALLEL:BOOL=ON',
            '-DTPL_ENABLE_Pnetcdf:BOOL=ON',
            '-DPNetCDF_ROOT:PATH=%s' % spec['parallel-netcdf'].prefix,
            '-DTPL_ENABLE_HDF5:BOOL=ON',
            '-DHDF5_INCLUDE_DIRS:PATH=%s' % spec['hdf5'].prefix.include,
            '-DHDF5_LIBRARY_DIRS:PATH=%s' % spec['hdf5'].prefix.lib,
            '-DTPL_ENABLE_Zlib:STRING=ON',
            '-DZlib_ROOT:PATH=%s' % spec['zlib'].prefix,
            '-DTPL_ENABLE_Boost:BOOL=ON',
            '-DBoost_ROOT:PATH=%s' % spec['boost'].prefix,
            '-DTrilinos_ASSERT_MISSING_PACKAGES=OFF',
            '-DTPL_ENABLE_BLAS=ON',
            '-DBLAS_LIBRARY_NAMES=%s' % ';'.join(blas.names),
            '-DBLAS_LIBRARY_DIRS=%s' % ';'.join(blas.directories),
            '-DTPL_ENABLE_LAPACK=ON',
            '-DLAPACK_LIBRARY_NAMES=%s' % ';'.join(lapack.names),
            '-DLAPACK_LIBRARY_DIRS=%s' % ';'.join(lapack.directories)
        ])
            
        return options
