#!/bin/sh
set -u
. "${0%/*}"/../k9s0ke_t3st_lib.sh

k9s0ke_t3st_enter

# two minimal test; defaults: rc=0 out='' nl=true
k9s0ke_t3st_one spec='minimal nl=true' -- \
  echo
# default command is cat, infile=/dev/null
k9s0ke_t3st_one nl=false spec='minimal nl=false cmd=cat'

k9s0ke_t3st_one nl=false -- \
  true
k9s0ke_t3st_one spec='# TODO : fails on both output (\n) & $? but TODO ignores result' -- \
  false

k9s0ke_t3st_me spec='_me with args # TODO : may fail with set -e' -- \
  eval 'echo Hello world && false'
k9s0ke_t3st_me spec='_me no args # TODO : may fail with set -e'

k9s0ke_t3st_one rc=2 out=X spec='cmd=eval' -- \
  eval 'echo X; exit 2'
k9s0ke_t3st_one rc=2 out=X nl=false -- \
  eval 'printf X; exit 2'
k9s0ke_t3st_one rc=3 out=X spec='pp=' pp='echo "$1"; return $(( $2 + 1 ))' -- \
  eval 'printf X; exit 2'

k9s0ke_t3st_one in=X out=X spec='in='
k9s0ke_t3st_one in="$k9s0ke_t3st_nl"X out="$k9s0ke_t3st_nl"X
k9s0ke_t3st_one in="$k9s0ke_t3st_nl" out="$k9s0ke_t3st_nl"

k9s0ke_t3st_one out=XX infile=- spec='infile=- <<EOF' <<'EOF'
XX
EOF
printf XX | k9s0ke_t3st_one out=XX nl=false infile=- cnt=false spec='infile=- pipe'
k9s0ke_t3st_cnt=$(( k9s0ke_t3st_cnt + 1 ))

k9s0ke_t3st_one rc=1 nl=false errexit=true spec=errexit -- \
  eval 'false; echo XX'

k9s0ke_t3st_one rc='-ne 0' nl=false spec='# TODO : only with global "set -e" hook' -- \
  eval 'false; echo XX'
k9s0ke_t3st_one rc=0 out=XX spec='# TODO : only without global "set -e" hook' -- \
  eval 'false; echo XX'

k9s0ke_t3st_one out=Done spec=Done -- \
  echo Done

k9s0ke_t3st_leave
