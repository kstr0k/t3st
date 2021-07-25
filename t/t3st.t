#!/bin/sh
set -u
. "${0%/*}"/../k9s0ke_t3st_lib.sh


k9s0ke_t3st_enter

# minimal test; defaults: rc=0 out='' nl=true
k9s0ke_t3st_one -- \
  echo
k9s0ke_t3st_one nl=false -- \
  true
k9s0ke_t3st_one spec='# TODO : fails on both output (\n) & $? but TODO ignores result' -- \
  false

k9s0ke_t3st_me eval 'echo Hello world && false'
k9s0ke_t3st_me

k9s0ke_t3st_one rc=2 out=X -- \
  eval 'echo X; exit 2'
k9s0ke_t3st_one rc=2 out=X nl=false -- \
  eval 'printf X; exit 2'
k9s0ke_t3st_one rc=3 out=X pp='echo "$1"; return $(( $2 + 1 ))' -- \
  eval 'printf X; exit 2'

k9s0ke_t3st_one in=X out=X -- \
  cat
k9s0ke_t3st_one in="$k9s0ke_t3st_nl"X out="$k9s0ke_t3st_nl"X -- \
  cat
k9s0ke_t3st_one in="$k9s0ke_t3st_nl" out="$k9s0ke_t3st_nl" -- \
  cat

k9s0ke_t3st_one out=XX infile=- -- \
  cat <<'EOF'
XX
EOF

printf XX | k9s0ke_t3st_one out=XX nl=false infile=- cnt=false -- \
  cat
k9s0ke_t3st_cnt=$(( k9s0ke_t3st_cnt + 1 ))


k9s0ke_t3st_one out=Done -- \
  echo Done

k9s0ke_t3st_leave
