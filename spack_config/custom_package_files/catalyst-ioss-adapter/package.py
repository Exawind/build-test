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


class CatalystIossAdapter(CMakePackage):
    """Adapter for Trilinos Ioss and Paraview Catalyst"""

    homepage = "https://github.com/nalucfd/naluspack"
    url      = "https://github.com/nalucfd/naluspack.git"

    version('develop', 'aa5266fddb8554d39c6087550d3c8b27',
            url='https://github.com/NaluCFD/NaluSpack/raw/master/spack_config/custom_package_files/catalyst-ioss-adapter/ParaViewCatalystIossAdapter.tar.gz')

    depends_on('bison@2.7')
    depends_on('flex@2.5.39')
    depends_on('paraview+mpi+python+osmesa@5.4.1')

    def cmake_args(self):
        spec = self.spec
        options = []

        options.extend([
            '-DParaView_DIR:PATH=%s' %
            spec['paraview'].prefix + '/lib/cmake/paraview-5.4'
        ])

        return options
