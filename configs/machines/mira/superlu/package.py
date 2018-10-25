# Copyright 2013-2018 Lawrence Livermore National Security, LLC and other
# Spack Project Developers. See the top-level COPYRIGHT file for details.
#
# SPDX-License-Identifier: (Apache-2.0 OR MIT)

from spack import *
import glob
import os


class Superlu(Package):
    """SuperLU is a general purpose library for the direct solution of large,
    sparse, nonsymmetric systems of linear equations on high performance
    machines. SuperLU is designed for sequential machines."""

    homepage = "http://crd-legacy.lbl.gov/~xiaoye/SuperLU/#superlu"
    url      = "http://crd-legacy.lbl.gov/~xiaoye/SuperLU/superlu_5.2.1.tar.gz"

    version('5.2.1', '3a1a9bff20cb06b7d97c46d337504447')
    version('4.3', 'b72c6309f25e9660133007b82621ba7c')

    variant('pic',    default=True,
            description='Build with position independent code')

    depends_on('cmake', when='@5.2.1:', type='build')
    depends_on('blas')

    # CMake installation method
    def install(self, spec, prefix):
        cmake_args = [
            '-Denable_blaslib=OFF',
            '-DBLAS_blas_LIBRARY={0}'.format(spec['blas'].libs.joined())
        ]

        if '+pic' in spec:
            cmake_args.extend([
                '-DCMAKE_POSITION_INDEPENDENT_CODE=ON'
            ])

        cmake_args.extend(std_cmake_args)

        with working_dir('spack-build', create=True):
            cmake('..', *cmake_args)
            make()
            make('install')

    # Pre-cmake installation method
    @when('@4.3')
    def install(self, spec, prefix):
        config = []

        # Define make.inc file
        config.extend([
            'PLAT       = _x86_64',
            'SuperLUroot = %s' % self.stage.source_path,
            'SUPERLULIB = $(SuperLUroot)/lib/libsuperlu_{0}.a' \
            .format(self.spec.version),
            'BLASDEF    = -DUSE_VENDOR_BLAS',
            'BLASLIB    = -L/soft/libraries/alcf/current/gcc/BLAS/lib -Wl,-Bstatic -lblas -L/soft/libraries/alcf/current/gcc/LAPACK/lib -Wl,-Bstatic -llapack -L/soft/compilers/gcc/4.8.4/powerpc64-bgq-linux/lib -Wl,-Bstatic -lgfortran -Wl,--allow-multiple-definition',
            'TMGLIB     = libtmglib.a',
            'LIBS       = $(SUPERLULIB) $(BLASLIB)',
            'ARCH       = ar',
            'ARCHFLAGS  = cr',
            'RANLIB     = {0}'.format('ranlib' if which('ranlib') else 'echo'),
            'CC         = {0}'.format(os.environ['CC']),
            'FORTRAN    = {0}'.format(os.environ['FC']),
            'LOADER     = {0}'.format(os.environ['CC']),
            'CDEFS      = -DAdd_'
        ])

        if '+pic' in spec:
            config.extend([
                # Use these lines instead when pic_flag capability arrives
                'CFLAGS     = -O2 {0}'.format(self.compiler.pic_flag),
                'NOOPTS     = {0}'.format(self.compiler.pic_flag),
                'FFLAGS     = -O2 {0}'.format(self.compiler.pic_flag),
                'LOADOPTS   = {0}'.format(self.compiler.pic_flag)
            ])
        else:
            config.extend([
                'CFLAGS     = -O2',
                'NOOPTS     = ',
                'FFLAGS     = -O2',
                'LOADOPTS   = '
            ])

        # Write configuration options to make.inc file
        with open('make.inc', 'w') as inc:
            for option in config:
                inc.write('{0}\n'.format(option))

        make(parallel=False)

        # Install manually
        install_tree('lib', prefix.lib)
        headers = glob.glob(join_path('SRC', '*.h'))
        mkdir(prefix.include)
        for h in headers:
            install(h, prefix.include)
