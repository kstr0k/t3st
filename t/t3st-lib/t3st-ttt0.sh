#!/bin/sh
set -u

# TTT = .t file namespace

# each TTT__FUNC defaults to TTT__FUNC_0; can extend (override & call default)

TTT__tfile_setup_0() {  # args: abs-path-to-t-file ...
  . "${1%/*}"/t3st-lib/k9s0ke_t3st_lib.sh
  TTT()    { k9s0ke_t3st_one "$@"; }
  TTT_ee() { k9s0ke_t3st_one errexit=true  "$@"; }
  TTT_de() { k9s0ke_t3st_one errexit=false "$@"; }
  TTT_xe() {
    TTT_de "$@"
    TTT_ee "$@"
  }
  TTTnl=$k9s0ke_t3st_nl
}
TTT__tfile_setup() { TTT__tfile_setup_0 "$@"; }

TTT__tfile_thelp_0() {
cat <<EOHELP
# Called as: '$*' (k9s0ke_t3st_g_errexit=${k9s0ke_t3st_g_errexit:-})
EOHELP
}
TTT__tfile_thelp() { TTT__tfile_thelp_0 "$@"; }

TTT__tfile_early_0() {
  TTT__tfile_mypath=$1; shift
  case "$TTT__tfile_mypath" in (/*) ;; (*) TTT__tfile_mypath=$PWD/$TTT__tfile_mypath ;; esac
  TTT__tfile_myname=${TTT__tfile_mypath#**/}
  TTT__tfile_mydirn=${TTT__tfile_mypath%/*}; TTT__tfile_mydirn=${TTT__tfile_mydirn:-/}
}
TTT__tfile_early() { TTT__tfile_early_0 "$@"; }

TTT__tfile_runme_0() {  # args: $0 + "$@" from .t invocation
  case "${2:-}" in
    (--help|-h) shift
      TTT__tfile_thelp "$TTT__tfile_mypath"; echo '1..0 # Skipped: help requested' ;;
    (*)
      set -e; TTT__tfile_setup "$@"; set +e
      k9s0ke_t3st_enter
      TTT__tfile_tests "$@"
      k9s0ke_t3st_leave ;;
  esac
}
TTT__tfile_runme() { TTT__tfile_runme_0 "$@"; }
