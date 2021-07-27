#!/bin/sh
set -u
[ $# -gt 0 ] || set -- --  # posh workaround
. "${0%/*}"/../k9s0ke_t3st_lib.sh

# convenient, but watch namespace pollution
TTT() { k9s0ke_t3st_one "$@"; }

# make script usable as library -- not required in general
# we use this in t3st-e.t
run_tests() {

k9s0ke_t3st_enter

# two minimal test; defaults: rc=0 out='' nl=true infile=/dev/null
TTT spec='minimal #1, nl=true' \
  -- echo
TTT nl=false spec='minimal #2, nl=false, command=cat'
TTT nl=false \
  -- true
TTT spec='# TODO : fails both output (\n) & $? but TODO ignores result' \
  -- false
TTT out=/ spec='use eval for shell code' \
  -- eval 'cd /; pwd'
test -r /etc/hosts &&  # run conditionally
TTT spec='' nl=false outfile=/etc/hosts infile=/etc/hosts spec='{outfile,infile}=/etc/hosts' \

k9s0ke_t3st_me spec='_me  -- args  # TODO : may fail with set -e (need symlinks)' \
  -- eval 'echo Hello world && false'
k9s0ke_t3st_me spec='_me (no args) # TODO : may fail with set -e (need symlinks)'

TTT rc=2 out=X spec='cmd=eval exit 2' \
  -- eval 'echo X; exit 2'
TTT rc=2 out=X nl=false \
  -- eval 'printf X; exit 2'
TTT rc=3 out=X spec='pp=' pp='echo "$1"; return $(( $2 + 1 ))' \
  -- eval 'printf X; exit 2'

TTT in=X out=X spec='in='
TTT in="$k9s0ke_t3st_nl"X out="$k9s0ke_t3st_nl"X
TTT in="$k9s0ke_t3st_nl" out="$k9s0ke_t3st_nl"

TTT out=XX infile=- spec='infile=- <<EOF' <<'EOF'
XX
EOF

# pipes & subshells: set cnt=false infile=-, increment counter manually
printf abcde |
TTT out=5 infile=- cnt=false spec='infile=- pipe' \
  -- eval 'set -- "$(cat)"; echo ${#1}'
k9s0ke_t3st_cnt=$(( k9s0ke_t3st_cnt + 1 ))

TTT rc='-ne 0' nl=false errexit=true spec='errexit # TODO : posh: set -e ignored in eval' \
  -- eval 'false; echo XX'
TTT rc='-ne 0' nl=false nounset=true spec=nounset \
  -- eval 'echo $NONE; echo XX' 2>/dev/null

TTT rc='-ne 0' nl=false spec='# TODO : only with global "set -e" hook' \
  -- eval 'false; echo XX'
TTT rc=0 out=XX spec='# TODO : only without global "set -e" hook' \
  -- eval 'false; echo XX'

TTT out=Done spec=Done \
  -- echo Done

k9s0ke_t3st_leave

}
if [ "${1:-}" != --no-run ]; then run_tests "$@"; fi
