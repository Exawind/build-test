#!/bin/bash

DIR=b

cd /nopt/nrel/ecom/ecp/base && unlink active && unlink modules && ln -s ${DIR} active && ln -s ${DIR}/spack/share/spack/modules/linux-centos7-x86_64 modules
