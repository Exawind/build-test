##############################################################################
# Copyright (c) 2013-2017, Lawrence Livermore National Security, LLC.
# Produced at the Lawrence Livermore National Laboratory.
#
# This file is part of Spack.
# Created by Todd Gamblin, tgamblin@llnl.gov, All rights reserved.
# LLNL-CODE-647188
#
# For details, see https://github.com/spack/spack
# Please also see the NOTICE and LICENSE files for our notice and the LGPL.
#
# This program is free software; you can redistribute it and/or modify
# it under the terms of the GNU Lesser General Public License (as
# published by the Free Software Foundation) version 2.1, February 1999.
#
# This program is distributed in the hope that it will be useful, but
# WITHOUT ANY WARRANTY; without even the IMPLIED WARRANTY OF
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the terms and
# conditions of the GNU Lesser General Public License for more details.
#
# You should have received a copy of the GNU Lesser General Public
# License along with this program; if not, write to the Free Software
# Foundation, Inc., 59 Temple Place, Suite 330, Boston, MA 02111-1307 USA
##############################################################################
from spack import *


class TrilinosCatalystIossAdapter(CMakePackage):
    """Adapter for Trilinos Seacas Ioss and Paraview Catalyst"""

    homepage = "https://trilinos.org/"
    url      = "https://github.com/trilinos/Trilinos/archive/trilinos-release-12-12-1.tar.gz"
    git      = "https://github.com/trilinos/Trilinos.git"

    version('develop', branch='develop')
    version('master', branch='master')
    version('12.12.1', 'ecd4606fa332212433c98bf950a69cc7',
            url='https://github.com/trilinos/Trilinos/archive/trilinos-release-12-12-1.tar.gz')

    depends_on('bison@2.7')
    depends_on('flex@2.5.39')
    depends_on('catalyst+essentials+extras+python+rendering')

    root_cmakelists_dir = 'packages/seacas/libraries/ioss/src/visualization/ParaViewCatalystIossAdapter'

    def cmake_args(self):
        spec = self.spec
        options = []

        paraview_version = 'paraview-%s' % self.spec.version.up_to(2)

        options.extend([
            '-DParaView_DIR:PATH=%s' %
            spec['catalyst'].prefix + '/lib/cmake/' + paraview_version
        ])

        return options
