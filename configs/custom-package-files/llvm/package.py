##############################################################################
# Copyright (c) 2013-2018, Lawrence Livermore National Security, LLC.
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


class Llvm(CMakePackage):
    """The LLVM Project is a collection of modular and reusable compiler and
       toolchain technologies. Despite its name, LLVM has little to do
       with traditional virtual machines, though it does provide helpful
       libraries that can be used to build them. The name "LLVM" itself
       is not an acronym; it is the full name of the project.
    """

    homepage = 'http://llvm.org/'
    url = 'http://llvm.org/releases/3.7.1/llvm-3.7.1.src.tar.xz'
    list_url = 'http://releases.llvm.org/download.html'

    family = 'compiler'  # Used by lmod

    # currently required by mesa package
    version('3.0', 'a8e5f5f1c1adebae7b4a654c376a6005',
            url='http://llvm.org/releases/3.0/llvm-3.0.tar.gz')

    # NOTE: The debug version of LLVM is an order of magnitude larger than
    # the release version, and may take up 20-30 GB of space. If you want
    # to save space, build with `build_type=Release`.

    variant('clang', default=True,
            description="Build the LLVM C/C++/Objective-C compiler frontend")
    variant('lldb', default=True, description="Build the LLVM debugger")
    variant('lld', default=True, description="Build the LLVM linker")
    variant('internal_unwind', default=True,
            description="Build the libcxxabi libunwind")
    variant('polly', default=True,
            description="Build the LLVM polyhedral optimization plugin, "
            "only builds for 3.7.0+")
    variant('libcxx', default=True,
            description="Build the LLVM C++ standard library")
    variant('compiler-rt', default=True,
            description="Build LLVM compiler runtime, including sanitizers")
    variant('gold', default=True,
            description="Add support for LTO with the gold linker plugin")
    variant('shared_libs', default=False,
            description="Build all components as shared libraries, faster, "
            "less memory to build, less stable")
    variant('link_dylib', default=False,
            description="Build and link the libLLVM shared library rather "
            "than static")
    variant('all_targets', default=True,
            description="Build all supported targets, default targets "
            "<current arch>,NVPTX,AMDGPU,CppBackend")
    variant('build_type', default='Release',
            description='CMake build type',
            values=('Debug', 'Release', 'RelWithDebInfo', 'MinSizeRel'))
    variant('python', default=False, description="Install python bindings")
    extends('python', when='+python')

    # Build dependency
    depends_on('cmake@3.4.3:', type='build')

    # Universal dependency
    depends_on('python@2.7:2.8', when='@:4.999')
    depends_on('python')
    depends_on('py-lit', type=('build', 'run'))

    # lldb dependencies
    depends_on('ncurses', when='+lldb')
    depends_on('swig', when='+lldb')
    depends_on('libedit', when='+lldb')
    depends_on('py-six', when='@5.0.0: +lldb +python')

    # gold support
    depends_on('binutils+gold', when='+gold')

    # polly plugin
    depends_on('gmp', when='@:3.6.999 +polly')
    depends_on('isl', when='@:3.6.999 +polly')

    base_url = 'http://llvm.org/releases/%%(version)s/%(pkg)s-%%(version)s.src.tar.xz'
    llvm_url = base_url % {'pkg': 'llvm'}

    resources = {
        'compiler-rt': {
            'url': base_url % {'pkg': 'compiler-rt'},
            'destination': 'projects',
            'placement': 'compiler-rt',
            'variant': '+compiler-rt',
        },
        'openmp': {
            'url': base_url % {'pkg': 'openmp'},
            'destination': 'projects',
            'placement': 'openmp',
            'variant': '+clang',
        },
        'libcxx': {
            'url': base_url % {'pkg': 'libcxx'},
            'destination': 'projects',
            'placement': 'libcxx',
            'variant': '+libcxx',
        },
        'libcxxabi': {
            'url':  base_url % {'pkg': 'libcxxabi'},
            'destination': 'projects',
            'placement': 'libcxxabi',
            'variant': '+libcxx',
        },
        'cfe': {
            'url':  base_url % {'pkg': 'cfe'},
            'destination': 'tools',
            'placement': 'clang',
            'variant': '+clang',
        },
        'clang-tools-extra': {
            'url':  base_url % {'pkg': 'clang-tools-extra'},
            'destination': 'tools/clang/tools',
            'placement': 'extra',
            'variant': '+clang',
        },
        'lldb': {
            'url':  base_url % {'pkg': 'lldb'},
            'destination': 'tools',
            'placement': 'lldb',
            'variant': '+lldb',
        },
        'lld': {
            'url':  base_url % {'pkg': 'lld'},
            'destination': 'tools',
            'placement': 'lld',
            'variant': '+lld',
        },
        'polly': {
            'url':  base_url % {'pkg': 'polly'},
            'destination': 'tools',
            'placement': 'polly',
            'variant': '+polly',
        },
        'libunwind': {
            'url':  base_url % {'pkg': 'libunwind'},
            'destination': 'projects',
            'placement': 'libunwind',
            'variant': '+internal_unwind',
        },
    }
    releases = [
        {
            'version': 'trunk',
            'repo': 'http://llvm.org/svn/llvm-project/llvm/trunk',
            'resources': {
                'compiler-rt': 'http://llvm.org/svn/llvm-project/compiler-rt/trunk',
                'openmp': 'http://llvm.org/svn/llvm-project/openmp/trunk',
                'polly': 'http://llvm.org/svn/llvm-project/polly/trunk',
                'libcxx': 'http://llvm.org/svn/llvm-project/libcxx/trunk',
                'libcxxabi': 'http://llvm.org/svn/llvm-project/libcxxabi/trunk',
                'cfe': 'http://llvm.org/svn/llvm-project/cfe/trunk',
                'clang-tools-extra': 'http://llvm.org/svn/llvm-project/clang-tools-extra/trunk',
                'lldb': 'http://llvm.org/svn/llvm-project/lldb/trunk',
                'lld': 'http://llvm.org/svn/llvm-project/lld/trunk',
                'libunwind': 'http://llvm.org/svn/llvm-project/libunwind/trunk',
            }
        },
        {
            'version': '6.0.0',
            'md5': '788a11a35fa62eb008019b37187d09d2',
            'resources': {
                'compiler-rt': 'ba6368e894b5528e527d86a69d8533c6',
                'openmp': 'eb6b8d0318a950a8192933a3b500585d',
                'polly': 'e5808a3a1ed1c23f56dd1854b86689d0',
                'libcxx': '4ecad7dfd8ea636205d3ffef028df73a',
                'libcxxabi': '9d06327892fc5d8acec4ef2e2821ab3d',
                'cfe': '121b3896cb0c7765d690acc5d9495d24',
                'clang-tools-extra': '6b1d543116dab5a3caba10091d983743',
                'lldb': '1ec6498066e273b7261270f344b68121',
                'lld': '7ab2612417477b03538f11cd8b5e12f8',
                'libunwind': '022a4ee2c3bf7b6d151e0444f66aca64'
            }
        },
        {
            'version': '5.0.1',
            'md5': '3a4ec6dcbc71579eeaec7cb157fe2168',
            'resources': {
                'compiler-rt': '6329380d643fb5dc5f5abdd0d5eecd70',
                'openmp': '7f9c8f6aecd97df9c18187157ed2f813',
                'polly': '49c49fb61b0e73855fc21a60db9f5ab3',
                'libcxx': 'a9dd49822f2c82cef9a9240d1714a67c',
                'libcxxabi': '60972ef307539aa517c9878d45b43452',
                'cfe': 'e4daa278d8f252585ab73d196484bf11',
                'clang-tools-extra': 'c2bd3733c183b033b49f7a416c6dca36',
                'lldb': 'd64078681215b5935614b6b83b2d1463',
                'lld': 'a873c7fdaac647613d8eed2cb03d82de',
                'libunwind': 'ccf48200065481244d3d09828d54e87f',
            }
        },
        {
            'version': '5.0.0',
            'md5': '5ce9c5ad55243347ea0fdb4c16754be0',
            'resources': {
                'compiler-rt': 'da735894133589cbc6052c8ef06b1230',
                'openmp': '8be33c0f0a7ed3aab42be2f63988913d',
                'polly': 'dcbd08450e895a42f3986e2fe6524c92',
                'libcxx': 'a39241a3c9b4d2b7ce1246b9f527b400',
                'libcxxabi': '0158528a5a0ae1c74821bae2195ea782',
                'cfe': '699c448c6d6d0edb693c87beb1cc8c6e',
                'clang-tools-extra': '0cda05d1a61becb393eb63746963d7f5',
                'lldb': '8de19973d044ca2cfe325d4625a5cfef',
                'lld': 'a39cbecced3263feab9139b47118e062',
                'libunwind': '98fb2c677068c6f36727fb1d5397bca3',
            }
        },
        {
            'version': '4.0.1',
            'md5': 'a818e70321b91e2bb2d47e60edd5408f',
            'resources': {
                'compiler-rt': '0227ac853ce422125f8bb08f6ad5c995',
                'openmp': '23e5f720ae119165ba32627467fdc885',
                'polly': '0d4a3fa2eb446a378bbf01b220851b1f',
                'libcxx': 'c54f7938e2f393a2cead0af37ed99dfb',
                'libcxxabi': '55ba0be7daf8bf25ab629a9cfd3022a4',
                'cfe': 'a6c7b3e953f8b93e252af5917df7db97',
                'clang-tools-extra': 'cfd46027a0ab7eed483dfcc803e86bd9',
                'lldb': '908bdd777d3b527a914ba360477b8ab3',
                'lld': '39cd3512cddcfd7d37ef12066c961660',
                'libunwind': 'b72ec95fb784e61f15d6196414b92f5e',
            }
        },
        {
            'version': '4.0.0',
            'md5': 'ea9139a604be702454f6acf160b4f3a2',
            'resources': {
                'compiler-rt': '2ec11fb7df827b086341131c5d7f1814',
                'openmp': '3d06d2801dd4808f551a1a70068e01f5',
                'polly': 'f36e4e7cf872f8b3bbb9cdcddc5fd964',
                'libcxx': '4cf7df466e6f803ec4611ee410ff6781',
                'libcxxabi': '8b5d7b9bfcf7dec2dc901c8a6746f97c',
                'cfe': '756e17349fdc708c62974b883bf72d37',
                'clang-tools-extra': '99e711337ec3e9a8bb36e8dd62b2cd6e',
                'lldb': 'bd41ba7fcca55d2a554409bbccd34d2d',
                'lld': 'e5784656e0f38e3578f10ff7551d3896',
                'libunwind': '0c3534eaa11c0cae33a1dcf5f36ce287',
            }
        },
        {
            'version': '3.9.1',
            'md5': '3259018a7437e157f3642df80f1983ea',
            'resources': {
                'compiler-rt': 'aadc76e7e180fafb10fb729444e287a3',
                'openmp': 'f076916bf2f49229b4df9fa0bb002599',
                'polly': '2cc7fe2bd9539775ba140abfd375bec6',
                'libcxx': '75a3214224301fc543fa6a38bdf7efe0',
                'libcxxabi': '62fd584b38cc502172c2ffab041b5fcc',
                'cfe': '45713ec5c417ed9cad614cd283d786a1',
                'clang-tools-extra': '1a01d545a064fcbc46a2f05f6880d3d7',
                'lldb': '91399402f287d3f637db1207113deecb',
                'lld': '6254dd138e23b098df4ef7840c11e2c8',
                'libunwind': 'f273dd0ed638ad0601b23176a36f187b',
            }
        },
        {
            'version': '3.9.0',
            'md5': 'f2093e98060532449eb7d2fcfd0bc6c6',
            'resources': {
                'compiler-rt': 'b7ea34c9d744da16ffc0217b6990d095',
                'openmp': '5390164f2374e1444e82393541ecf6c7',
                'polly': '1cf328cbae25267749b68cfa6f113674',
                'libcxx': '0a11efefd864ce6f321194e441f7e569',
                'libcxxabi': 'd02642308e22e614af6b061b9b4fedfa',
                'cfe': '29e1d86bee422ab5345f5e9fb808d2dc',
                'clang-tools-extra': 'f4f663068c77fc742113211841e94d5e',
                'lldb': '968d053c3c3d7297983589164c6999e9',
                'lld': 'c23c895c0d855a0dc426af686538a95e',
                'libunwind': '3e5c87c723a456be599727a444b1c166',
            }
        },
        {
            'version': '3.8.1',
            'md5': '538467e6028bbc9259b1e6e015d25845',
            'resources': {
                'compiler-rt': 'f140db073d2453f854fbe01cc46f3110',
                'openmp': '078b8d4c51ad437a4f8b5989f5ec4156',
                'polly': '8a40e697a4ba1c8b640b85d074bd6e25',
                'libcxx': '1bc60150302ff76a0d79d6f9db22332e',
                'libcxxabi': '3c63b03ba2f30a01279ca63384a67773',
                'cfe': '4ff2f8844a786edb0220f490f7896080',
                'clang-tools-extra': '6e49f285d0b366cc3cab782d8c92d382',
                'lldb': '9e4787b71be8e432fffd31e13ac87623',
                'lld': '68cd069bf99c71ebcfbe01d557c0e14d',
                'libunwind': 'd66e2387e1d37a8a0c8fe6a0063a3bab',
            }
        },
        {
            'version': '3.8.0',
            'md5': '07a7a74f3c6bd65de4702bf941b511a0',
            'resources': {
                'compiler-rt': 'd6fcbe14352ffb708e4d1ac2e48bb025',
                'openmp': '8fd7cc35d48051613cf1e750e9f22e40',
                'polly': '1b3b20f52d34a4024e21a4ea7112caa7',
                'libcxx': 'd6e0bdbbee39f7907ad74fd56d03b88a',
                'libcxxabi': 'bbe6b4d72c7c5978550d370af529bcf7',
                'cfe': 'cc99e7019bb74e6459e80863606250c5',
                'clang-tools-extra': 'c2344f50e0eea0b402f0092a80ddc036',
                'lldb': 'a5da35ed9cc8c8817ee854e3dbfba00e',
                'lld': 'de33b5c6c77698ee2f8d024fbffb8df1',
                'libunwind': '162ade468607f153cca12be90b5194fa',
            }
        },
        {
            'version': '3.7.1',
            'md5': 'bf8b3a2c79e61212c5409041dfdbd319',
            'resources': {
                'compiler-rt': '1c6975daf30bb3b0473b53c3a1a6ff01',
                'openmp': 'b4ad08cda4e5c22e42b66062b140438e',
                'polly': '3a2a7367002740881637f4d47bca4dc3',
                'libcxx': 'f9c43fa552a10e14ff53b94d04bea140',
                'libcxxabi': '52d925afac9f97e9dcac90745255c169',
                'cfe': '0acd026b5529164197563d135a8fd83e',
                'clang-tools-extra': '5d49ff745037f061a7c86aeb6a24c3d2',
                'lldb': 'a106d8a0d21fc84d76953822fbaf3398',
                'lld': '6c3794e30fbe118a601fb694627f34f8',
                'libunwind': '814bd52c9247c5d04629658fbcb3ab8c',
            }
        },
        {
            'version': '3.7.0',
            'md5': 'b98b9495e5655a672d6cb83e1a180f8e',
            'resources': {
                'compiler-rt': '383c10affd513026f08936b5525523f5',
                'openmp': 'f482c86fdead50ba246a1a2b0bbf206f',
                'polly': '32f93ffc9cc7e042df22089761558f8b',
                'libcxx': '46aa5175cbe1ad42d6e9c995968e56dd',
                'libcxxabi': '5aa769e2fca79fa5335cfae8f6258772',
                'cfe': '8f9d27335e7331cf0a4711e952f21f01',
                'clang-tools-extra': 'd5a87dacb65d981a427a536f6964642e',
                'lldb': 'e5931740400d1dc3e7db4c7ba2ceff68',
                'lld': '91bd593a67293d84dad0bf11845546c2',
                'libunwind': '9a75392eb7eb8ed5c0840007e212baf5',
            }
        },
        {
            'version': '3.6.2',
            'md5': '0c1ee3597d75280dee603bae9cbf5cc2',
            'resources': {
                'compiler-rt': 'e3bc4eb7ba8c39a6fe90d6c988927f3c',
                'openmp': '65dd5863b9b270960a96817e9152b123',
                'libcxx': '22214c90697636ef960a49aef7c1823a',
                'libcxxabi': '17518e361e4e228f193dd91e8ef54ba2',
                'cfe': 'ff862793682f714bb7862325b9c06e20',
                'clang-tools-extra': '3ebc1dc41659fcec3db1b47d81575e06',
                'lldb': '51e5eb552f777b950bb0ff326e60d5f0',
                'lld': '7143cc4fa88851a9f9b9a03621fbb387',
            }
        },
        {
            'version': '3.5.1',
            'md5': '2d3d8004f38852aa679e5945b8ce0b14',
            'resources': {
                'compiler-rt': 'd626cfb8a9712cb92b820798ab5bc1f8',
                'openmp': '121ddb10167d7fc38b1f7e4b029cf059',
                'libcxx': '406f09b1dab529f3f7879f4d548329d2',
                'libcxxabi': 'b22c707e8d474a99865ad3c521c3d464',
                'cfe': '93f9532f8f7e6f1d8e5c1116907051cb',
                'clang-tools-extra': 'f13f31ed3038acadc6fa63fef812a246',
                'lldb': 'cc5ea8a414c62c33e760517f8929a204',
                'lld': '173be02b7ff4e5e31fbb0a591a03d7a3',
            }
        },
    ]

    for release in releases:
        if release['version'] == 'trunk':
            version(release['version'], svn=release['repo'])

            for name, repo in release['resources'].items():
                resource(name=name,
                         svn=repo,
                         destination=resources[name]['destination'],
                         when='@%s%s' % (release['version'],
                                         resources[name].get('variant', "")),
                         placement=resources[name].get('placement', None))
        else:
            version(release['version'], release['md5'], url=llvm_url % release)

            for name, md5 in release['resources'].items():
                resource(name=name,
                         url=resources[name]['url'] % release,
                         md5=md5,
                         destination=resources[name]['destination'],
                         when='@%s%s' % (release['version'],
                                         resources[name].get('variant', "")),
                         placement=resources[name].get('placement', None))

    conflicts('+clang_extra', when='~clang')
    conflicts('+lldb',        when='~clang')

    # Github issue #4986
    patch('llvm_gcc7.patch', when='@4.0.0:4.0.1+lldb %gcc@7.0:')

    def setup_environment(self, spack_env, run_env):
        spack_env.append_flags('CXXFLAGS', self.compiler.cxx11_flag)

        if '+clang' in self.spec:
            run_env.set('CC', join_path(self.spec.prefix.bin, 'clang'))
            run_env.set('CXX', join_path(self.spec.prefix.bin, 'clang++'))

    def cmake_args(self):
        spec = self.spec

        cmake_args = [
            '-DLLVM_REQUIRES_RTTI:BOOL=ON',
            '-DCLANG_DEFAULT_OPENMP_RUNTIME:STRING=libomp',
            '-DPYTHON_EXECUTABLE:PATH={0}'.format(spec['python'].command.path),
        ]

        if '+gold' in spec:
            cmake_args.append('-DLLVM_BINUTILS_INCDIR=' +
                              spec['binutils'].prefix.include)
        if '+polly' in spec:
            cmake_args.append('-DLINK_POLLY_INTO_TOOLS:Bool=ON')
        else:
            cmake_args.extend(['-DLLVM_EXTERNAL_POLLY_BUILD:Bool=OFF',
                               '-DLLVM_TOOL_POLLY_BUILD:Bool=OFF',
                               '-DLLVM_POLLY_BUILD:Bool=OFF',
                               '-DLLVM_POLLY_LINK_INTO_TOOLS:Bool=OFF'])

        if '+python' in spec and '+lldb' in spec and spec.satisfies('@5.0.0:'):
            cmake_args.append('-DLLDB_USE_SYSTEM_SIX:Bool=TRUE')
        if '+clang' not in spec:
            cmake_args.append('-DLLVM_EXTERNAL_CLANG_BUILD:Bool=OFF')
        if '+lldb' not in spec:
            cmake_args.extend(['-DLLVM_EXTERNAL_LLDB_BUILD:Bool=OFF',
                               '-DLLVM_TOOL_LLDB_BUILD:Bool=OFF'])
        if '+lld' not in spec:
            cmake_args.append('-DLLVM_TOOL_LLD_BUILD:Bool=OFF')
        if '+internal_unwind' not in spec:
            cmake_args.append('-DLLVM_EXTERNAL_LIBUNWIND_BUILD:Bool=OFF')
        if '+libcxx' in spec:
            if spec.satisfies('@3.9.0:'):
                cmake_args.append('-DCLANG_DEFAULT_CXX_STDLIB=libc++')
        else:
            cmake_args.append('-DLLVM_EXTERNAL_LIBCXX_BUILD:Bool=OFF')
            cmake_args.append('-DLLVM_EXTERNAL_LIBCXXABI_BUILD:Bool=OFF')
        if '+compiler-rt' not in spec:
            cmake_args.append('-DLLVM_EXTERNAL_COMPILER_RT_BUILD:Bool=OFF')

        if '+shared_libs' in spec:
            cmake_args.append('-DBUILD_SHARED_LIBS:Bool=ON')

        if '+link_dylib' in spec:
            cmake_args.append('-DLLVM_LINK_LLVM_DYLIB:Bool=ON')

        if '+all_targets' not in spec:  # all is default on cmake

            if spec.version < Version('3.9.0'):
                targets = ['CppBackend', 'NVPTX', 'AMDGPU']
            else:
                # Starting in 3.9.0 CppBackend is no longer a target (see
                # LLVM_ALL_TARGETS in llvm's top-level CMakeLists.txt for
                # the complete list of targets)
                targets = ['NVPTX', 'AMDGPU']

            if 'x86' in spec.architecture.target.lower():
                targets.append('X86')
            elif 'arm' in spec.architecture.target.lower():
                targets.append('ARM')
            elif 'aarch64' in spec.architecture.target.lower():
                targets.append('AArch64')
            elif 'sparc' in spec.architecture.target.lower():
                targets.append('Sparc')
            elif ('ppc' in spec.architecture.target.lower() or
                  'power' in spec.architecture.target.lower()):
                targets.append('PowerPC')

            cmake_args.append(
                '-DLLVM_TARGETS_TO_BUILD:Bool=' + ';'.join(targets))

        if spec.satisfies('@4.0.0:') and spec.satisfies('platform=linux'):
            cmake_args.append('-DCMAKE_BUILD_WITH_INSTALL_RPATH=1')
        return cmake_args

    @run_before('build')
    def pre_install(self):
        with working_dir(self.build_directory):
            # When building shared libraries these need to be installed first
            make('install-LLVMTableGen')
            if self.spec.version >= Version('4.0.0'):
                # LLVMDemangle target was added in 4.0.0
                make('install-LLVMDemangle')
            make('install-LLVMSupport')

    @run_after('install')
    def post_install(self):
        if '+clang' in self.spec and '+python' in self.spec:
            install_tree(
                'tools/clang/bindings/python/clang',
                join_path(site_packages_dir, 'clang'))

        with working_dir(self.build_directory):
            install_tree('bin', join_path(self.prefix, 'libexec', 'llvm'))
