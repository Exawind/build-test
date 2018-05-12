# .bashrc

# Source global definitions
if [ -f /etc/bashrc ]; then
	. /etc/bashrc
fi

#Pure modules sans Spack
export MODULE_PREFIX=/opt/software/module_prefix
export PATH=${MODULE_PREFIX}/Modules/bin:${PATH}
module() { eval $(${MODULE_PREFIX}/Modules/bin/modulecmd $(basename ${SHELL}) $*); }

#Load some base modules
module use /opt/software/modules
module load unzip
module load patch
module load bzip2
module load cmake
module load git
module load flex
module load bison
module load wget
module load bc
module load python/2.7.14

# Need to uncomment all this for using Visit
#module load makedepend
#module load libxml2/2.9.4-py2
#module load autoconf
#module load automake
#module load pkgconf
#module load libtool
#module load m4
#module load libpthread-stubs
#module load zlib
#module load xz
#module load netlib-lapack
#module load xproto
#module load inputproto
#module load xextproto
#module load xcb-proto
#module load xtrans
#module load fontconfig
#module load freetype
#module load randrproto
#module load renderproto
#module load libx11
#module load libxau
#module load libxcb
#module load libxcursor
#module load libxdamage
#module load libxdmcp
#module load libxext
#module load libxfixes
#module load libxft
#module load libxi
#module load libxpm
#module load libxrandr
#module load libxrender
#module load libxshmfence
#module load libxv
#module load libxvmc
#module load glib
#module load glproto
#module load libxt
#module load libsm
#module load libice
#module load mesa
#module load mesa-glu
#module load openssl
#module load visit
