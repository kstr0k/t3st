#!/bin/sh

# if named TEST-e.t, runs TEST.t in the same shell but in errexit mode
# assumes TEST.t based on t3st-lib/t3st-ttt0.sh, or at least has a ..._entry()

k9s0ke_t3st_g_errexit=true

if [ "${1:-}" != '--no-run' ]; then
  [ $# -gt 0 ] || set -- --
  set -- --no-run "$@"
  . "${0%-e.t}.t"
  TTT__tfile_entry "${0%-e.t}.t" "$@"
else shift # library mode: sourced, assume caller setup
fi
