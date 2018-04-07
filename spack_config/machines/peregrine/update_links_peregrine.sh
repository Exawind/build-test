#!/bin/bash

DIR=a

unlink active
unlink modules
ln -s ${DIR} active
ln -s ${DIR}/spack/share/spack/modules/linux-centos6-x86_64 modules
