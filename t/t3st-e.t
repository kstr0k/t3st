#!/bin/sh
[ $# -gt 0 ] || set -- --  # posh workaround
k9s0ke_t3st_g_errexit=true

# howto: use a script as both library & command
# a simple `. something.t` would also do here though
set -- --no-run "$@"
. "${0%-e.t}.t"
shift

if [ "${1:-}" != --no-run ]; then run_tests "$@"; fi
