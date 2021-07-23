#!/bin/sh

k9s0ke_t3st_slurp_cmd() {
  local x; x=$1; shift

  local rc nl; nl='
';
  [ "$x" = out ] || local out  # if outvar is "out", local & eval not needed
  out=$(
    if [ $# -gt 0 ]; then "$@"; else cat; fi
    rc=$?; echo EOF; exit $rc
  ); rc=$?; out=${out%"${nl}"EOF}
  [ "$x" = out ] || eval "$x=\$out"
}

k9s0ke_t3st_one() { # args: kw1=val1 kw2='val 2' ... -- cmd...
  # keywords: rc, out, spec
  local arg
  while [ $# -gt 0 ]; do
    arg="$1"; shift
    [ "$arg" != -- ] || break
    local "_t_$arg"
  done

  local out rc
  k9s0ke_t3st_slurp_cmd out "$@"; rc=$?
  if [ $rc = ${_t_rc:-0} ] && [ "$out" = "${_t_out:-}" ]; then
    echo ok "${_t_spec:-}"
  else
    echo not ok "${_t_spec:-}"
  fi
}

k9s0ke_t3st_me() {
  local out=
  ! [ -r "$0".out ] || k9s0ke_t3st_slurp_cmd out cat "$0".out
  k9s0ke_t3st_one rc="$(if test -r "$0".rc; then cat "$0".rc; else echo 0; fi)" out="$out" -- "$@"
}

k9s0ke_t3st_begin () {
  if [ $# -eq 0 ]; then
    set -- "$(sed -ne '/^[[:space:]]*k9s0ke_t3st_one/p' < "$0" | wc -l)"
  fi
  echo 1..$1
}
k9s0ke_t3st_end() {
  :
}

