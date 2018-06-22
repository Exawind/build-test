#!/bin/bash

print_cmds=true
execute_cmds=true

cmd() {
  if ${print_cmds}; then echo "+ $@"; fi
  if ${execute_cmds}; then eval "$@"; fi
}

cmd "chmod -R a+rX,o-w,ug+w /nopt/nrel/ecom/ecp/base/c"
cmd "chgrp -R n-ecom /nopt/nrel/ecom/ecp/base/c"
