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
    if [ $# -gt 0 ]; then ("$@"); else cat; fi
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
  k9s0ke_t3st_cnt=$(( k9s0ke_t3st_cnt + 1 ))
  local k9s0ke_t3st_arg_spec= k9s0ke_t3st_arg_rc=0 k9s0ke_t3st_arg_out= k9s0ke_t3st_arg_nl=true k9s0ke_t3st_arg_notok_diff=true  k9s0ke_t3st_arg_pp= k9s0ke_t3st_arg_infile=/dev/null k9s0ke_t3st_arg_in=
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
  local ok; ok=true
  [ $rc ${k9s0ke_t3st_arg_rc:-} ] && [ "$out" = "${k9s0ke_t3st_arg_out:-}" ] || ok=false
  $ok || printf 'not '
  printf 'ok%s\n'  " $k9s0ke_t3st_cnt ${k9s0ke_t3st_arg_spec:+"$k9s0ke_t3st_arg_spec"}"
  if $k9s0ke_t3st_arg_notok_diff && ! $ok; then
    local _pl
    if _pl=$(which perl 2>/dev/null); then
      eval set -- "$_pl"' -wE '\''use Data::Dumper; $Data::Dumper::Useqq=1; $Data::Dumper::Terse=1; print Dumper( $ARGV[0] )'\'' --'
    else eval set -- 'printf %s\\n'
    fi
    printf '%s%6s out=' '# Expect: rc=' "$k9s0ke_t3st_arg_rc"
    "$@" "$k9s0ke_t3st_arg_out" | tr \\n '|'; echo
    printf '%s%6s out=' '# Actual: rc=' "$rc"
    "$@" "$out"                 | tr \\n '|'; echo
  fi
}

k9s0ke_t3st_me() {
  ! [ -r "$0".out ] || k9s0ke_t3st_slurp_cmd <"$0".out
  k9s0ke_t3st_one rc="$(if test -r "$0".rc; then cat "$0".rc; else echo 0; fi)" out="$k9s0ke_t3st_out" -- "$@"
}

k9s0ke_t3st_enter () {
  k9s0ke_t3st_cnt=0
  return 0  # plan now at end
  if [ $# -eq 0 ]; then
    set -- "$(sed -ne '/^[[:space:]]*k9s0ke_t3st_one/p' < "$0" | wc -l)"
  fi
}
k9s0ke_t3st_leave() {
  echo 1..$k9s0ke_t3st_cnt
}

