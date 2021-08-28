#!/bin/sh
set -u

# TTT = .t file namespace

# each TTT__FUNC defaults to TTT__FUNC_0; can extend (override & call default)

TTT__tfile_setup_0() {  # args: .t invocation
  . "$TTT__tfile_mydirn"/t3st-lib/k9s0ke_t3st_lib.sh
  TTT()    { k9s0ke_t3st_one "$@"; }
  TTT_ee() { k9s0ke_t3st_one errexit=true  "$@"; }
  TTT_de() { k9s0ke_t3st_one errexit=false "$@"; }
  TTT_xe() {
    TTT_de "$@"
    TTT_ee "$@"
  }
  TTTnl=$k9s0ke_t3st_nl
}
TTT__tfile_setup() { TTT__tfile_setup_0 ${1+"$@"}; }

# ${1+"$@"}: work-around for shells (posh, old bash) that break $@ / $* when $# = 0

TTT__tfile_thelp_0() {
cat <<EOHELP
# Called as: '$TTT__tfile_mypath ${1+"$*"}' (k9s0ke_t3st_g_errexit=${k9s0ke_t3st_g_errexit:-})
EOHELP
}
TTT__tfile_thelp() { TTT__tfile_thelp_0 ${1+"$@"}; }

TTT__tfile_early_0() {  # args: $0 + .t invocation
  TTT__tfile_myname=${TTT__tfile_mypath##*/}
  TTT__tfile_mydirn=${TTT__tfile_mypath%/*}; TTT__tfile_mydirn=${TTT__tfile_mydirn:-/}
}
TTT__tfile_early() { TTT__tfile_early_0 ${1+"$@"}; }

TTT__tfile_parse_args_end_0() {
  set -e; TTT__tfile_setup ${1+"$@"}; set +e
  k9s0ke_t3st_enter
  TTT__tfile_tests ${1+"$@"}
  k9s0ke_t3st_leave
}
TTT__tfile_parse_args_end() { TTT__tfile_parse_args_end_0 ${1+"$@"}; }

TTT__tfile_parse_args_0() {
  case "${1:-}" in
    (--help|-h) shift
      TTT__tfile_thelp ${1+"$@"}; echo '1..0 # Skipped: help requested' ;;
    (--t3st-shell=*) local sh; sh="${1#*=}"; shift
      eval exec "$sh" '"$TTT__tfile_mypath" ${1+"$@"}' ;;
    (--t3st-eval=*) eval "${1#*=}"; shift
      TTT__tfile_parse_args ${1+"$@"} ;;
    (--) shift
      TTT__tfile_parse_args_end ${1+"$@"} ;;
    (*)
      TTT__tfile_parse_args_end ${1+"$@"} ;;
  esac
}
TTT__tfile_parse_args() { TTT__tfile_parse_args_0 ${1+"$@"}; }

TTT__tfile_runme_0() {  # args: .t invocation
  TTT__tfile_parse_args ${1+"$@"};
}
TTT__tfile_runme() { TTT__tfile_runme_0 ${1+"$@"}; }
