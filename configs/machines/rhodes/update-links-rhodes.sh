#!/bin/bash

DIR=b

cd /opt/software && unlink active && unlink modules && unlink module_prefix && ln -s ${DIR} active && ln -s ${DIR}/spack/share/spack/modules/linux-centos7-x86_64/gcc-4.8.5 modules && ln -s ${DIR}/spack/opt/spack/linux-centos7-x86_64/gcc-4.8.5/environment-modules-3.2.10-c5xiwsdznporezjx7cgtvzsh3as576d3 module_prefix
