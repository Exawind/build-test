from spack import *


class CatalystIossAdapter(CMakePackage):
    """Adapter for Trilinos Ioss and Paraview Catalyst"""

    homepage = "https://github.com/nalucfd/naluspack"
    url      = "https://github.com/nalucfd/naluspack.git"

    version('develop', 'aa5266fddb8554d39c6087550d3c8b27',
            url='https://github.com/NaluCFD/NaluSpack/raw/master/spack_config/custom_package_files/catalyst-ioss-adapter/ParaViewCatalystIossAdapter.tar.gz')

    depends_on('paraview+mpi+python+osmesa')

    def cmake_args(self):
        spec = self.spec
        options = []

        options.extend([
            '-DParaView_DIR:PATH=%s' % spec['paraview'].prefix + '/lib/cmake/paraview-5.4'
        ])

        return options
