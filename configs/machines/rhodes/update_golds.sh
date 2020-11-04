#!/bin/bash

cmd() {
  echo "+ $@"
  eval "$@"
}

TEST_DIR=${HOME}/exawind/golds
GOLD_DIR=${HOME}/exawind/nalu-wind/reg_tests/test_files

TESTS=( ablNeutralStat )

for TEST in "${TESTS[@]}"; do
  cmd "cp ${TEST_DIR}/${TEST}/${TEST}.norm ${GOLD_DIR}/${TEST}/${TEST}.norm.gold"
  cmd "cp ${TEST_DIR}/${TEST}/${TEST}_rst.norm ${GOLD_DIR}/${TEST}/${TEST}_rst.norm.gold"
  cmd "cp ${TEST_DIR}/${TEST}/${TEST}_Input.norm ${GOLD_DIR}/${TEST}/${TEST}_Input.norm.gold"
  cmd "cp ${TEST_DIR}/${TEST}/${TEST}.nc ${GOLD_DIR}/${TEST}/${TEST}.nc.gold"
done
