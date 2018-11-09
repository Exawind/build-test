# Copyright 2013-2018 Lawrence Livermore National Security, LLC and other
# Spack Project Developers. See the top-level COPYRIGHT file for details.
#
# SPDX-License-Identifier: (Apache-2.0 OR MIT)

from spack import *


class TrilinosCatalystIossAdapter(CMakePackage):
    """Adapter for Trilinos Seacas Ioss and Paraview Catalyst"""

    homepage = "https://trilinos.org/"
    url      = "https://github.com/trilinos/Trilinos/archive/trilinos-release-12-12-1.tar.gz"
    git      = "https://github.com/trilinos/Trilinos.git"

    version('develop', branch='develop')

    depends_on('bison')
    depends_on('flex')
    depends_on('paraview+mpi+python+osmesa')

    root_cmakelists_dir = 'packages/seacas/libraries/ioss/src/visualization/ParaViewCatalystIossAdapter'

    def cmake_args(self):
        spec = self.spec
        options = []

        paraview_version = 'paraview-%s' % spec['paraview'].version.up_to(2)

        options.extend([
            '-DParaView_DIR:PATH=%s' %
            spec['paraview'].prefix + '/lib/cmake/' + paraview_version
        ])

        return options
