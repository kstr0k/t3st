#!/bin/sh
set -u

# TTT = .t file namespace (arbitrary)
# ..._tests runs after ..._setup
TTT__tfile_tests() {  # this script may be used in library mode, see end
local TTT__tfile_me; TTT__tfile_me=$1; shift
k9s0ke_t3st_enter

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

k9s0ke_t3st_me "$TTT__tfile_me" exec='echo Hello world && false' spec='_me exec='
k9s0ke_t3st_me "$TTT__tfile_me" spec='_me (.exec)'

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

if [ "${POSH_VERSION:-}" ]; then k9s0ke_t3st_skip 1 'posh: set -e ignored in eval'; else
TTT rc='-ne 0' nl=false errexit=true spec=errexit \
  -- eval 'false; echo XX'
fi
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

case "${1:-}" in (--help|-h)
  shift; TTT__tfile_help "$TTT__tfile_me" ;;  # TODO: pass "$@": posh ${1+"$@"}
esac
k9s0ke_t3st_leave
}

TTT__tfile_setup() {  # args: testdir
  . "${1%/*}"/../k9s0ke_t3st_lib.sh  # $me has '/'-es
  TTT()    { k9s0ke_t3st_one "$@"; }
  TTT_ee() { k9s0ke_t3st_one errexit=true  "$@"; }
  TTT_de() { k9s0ke_t3st_one errexit=false "$@"; }
  TTTnl=$k9s0ke_t3st_nl
}

TTT__tfile_runme() {
  local TTT__tfile_me; TTT__tfile_me=$1; shift
  case "$TTT__tfile_me" in (/*) ;; (*) TTT__tfile_me=$PWD/$TTT__tfile_me ;; esac
  set -- "$TTT__tfile_me" "$@"
  set -e; TTT__tfile_setup "$@"
  set +e; TTT__tfile_tests "$@"
}

TTT__tfile_help() {
cat <<EOHELP
# Ran "$@", k9s0ke_t3st_g_errexit=${k9s0ke_t3st_g_errexit:-}
EOHELP
}

### script entrypoint
### see https://gitlab.com/kstr0k/t3st/-/wikis/shell/dollar0-source

# could use 'if ! type k9s0ke_t3st_me' but for posh (no type)
if [ "${1:-}" != '--no-run' ]; then  # script-mode top-level only
  # some shells (e.g. posh) break on "$@" if argc==0
  [ $# -gt 0 ] || set -- --
  TTT__tfile_runme "$0" "$@"
else shift # library mode: sourced, assume caller setup
fi

# vim: set ft=sh:
