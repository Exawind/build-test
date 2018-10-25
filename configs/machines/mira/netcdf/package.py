# Copyright 2013-2018 Lawrence Livermore National Security, LLC and other
# Spack Project Developers. See the top-level COPYRIGHT file for details.
#
# SPDX-License-Identifier: (Apache-2.0 OR MIT)

from spack import *

import numbers


def is_integral(x):
    """Any integer value"""
    try:
        return isinstance(int(x), numbers.Integral) and not isinstance(x, bool)
    except ValueError:
        return False


class Netcdf(AutotoolsPackage):
    """NetCDF is a set of software libraries and self-describing,
    machine-independent data formats that support the creation, access,
    and sharing of array-oriented scientific data."""

    homepage = "http://www.unidata.ucar.edu/software/netcdf"
    url      = "http://www.gfd-dennou.org/arch/netcdf/unidata-mirror/netcdf-4.3.3.tar.gz"

    # Version 4.4.1.1 is having problems in tests
    #    https://github.com/Unidata/netcdf-c/issues/343
    version('4.6.1', 'ee81c593efc8a6229d9bcb350b6d7849')
    version('4.4.1.1', '503a2d6b6035d116ed53b1d80c811bda')
    # netcdf@4.4.1 can crash on you (in real life and in tests).  See:
    #    https://github.com/Unidata/netcdf-c/issues/282
    version('4.4.1',   '7843e35b661c99e1d49e60791d5072d8')
    version('4.4.0',   'cffda0cbd97fdb3a06e9274f7aef438e')
    version('4.3.3.1', '5c9dad3705a3408d27f696e5b31fb88c')
    version('4.3.3',   '5fbd0e108a54bd82cb5702a73f56d2ae')

    variant('mpi', default=True,
            description='Enable parallel I/O for netcdf-4')
    variant('parallel-netcdf', default=True,
            description='Enable parallel I/O for classic files')
    variant('hdf4', default=False, description='Enable HDF4 support')
    variant('shared', default=False, description='Enable shared library')
    variant('dap', default=False, description='Enable DAP support')

    # It's unclear if cdmremote can be enabled if '--enable-netcdf-4' is passed
    # to the configure script. Since netcdf-4 support is mandatory we comment
    # this variant out.
    # variant('cdmremote', default=False,
    #         description='Enable CDM Remote support')

    # These variants control the number of dimensions (i.e. coordinates and
    # attributes) and variables (e.g. time, entity ID, number of coordinates)
    # that can be used in any particular NetCDF file.
    variant(
        'maxdims',
        default=1024,
        description='Defines the maximum dimensions of NetCDF files.',
        values=is_integral
    )
    variant(
        'maxvars',
        default=8192,
        description='Defines the maximum variables of NetCDF files.',
        values=is_integral
    )

    depends_on("m4", type='build')
    depends_on("hdf", when='+hdf4')

    # curl 7.18.0 or later is required:
    # http://www.unidata.ucar.edu/software/netcdf/docs/getting_and_building_netcdf.html
    depends_on("curl@7.18.0:", when='+dap')
    # depends_on("curl@7.18.0:", when='+cdmremote')

    depends_on('parallel-netcdf', when='+parallel-netcdf')

    # We need to build with MPI wrappers if any of the two
    # parallel I/O features is enabled:
    # http://www.unidata.ucar.edu/software/netcdf/docs/getting_and_building_netcdf.html#build_parallel
    depends_on('mpi', when='+mpi')
    depends_on('mpi', when='+parallel-netcdf')

    # zlib 1.2.5 or later is required for netCDF-4 compression:
    # http://www.unidata.ucar.edu/software/netcdf/docs/getting_and_building_netcdf.html
    depends_on("zlib@1.2.5:")

    # High-level API of HDF5 1.8.9 or later is required for netCDF-4 support:
    # http://www.unidata.ucar.edu/software/netcdf/docs/getting_and_building_netcdf.html
    depends_on('hdf5@1.8.9:+hl')

    # Starting version 4.4.0, it became possible to disable parallel I/O even
    # if HDF5 supports it. For previous versions of the library we need
    # HDF5 without mpi support to disable parallel I/O.
    # The following doesn't work if hdf5+mpi by default and netcdf~mpi is
    # specified in packages.yaml
    # depends_on('hdf5~mpi', when='@:4.3~mpi')
    # Thus, we have to introduce a conflict
    conflicts('~mpi', when='@:4.3^hdf5+mpi',
              msg='netcdf@:4.3~mpi requires hdf5~mpi')

    # We need HDF5 with mpi support to enable parallel I/O.
    # The following doesn't work if hdf5~mpi by default and netcdf+mpi is
    # specified in packages.yaml
    # depends_on('hdf5+mpi', when='+mpi')
    # Thus, we have to introduce a conflict
    conflicts('+mpi', when='^hdf5~mpi',
              msg='netcdf+mpi requires hdf5+mpi')

    # NetCDF 4.4.0 and prior have compatibility issues with HDF5 1.10 and later
    # https://github.com/Unidata/netcdf-c/issues/250
    depends_on('hdf5@:1.8.999', when='@:4.4.0')

    # The feature was introduced in version 4.1.2
    # and was removed in version 4.4.0
    # conflicts('+cdmremote', when='@:4.1.1,4.4:')

    # The features were introduced in version 4.1.0
    conflicts('+parallel-netcdf', when='@:4.0')
    conflicts('+hdf4', when='@:4.0')

    def patch(self):
        try:
            max_dims = int(self.spec.variants['maxdims'].value)
            max_vars = int(self.spec.variants['maxvars'].value)
        except (ValueError, TypeError):
            raise TypeError('NetCDF variant values max[dims|vars] must be '
                            'integer values.')

        ff = FileFilter(join_path('include', 'netcdf.h'))
        ff.filter(r'^(#define\s+NC_MAX_DIMS\s+)\d+(.*)$',
                  r'\1{0}\2'.format(max_dims))
        ff.filter(r'^(#define\s+NC_MAX_VARS\s+)\d+(.*)$',
                  r'\1{0}\2'.format(max_vars))

    def configure_args(self):
        cflags = []
        cppflags = []
        ldflags = []
        libs = []

        config_args = ['--enable-v2',
                       '--enable-utilities',
                       '--enable-static',
                       '--enable-largefile',
                       '--enable-netcdf-4']

        # The flag was introduced in version 4.1.0
        if self.spec.satisfies('@4.1:'):
            config_args.append('--enable-fsync')

        # The flag was introduced in version 4.3.1
        #if self.spec.satisfies('@4.3.1:'):
        #    config_args.append('--enable-dynamic-loading')

        config_args += self.enable_or_disable('shared')

        #if '~shared' in self.spec:
            # We don't have shared libraries but we still want it to be
            # possible to use this library in shared builds
        #    cflags.append(self.compiler.pic_flag)

        config_args += self.enable_or_disable('dap')
        # config_args += self.enable_or_disable('cdmremote')

        # if '+dap' in self.spec or '+cdmremote' in self.spec:
        if '+dap' in self.spec:
            # Make sure Netcdf links against Spack's curl, otherwise it may
            # pick up system's curl, which can give link errors, e.g.:
            # undefined reference to `SSL_CTX_use_certificate_chain_file
            curl = self.spec['curl']
            curl_libs = curl.libs
            libs.append(curl_libs.link_flags)
            ldflags.append(curl_libs.search_flags)
            # TODO: figure out how to get correct flags via headers.cpp_flags
            cppflags.append('-I' + curl.prefix.include)

        if self.spec.satisfies('@4.4:'):
            if '+mpi' in self.spec:
                config_args.append('--enable-parallel4')
            else:
                config_args.append('--disable-parallel4')

        # Starting version 4.1.3, --with-hdf5= and other such configure options
        # are removed. Variables CPPFLAGS, LDFLAGS, and LD_LIBRARY_PATH must be
        # used instead.
        hdf5_hl = self.spec['hdf5:hl']
        cppflags.append(hdf5_hl.headers.cpp_flags)
        ldflags.append(hdf5_hl.libs.search_flags)

        if '+parallel-netcdf' in self.spec:
            config_args.append('--enable-pnetcdf')
            pnetcdf = self.spec['parallel-netcdf']
            cppflags.append(pnetcdf.headers.cpp_flags)
            # TODO: change to pnetcdf.libs.search_flags once 'parallel-netcdf'
            # package gets custom implementation of 'libs'
            ldflags.append('-L' + pnetcdf.prefix.lib)
        else:
            config_args.append('--disable-pnetcdf')

        if '+mpi' in self.spec or '+parallel-netcdf' in self.spec:
            config_args.append('CC=%s' % self.spec['mpi'].mpicc)

        config_args += self.enable_or_disable('hdf4')
        if '+hdf4' in self.spec:
            hdf4 = self.spec['hdf']
            cppflags.append(hdf4.headers.cpp_flags)
            # TODO: change to hdf4.libs.search_flags once 'hdf'
            # package gets custom implementation of 'libs' property.
            ldflags.append('-L' + hdf4.prefix.lib)
            # TODO: change to self.spec['jpeg'].libs.link_flags once the
            # implementations of 'jpeg' virtual package get 'jpeg_libs'
            # property.
            libs.append('-ljpeg')
            if '+szip' in hdf4:
                # This should also come from hdf4.libs
                libs.append('-lsz')

        # Fortran support
        # In version 4.2+, NetCDF-C and NetCDF-Fortran have split.
        # Use the netcdf-fortran package to install Fortran support.

        config_args.append('CFLAGS=' + ' '.join(cflags))
        config_args.append('CPPFLAGS=' + ' '.join(cppflags))
        config_args.append('LDFLAGS=' + ' '.join(ldflags))
        config_args.append('LIBS=' + ' '.join(libs))

        return config_args

    def check(self):
        # h5_test fails when run in parallel
        make('check', parallel=False)
