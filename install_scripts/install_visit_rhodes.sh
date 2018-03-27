#!/bin/bash -l

cmd() {
  echo "+ $@"
  eval "$@"
}

set -e

VISIT_DIR=/opt/software/a/visit

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
cmd "module load libxml2/2.9.4"
cmd "module load makedepend/1.0.5"
cmd "module list"

cmd "cp build_visit2_13_0 ${VISIT_DIR}/ && cd ${VISIT_DIR} && ./build_visit2_13_0 --makeflags -j24 --parallel --required --optional --all-io --nonio --no-fastbit --no-fastquery --prefix ${VISIT_DIR}/install"