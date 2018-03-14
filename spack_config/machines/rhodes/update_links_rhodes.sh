#!/bin/bash

DIR=a

ln -s ${DIR} active
ln -s ${DIR}/spack/share/spack/modules/linux-centos7-x86_64 modules
ln -s ${DIR}/spack/opt/spack/linux-centos7-x86_64/gcc-4.8.5/environment-modules-3.2.10-3x6hrfov45yzzquhieonp4acxkhcrvhh module_prefix
