# Copyright 2013-2018 Lawrence Livermore National Security, LLC and other
# Spack Project Developers. See the top-level COPYRIGHT file for details.
#
# SPDX-License-Identifier: (Apache-2.0 OR MIT)

from spack import *
import sys


class NaluWind(CMakePackage):
    """Nalu-Wind: Wind energy focused variant of Nalu."""

    homepage = "https://github.com/exawind/nalu-wind"
    git      = "https://github.com/exawind/nalu-wind.git"

    maintainers = ['jrood-nrel']

    tags = ['ecp', 'ecp-apps']

    version('master', branch='master')

    # Options
    variant('shared', default=(sys.platform != 'darwin'),
            description='Build Trilinos as shared library')
    variant('pic', default=True,
            description='Position independent code')
    # Third party libraries
    variant('openfast', default=False,
            description='Compile with OpenFAST support')
    variant('tioga', default=False,
            description='Compile with Tioga support')
    variant('hypre', default=False,
            description='Compile with Hypre support')
    variant('catalyst', default=False,
            description='Compile with Catalyst support')
    variant('fftw', default=False,
            description='Compile with FFTW support')

    # Required dependencies
    depends_on('mpi')
    depends_on('yaml-cpp@0.5.3:')
    depends_on('trilinos+exodus+tpetra+muelu+belos+ifpack2+amesos2+zoltan+stk+boost~superlu-dist+superlu+hdf5+zlib+pnetcdf+shards~hypre@master,develop', when='+shared')
    # Cannot build Trilinos as a shared library with STK on Darwin
    # https://github.com/trilinos/Trilinos/issues/2994
    depends_on('trilinos~shared+exodus+tpetra+muelu+belos+ifpack2+amesos2+zoltan+stk+boost~superlu-dist+superlu+hdf5+zlib+pnetcdf+shards~hypre@master,develop', when='~shared')
    # Optional dependencies
    depends_on('openfast+cxx', when='+openfast')
    depends_on('tioga', when='+tioga')
    depends_on('hypre+mpi+int64', when='+hypre')
    depends_on('trilinos-catalyst-ioss-adapter', when='+catalyst')
    depends_on('fftw+mpi', when='+fftw')

    def cmake_args(self):
        spec = self.spec
        options = []

        options.extend([
            '-DTrilinos_DIR:PATH=%s' % spec['trilinos'].prefix,
            '-DYAML_DIR:PATH=%s' % spec['yaml-cpp'].prefix,
            '-DCMAKE_C_COMPILER=%s' % spec['mpi'].mpicc,
            '-DCMAKE_CXX_COMPILER=%s' % spec['mpi'].mpicxx,
            '-DCMAKE_Fortran_COMPILER=%s' % spec['mpi'].mpifc,
            '-DMPI_C_COMPILER=%s' % spec['mpi'].mpicc,
            '-DMPI_CXX_COMPILER=%s' % spec['mpi'].mpicxx,
            '-DMPI_Fortran_COMPILER=%s' % spec['mpi'].mpifc,
            '-DCMAKE_POSITION_INDEPENDENT_CODE:BOOL=%s' % (
                'ON' if '+pic' in spec else 'OFF'),
        ])

        if '+openfast' in spec:
            options.extend([
                '-DENABLE_OPENFAST:BOOL=ON',
                '-DOpenFAST_DIR:PATH=%s' % spec['openfast'].prefix
            ])
        else:
            options.append('-DENABLE_OPENFAST:BOOL=OFF')

        if '+tioga' in spec:
            options.extend([
                '-DENABLE_TIOGA:BOOL=ON',
                '-DTIOGA_DIR:PATH=%s' % spec['tioga'].prefix
            ])
        else:
            options.append('-DENABLE_TIOGA:BOOL=OFF')

        if '+hypre' in spec:
            options.extend([
                '-DENABLE_HYPRE:BOOL=ON',
                '-DHYPRE_DIR:PATH=%s' % spec['hypre'].prefix
            ])
        else:
            options.append('-DENABLE_HYPRE:BOOL=OFF')

        if '+catalyst' in spec:
            options.extend([
                '-DENABLE_PARAVIEW_CATALYST:BOOL=ON',
                '-DPARAVIEW_CATALYST_INSTALL_PATH:PATH=%s' %
                spec['trilinos-catalyst-ioss-adapter'].prefix
            ])
        else:
            options.append('-DENABLE_PARAVIEW_CATALYST:BOOL=OFF')

        if '+fftw' in spec:
            options.extend([
                '-DENABLE_FFTW:BOOL=ON',
                '-DFFTW_DIR:PATH=%s' % spec['fftw'].prefix
            ])
        else:
            options.append('-DENABLE_HYPRE:BOOL=OFF')

        return options
