#!/bin/sh
k9s0ke_t3st_g_errexit=true

# script-mode top-level only (see all.t comments)
. "$(dirname -- "$0")"/../k9s0ke_t3st_lib.sh
set -- --no-run "$@"; . "${0%-e.t}.t"; shift

[ $# -gt 0 ] || set -- --  # posh workaround
run_tests "$@"
