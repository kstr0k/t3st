#!/bin/sh
set -u
. "${0%/*}"/../k9s0ke_t3st_lib.sh

# convenient, but watch namespace pollution
TTT() { k9s0ke_t3st_one "$@"; }

k9s0ke_t3st_enter

# two minimal test; defaults: rc=0 out='' nl=true
TTT spec='minimal nl=true' -- \
  echo
# default command is cat, infile=/dev/null
TTT nl=false spec='minimal nl=false cmd=cat'
TTT nl=false -- \
  true
TTT spec='# TODO : fails both output (\n) & $? but TODO ignores result' -- \
  false

k9s0ke_t3st_me spec='_me  -- args  # TODO : may fail with set -e (need symlinks)' -- \
  eval 'echo Hello world && false'
k9s0ke_t3st_me spec='_me (no args) # TODO : may fail with set -e (need symlinks)'

TTT rc=2 out=X spec='cmd=eval exit 2' -- \
  eval 'echo X; exit 2'
TTT rc=2 out=X nl=false -- \
  eval 'printf X; exit 2'
TTT rc=3 out=X spec='pp=' pp='echo "$1"; return $(( $2 + 1 ))' -- \
  eval 'printf X; exit 2'

TTT in=X out=X spec='in='
TTT in="$k9s0ke_t3st_nl"X out="$k9s0ke_t3st_nl"X
TTT in="$k9s0ke_t3st_nl" out="$k9s0ke_t3st_nl"

TTT out=XX infile=- spec='infile=- <<EOF' <<'EOF'
XX
EOF

# pipes & subshells: set cnt=false infile=-, increment counter manually
  printf XX |
TTT out=XX nl=false infile=- cnt=false spec='infile=- pipe'
k9s0ke_t3st_cnt=$(( k9s0ke_t3st_cnt + 1 ))

TTT rc=1 nl=false errexit=true spec=errexit -- \
  eval 'false; echo XX'

TTT rc='-ne 0' nl=false spec='# TODO : only with global "set -e" hook' -- \
  eval 'false; echo XX'
TTT rc=0 out=XX spec='# TODO : only without global "set -e" hook' -- \
  eval 'false; echo XX'

TTT out=Done spec=Done -- \
  echo Done

k9s0ke_t3st_leave
