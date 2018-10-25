#!/bin/bash

set -x

DIR=/scratch/jrood/eagle2/eagle_compilers/spack/share/spack/modules/linux-centos7-x86_64

for file_name in cluster.2019.0 cluster.2018.3 cluster.2017.7; do
  find ${DIR} -name "${file_name}" -type f | xargs sed -i -e '/INTEL_LICENSE_FILE/d'
  find ${DIR} -name "${file_name}" -type f | xargs -I {} sh -c "echo 'setenv INTEL_LICENSE_FILE 28519@license-1.hpc.nrel.gov' >> '{}'"
done
