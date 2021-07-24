#!/bin/sh

k9s0ke_t3st_nl='
'
k9s0ke_t3st_ch_newline=$k9s0ke_t3st_nl
k9s0ke_t3st_ch_tab=$(printf \\t)
k9s0ke_t3st_ch_apos="'"
k9s0ke_t3st_ch_amp='&'
k9s0ke_t3st_ch_bsol='\'
k9s0ke_t3st_ch_gt='>'
k9s0ke_t3st_ch_lt='<'
k9s0ke_t3st_ch_vert='|'
k9s0ke_t3st_ch_grave='`'
k9s0ke_t3st_ch_quest='?'
k9s0ke_t3st_ch_star='*'
k9s0ke_t3st_ch_dollar='$'
k9s0ke_t3st_ch_excl='!'
k9s0ke_t3st_ch_semi=';'
k9s0ke_t3st_ch_num='#'

k9s0ke_t3st_slurp_cmd() {
  k9s0ke_t3st_out=$(
    if [ $# -gt 0 ]; then "$@"; else cat; fi
    rc=$?; echo EOF; exit $rc
  ); local rc=$?
  k9s0ke_t3st_out=${k9s0ke_t3st_out%EOF}
  return "$rc"
}

k9s0ke_t3st_tmpfile() {
  :
}

k9s0ke_t3st_bailout() {
  echo 'Bail out!' "${*}"
  k9s0ke_t3st_end
  exit 1
}

k9s0ke_t3st_one() { # args: kw1=val1 kw2='val 2' ... -- cmd...
  local k9s0ke_t3st_arg_rc=0 k9s0ke_t3st_arg_out= k9s0ke_t3st_arg_nl=true k9s0ke_t3st_arg_pp= k9s0ke_t3st_arg_infile=/dev/null k9s0ke_t3st_arg_in=
  # keywords: rc, out, spec, nl, pp
  while [ $# -gt 0 ]; do
    [ "$1" != -- ] || { shift; break; }
    local "k9s0ke_t3st_arg_$1"; shift
  done
  case "$k9s0ke_t3st_arg_rc" in
    ''|*' '*) ;;  # '' will ignore $rc
    *) k9s0ke_t3st_arg_rc="-eq $k9s0ke_t3st_arg_rc" ;;
  esac
  ! $k9s0ke_t3st_arg_nl || k9s0ke_t3st_arg_out=$k9s0ke_t3st_arg_out$k9s0ke_t3st_nl

  case "$k9s0ke_t3st_arg_in" in
    '') k9s0ke_t3st_slurp_cmd "$@" <"$k9s0ke_t3st_arg_infile" ;;
    *) $k9s0ke_t3st_arg_nl || { k9s0ke_t3st_bailout 'in= with nl=false not supported'; return 1; }
    k9s0ke_t3st_slurp_cmd "$@" <<EOF
$k9s0ke_t3st_arg_in
EOF
    ;;
  esac
  local rc=$?  # DON'T split, local has its own rc
  local out; out=$k9s0ke_t3st_out
  if [ "$k9s0ke_t3st_arg_pp" ]; then
    out=$(eval "k9s0ke_t3st_tmp() { $k9s0ke_t3st_arg_pp $k9s0ke_t3st_nl}"
      k9s0ke_t3st_tmp $rc "$out"; rc=$?; echo EOF; exit $rc)
    rc=$?; out=${out%EOF}
  fi
  [ $rc ${k9s0ke_t3st_arg_rc:-} ] && [ "$out" = "${k9s0ke_t3st_arg_out:-}" ] ||  printf 'not '
  printf 'ok%s\n'  "${k9s0ke_t3st_arg_spec:+ "$k9s0ke_t3st_arg_spec"}"
}

k9s0ke_t3st_me() {
  ! [ -r "$0".out ] || k9s0ke_t3st_slurp_cmd <"$0".out
  k9s0ke_t3st_one rc="$(if test -r "$0".rc; then cat "$0".rc; else echo 0; fi)" out="$k9s0ke_t3st_out" -- "$@"
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

