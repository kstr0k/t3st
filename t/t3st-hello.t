#!/bin/sh

# See usage at end; ./hello-t3st.t -h; prove -v :: -h

### SETUP

# global defaults -- apply to all tests
#set -u                          # recommended; DON'T `set -e` globally
#k9s0ke_t3st_g_errexit=true      # default: false
 k9s0ke_t3st_g_diff_on=ok,notok  # default: notok

# DON'T "optimize" dirname or move into function (gotchas)
# see https://gitlab.com/kstr0k/t3st/-/wikis/shell/dollar0-source
. "$(dirname -- "$0")"/t3st-lib/k9s0ke_t3st_lib.sh

# TTT prefix: .t-file namespace (arbitrary -- anything convenient)
# test with default errexit setting
TTT()   { k9s0ke_t3st_one "$@"; }
# test with enabled / disabled errexit (regardless of default)
TTT_ee() { k9s0ke_t3st_one errexit=true  "$@"; }
TTT_de() { k9s0ke_t3st_one errexit=false "$@"; }
# constants
TTTnl=$k9s0ke_t3st_nl

### TESTS

k9s0ke_t3st_enter

TTT out='Hello t3st' \
  -- echo 'Hello t3st'
TTT_de out=here \
  -- eval 'false; echo here'
TTT_ee nl=false rc='-ne 0' \
  -- eval 'false; echo here'

TTT nl=false todo='add more tests'

### END OF TESTS (don't forget to _leave)

case "${1:-}" in (--help|-h) cat <<'EOHELP'
#
### Usage:
# prove [-v] [-e $shell] [t/hello-t3st.t] [:: --help]
# git t3st-prove [...]
# git t3st-setup  # update / repair
# git t3st-new    # add test
# git config t3st.prove-shells 'sh,bash,busybox sh#,mksh,dash,zsh,zsh --emulate sh,yash'
# git -c t3st.prove-shells='override..' t3st.prove [...]
#
### if Makefile not linked, use -f t3st.mk
# make -C t/ [ T3ST_PROVE_SHELLS='override..' ]
# make -C t/ new

## set up a different test dir:
# curl -s https://gitlab.com/kstr0k/t3st/-/raw/master/git-t3st-setup | sh -s -- --tdir=...
EOHELP
esac

k9s0ke_t3st_leave
