#!/bin/sh
set -u

# convenient, but watch namespace pollution
TTT() { k9s0ke_t3st_one "$@"; }

run_tests() {  # this script may be used in library mode, see end
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
if [ "${ZSH_VERSION:-}" ]; then k9s0ke_t3st_skip 1 'zsh: set -f is set -F'; else
TTT out='*' set_pre=-f hook_test_pre='cd /' spec='set_pre' \
  -- eval 'echo *'
fi

TTT spec='# TODO : fails without global k9s0ke_t3st_g_errexit=true' \
  rc='-ne 0' nl=false \
  -- eval 'false; echo XX'
TTT spec='# TODO : fails with global k9s0ke_t3st_g_errexit' \
  rc=0 out=XX \
  -- eval 'false; echo XX'

TTT out=Done spec=Done \
  -- echo Done

k9s0ke_t3st_leave
}

# could use 'if ! type k9s0ke_t3st_me' but for posh (no type)
if [ "${1:-}" != '--no-run' ]; then  # script-mode top-level only
  . "$(dirname -- "$0")"/../k9s0ke_t3st_lib.sh
  [ $# -gt 0 ] || set -- --  # posh workaround
  run_tests "$@"
# else library mode: sourced, assume caller setup
fi

# TLDR: only use script mode, top-level $0; caller does all setup in libmode
# mydir=$(dirname -- "$0"); mybasename=${0##*/}
#
# in script mode (invoked by './myscript' or 'shell myscript')
#   $0 = script; except zsh: $ZSH_ARGZERO = myscript, $0 inside f() = 'f'
# in library mode (invoked by '. myscript')
#   $0 = caller (zsh: $ZSH_ARGZERO instead); may be /bin/*sh!
#   POSIX sh: impossible to get 'myscript'
#   bash: $BASH_SOURCE = myscript
#   zsh: top-level $0 = myscript; ${(%):-%x} anywhere but may confuse others

# Don't "optimize" 'dirname $0' via '${0%/*}/'; consider
#   sh myscript  # (or myscript in path): $0 = 'myscript' (no /)
# The following work (zsh: top-level script-mode only, or even more code)
#   "${0##*/}" = basename
#   "${0%"${0##*/}"}"/ = dirname
#   # final / needed: consider /myscript

# vim: set ft=sh:
