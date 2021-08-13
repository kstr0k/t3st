#!/bin/sh
k9s0ke_t3st_g_errexit=true

if [ "${1:-}" != '--no-run' ]; then
  [ $# -gt 0 ] || set -- --
  set -- --no-run "$@"
  . "${0%-e.t}.t"
  TTT__tfile_runme "${0%-e.t}.t" "$@"
fi
