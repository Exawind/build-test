#!/bin/bash

cmd() {
  echo "+ $@"
  eval "$@"
}

TEST_DIR=${HOME}/exawind/test
GOLD_DIR=${HOME}/exawind/nalu-wind/reg_tests/test_files

TESTS=( elemClosedDomain ablUnstableEdge_ra ablUnstableEdge elemBackStepLRSST ablNeutralEdgeSegregated ablStableElem dgNonConformalFluidsEdge ablNeutralEdge heatedWaterChannelEdge movingCylinder airfoilRANSEdge milestoneRun ablHill3d_pp airfoilRANSElem fluidsPmrChtPeriodic heliumPlume uqSlidingMeshDG )

for TEST in "${TESTS[@]}"; do
  cmd "cp ${TEST_DIR}/${TEST}/${TEST}.norm ${GOLD_DIR}/${TEST}/${TEST}.norm.gold"
done
