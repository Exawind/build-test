#!/bin/bash -l

cmd() {
  echo "+ $@"
  eval "$@"
}

set -e

VISIT_DIR=${HOME}/visit

# Load the necessary modules
cmd "module purge"
cmd "module load unzip"
cmd "module load patch"
cmd "module load bzip2"
cmd "module load cmake"
cmd "module load git"
cmd "module load flex"
cmd "module load bison"
cmd "module load wget"
cmd "module load bc"
cmd "module load python/2.7.14"
cmd "module load makedepend"
cmd "module load libxml2/2.9.4-py2"
cmd "module load autoconf"
cmd "module load automake"
cmd "module load pkgconf"
cmd "module load libtool"
cmd "module load m4"
cmd "module load libpthread-stubs"
cmd "module load zlib"
cmd "module load xz"
cmd "module load netlib-lapack"
cmd "module load openssl"

# X11 stuff
cmd "module load xproto"
cmd "module load inputproto"
cmd "module load xextproto"
cmd "module load xcb-proto"
cmd "module load xtrans"
cmd "module load fontconfig"
cmd "module load freetype"
cmd "module load randrproto"
cmd "module load renderproto"
cmd "module load libx11"
cmd "module load libxau"
cmd "module load libxcb"
cmd "module load libxcursor"
cmd "module load libxdamage"
cmd "module load libxdmcp"
cmd "module load libxext"
cmd "module load libxfixes"
cmd "module load libxft"
cmd "module load libxi"
cmd "module load libxpm"
cmd "module load libxrandr"
cmd "module load libxrender"
cmd "module load libxshmfence"
cmd "module load libxv"
cmd "module load libxvmc"
cmd "module load glib"
cmd "module load glproto"
cmd "module load libxt"
cmd "module load libsm"
cmd "module load libice"
cmd "module load mesa"
cmd "module load mesa-glu"

cmd "module list"

# Setup the directory and run the build visit script
cmd "mkdir -p ${VISIT_DIR} && cp build_visit2_13_0 ${VISIT_DIR}/ && cd ${VISIT_DIR} && ./build_visit2_13_0 --makeflags -j32 --parallel --required --optional --all-io --nonio --no-fastbit --no-fastquery --prefix ${VISIT_DIR}/install"

# Set the permissions
#cmd "chmod -R a+rX,go-w ${VISIT_DIR}"
