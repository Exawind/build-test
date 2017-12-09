from spack import *


class CatalystIossAdapter(CMakePackage):
    """Adapter for Trilinos Ioss and Paraview Catalyst"""

    homepage = "https://github.com/nalucfd/naluspack"
    url      = "https://github.com/nalucfd/naluspack.git"

    version('develop', '59163fd085a24c7a4c2170c70bb60fea',
            url='https://github.com/nalucfd/naluspack/raw/master/spack_config/custom_package_files/catalyst-ioss-adapter/ParaviewCatalystIossAdapter.tar.gz')

    depends_on('paraview+mpi+python+osmesa')

    def cmake_args(self):
        spec = self.spec
        options = []

        options.extend([
            '-DParaView_DIR:PATH=%s' % spec['paraview'].prefix + '/lib/cmake/paraview-5.4'
        ])

        return options
