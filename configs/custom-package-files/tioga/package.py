##############################################################################
# Copyright (c) 2013-2018, Lawrence Livermore National Security, LLC.
# Produced at the Lawrence Livermore National Laboratory.
#
# This file is part of Spack.
# Created by Todd Gamblin, tgamblin@llnl.gov, All rights reserved.
# LLNL-CODE-647188
#
# For details, see https://github.com/llnl/spack
# Please also see the LICENSE file for our notice and the LGPL.
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


class Tioga(CMakePackage):
    """Topology Independent Overset Grid Assembly (TIOGA)"""

    homepage = "https://github.com/jsitaraman/tioga"
    git      = "https://github.com/jsitaraman/tioga.git"

    # The master branch doesn't support CMake
    version('develop', branch='nalu-api')

    variant('shared', default=True,
            description="Enable building shared libraries")
    variant('pic', default=True,
            description="Position independent code")

    depends_on('mpi')

    # Tioga has the fortran module file problem with parallel builds
    parallel = False

    def cmake_args(self):
        spec = self.spec

        options = [
            '-DBUILD_SHARED_LIBS:BOOL=%s' % (
                'ON' if '+shared' in spec else 'OFF'),
            '-DCMAKE_POSITION_INDEPENDENT_CODE:BOOL=%s' % (
                'ON' if '+pic' in spec else 'OFF'),
            '-DMPI_CXX_COMPILER:PATH=%s' % spec['mpi'].mpicxx,
            '-DMPI_C_COMPILER:PATH=%s' % spec['mpi'].mpicc,
            '-DMPI_Fortran_COMPILER:PATH=%s' % spec['mpi'].mpifc
        ]

        return options
