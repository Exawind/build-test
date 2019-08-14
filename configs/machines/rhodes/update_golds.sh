#!/bin/bash

cmd() {
  echo "+ $@"
  eval "$@"
}

TEST_DIR=${HOME}/gold
GOLD_DIR=${HOME}/exawind/nalu-wind/reg_tests/test_files

TESTS=( ablNeutralEdge ablNeutralEdgeSegregated ablStableElem ablUnstableEdge ablUnstableEdge_ra airfoilRANSEdge airfoilRANSElem elemBackStepLRSST elemClosedDomain heatedWaterChannelEdge heliumPlume milestoneRun movingCylinder uqSlidingMeshDG waleElemXflowMixFrac3.5m )

for TEST in "${TESTS[@]}"; do
  cmd "cp ${TEST_DIR}/${TEST}/${TEST}.norm ${GOLD_DIR}/${TEST}/${TEST}.norm.gold"
  cmd "cp ${TEST_DIR}/${TEST}/${TEST}_rst.norm ${GOLD_DIR}/${TEST}/${TEST}_rst.norm.gold"
done
