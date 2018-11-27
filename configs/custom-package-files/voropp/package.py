# Copyright 2013-2018 Lawrence Livermore National Security, LLC and other
# Spack Project Developers. See the top-level COPYRIGHT file for details.
#
# SPDX-License-Identifier: (Apache-2.0 OR MIT)

from spack import *


class Voropp(MakefilePackage):
    """Voro++ is a open source software library for the computation of the
    Voronoi diagram, a widely-used tessellation that has applications in many
    scientific fields."""

    homepage = "http://math.lbl.gov/voro++/about.html"
    url      = "http://math.lbl.gov/voro++/download/dir/voro++-0.4.6.tar.gz"

    variant('pic', default=True,
            description='Position independent code')

    version('0.4.6', '2338b824c3b7b25590e18e8df5d68af9')

    def edit(self, spec, prefix):
        filter_file(r'CC=g\+\+',
                    'CC={0}'.format(self.compiler.cxx),
                    'config.mk')
        filter_file(r'PREFIX=/usr/local',
                    'PREFIX={0}'.format(self.prefix),
                    'config.mk')
        # We can safely replace the default CFLAGS which are:
        # CFLAGS=-Wall -ansi -pedantic -O3
        cflags = ''
        if '+pic' in spec:
            cflags += self.compiler.pic_flag
        filter_file(r'CFLAGS=.*',
                    'CFLAGS={0}'.format(cflags),
                    'config.mk')
