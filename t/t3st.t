#!/bin/sh
set -u

# this script may be used in library mode, see end

# TTT = .t file namespace (arbitrary)
# uses TTT* defs in t/t3st-ttt0.sh
TTT__tfile_tests() {

# minimal tests; defaults: rc=0 out='' nl=true infile=/dev/null
TTT spec='minimal #1, [nl=true]' \
  -- echo
TTT nl=false spec='minimal #2, nl=false, [command=cat]'
TTT in= spec='minimal #3, in="", [nl=true], [command=cat]'

TTT nl=false \
  -- true
TTT spec='# TODO : fails both output (\n) & $? but TODO ignores result' \
  -- false
TTT out=// hook_test_pre='cd /' spec='use eval for shell code' \
  -- eval 'printf $PWD; pwd'

if [ -r /etc/hosts ]; then  # run conditionally
TTT spec='' nl=false outfile=/etc/hosts infile=/etc/hosts spec='{outfile,infile}=/etc/hosts'
TTT spec='' nl=true outfile=/etc/hosts infile=/etc/hosts spec='{outfile,infile}=/etc/hosts, nl=true ignored'
fi

k9s0ke_t3st_me "$TTT__tfile_mypath" exec='echo Hello world && false' spec='_me exec='
k9s0ke_t3st_me "$TTT__tfile_mypath" spec='_me (.exec)'

TTT rc=2 out=X spec='cmd=eval exit 2' \
  -- eval 'echo X; exit 2'
TTT rc=2 out=X nl=false \
  -- eval 'printf X; exit 2'
TTT rc=3 out=X spec='pp=' pp='echo "$1"; return $(( $2 + 1 ))' \
  -- eval 'printf X; exit 2'

TTT in=X out=X spec='in='
TTT in=X out=X nl=false spec='in= nl=false'
TTT in="$k9s0ke_t3st_nl"X out="$k9s0ke_t3st_nl"X
TTT in="$k9s0ke_t3st_nl" out="$k9s0ke_t3st_nl"

TTT repeat=2 spec='# TODO : this succeeds only on 1st repetition' \
  -- eval 'set -e; f=$k9s0ke_t3st_tmp_dir/rep; ! [ -r "$f" ]; touch "$f"'

TTT out=XX \
  -- eval 'k9s0ke_t3st_mktemp tf; echo XX >"$tf"; cat "$tf"'

TTT out=XX infile=- spec='infile=- <<EOF' <<'EOF'
XX
EOF

# pipes & subshells: set cnt=false infile=-, increment counter manually
echo 'XX YY' |
TTT out=XX infile=- cnt=false spec='infile=- pipe' \
  -- eval 'read -r x rest; echo "$x"; k9s0ke_t3st_cnt_save'
k9s0ke_t3st_cnt_load

TTT rc='-ne 0' nl=false errexit=true spec=errexit \
  -- eval 'false; echo XX'
TTT out=XX set_pre=+u spec=set+u \
  -- eval 'printf "$T3STNONE"; echo XX' 2>/dev/null
TTT rc='-ne 0' nl=false set_pre=-u spec=set-u \
  -- eval 'printf "$T3STNONE"; echo XX' 2>/dev/null
TTT out='*' set_pre='-o noglob' hook_test_pre='cd /' spec='set_pre="-o longname"' \
  -- eval 'echo *'

k9s0ke_t3st_skip 1 'skip() demo'

TTT spec='# TODO : fails without global k9s0ke_t3st_g_errexit=true' \
  rc='-ne 0' nl=false \
  -- eval 'false; echo XX'
TTT spec='# TODO : fails with global k9s0ke_t3st_g_errexit' \
  rc=0 out=XX \
  -- eval 'false; echo XX'

TTT out=Done spec=Done \
  -- echo Done
}

### script entrypoint
### see https://gitlab.com/kstr0k/t3st/-/wikis/shell/dollar0-source

TTT__tfile_entry() {  # args: $0 + "$@" from .t invocation
  . "$(dirname -- "$1")"/t3st-lib/t3st-ttt0.sh  # keep dirname (gotchas)
  TTT__tfile_early "$@"
  TTT__tfile_runme "$@"
}

if [ "${1:-}" != '--no-run' ]; then  # script-mode top-level only
  # some shells (e.g. posh) break on "$@" if argc==0
  [ $# -gt 0 ] || set -- --
  TTT__tfile_entry "$0" "$@"
else shift # library mode: sourced, assume caller setup
fi

# vim: set ft=sh:
