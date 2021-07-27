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

# runs "$@", copies output and appends \n$?
k9s0ke_t3st_slurp_cmd() {
  [ $# -gt 0 ] || { unset Error; : "${Error?internal: slurp}"; }
  [ $# -gt 1 ] || set -- "$@" cat
  # anything past "$@" would possibly not run (e.g. if $1 contains set -e)
  # thus it's impossible to avoid \n-trimming here with $()
  # OTOH $1 eval must be in subshell (set -e again)
  # result: impossible to avoid double subshell with capturing
  # TODO: redirecting output to file would work though
  (if [ "$1" ]; then eval "$1"; fi; shift; "$@")
  echo "$k9s0ke_t3st_nl$?"
}
# splits _slurp_cmd() output into actual output and $?
k9s0ke_t3st_slurp_split() {  # args: 1=slurp 2=outvar 3=rcvar
  [ -z "$2" ] || eval "$2=\${1%\"$k9s0ke_t3st_nl\"*}"
  [ -z "$3" ] || eval "$3=\${1##*\"$k9s0ke_t3st_nl\"}"
}

k9s0ke_t3st_tmpfile() {
  :
}

k9s0ke_t3st_bailout() {
  echo 'Bail out!' "${*}"
  k9s0ke_t3st_leave
  exit 1
}

k9s0ke_t3st_one() { # args: kw1=val1 kw2='val 2' ... -- cmd...
  local k9s0ke_t3st_arg_spec= k9s0ke_t3st_arg_rc=0 k9s0ke_t3st_arg_out= k9s0ke_t3st_arg_nl=true k9s0ke_t3st_arg_cnt=true k9s0ke_t3st_arg_notok_diff=true  k9s0ke_t3st_arg_pp= k9s0ke_t3st_arg_infile=/dev/null k9s0ke_t3st_arg_outfile= k9s0ke_t3st_arg_in= k9s0ke_t3st_arg_hook_test_pre="${k9s0ke_t3st_hook_test_pre:-}" k9s0ke_t3st_arg_errexit=false
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
  ! $k9s0ke_t3st_arg_errexit ||
    k9s0ke_t3st_arg_hook_test_pre="set -e$k9s0ke_t3st_nl${k9s0ke_t3st_arg_hook_test_pre:-}"
  if [ "$k9s0ke_t3st_arg_outfile" ]; then  # outfile= overrides out=
    k9s0ke_t3st_out=$(k9s0ke_t3st_slurp_cmd '' <"$k9s0ke_t3st_arg_outfile") ||
      k9s0ke_t3st_bailout "not found: outfile $k9s0ke_t3st_arg_outfile"
    k9s0ke_t3st_slurp_split "$k9s0ke_t3st_out" k9s0ke_t3st_arg_out ''
  fi
  if [ "$k9s0ke_t3st_arg_in" ]; then  # in= overrides infile=
    if ! $k9s0ke_t3st_arg_nl; then
      k9s0ke_t3st_bailout 'in=... nl=false not supported'; return 1
    fi
    k9s0ke_t3st_arg_hook_test_pre='exec <<EOF
$k9s0ke_t3st_arg_in
EOF
'${k9s0ke_t3st_arg_hook_test_pre:-}
  elif [ - != "${k9s0ke_t3st_arg_infile:--}" ]; then
    k9s0ke_t3st_arg_hook_test_pre='exec <"$k9s0ke_t3st_arg_infile"
'${k9s0ke_t3st_arg_hook_test_pre:-}
  fi

  local k9s0ke_t3st_out; k9s0ke_t3st_out=$(k9s0ke_t3st_slurp_cmd "$k9s0ke_t3st_arg_hook_test_pre" "$@")
  local out rc
  k9s0ke_t3st_slurp_split "$k9s0ke_t3st_out" out rc
  if [ "$k9s0ke_t3st_arg_pp" ]; then
    k9s0ke_t3st_out=$(eval "k9s0ke_t3st_tmp() { $k9s0ke_t3st_arg_pp $k9s0ke_t3st_nl}"
      k9s0ke_t3st_slurp_cmd '' k9s0ke_t3st_tmp "$out" "$rc")
    k9s0ke_t3st_slurp_split "$k9s0ke_t3st_out" out rc
  fi
  local ok; ok=true
  [ $rc ${k9s0ke_t3st_arg_rc:-} ] && [ "$out" = "${k9s0ke_t3st_arg_out:-}" ] || ok=false
  $ok || printf 'not '
  printf 'ok%s\n'  " $(( $k9s0ke_t3st_cnt + 1 )) $k9s0ke_t3st_arg_spec"
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
  ! $k9s0ke_t3st_arg_cnt || k9s0ke_t3st_cnt=$(( k9s0ke_t3st_cnt + 1 ))
}

k9s0ke_t3st_me() {
  if [ $# -eq 0 ]; then
    if test -r "$0".exec; then
      set -- "$0".exec
      test -x "$1" || set -- sh "$@"
      set -- -- "$@"
    else
      k9s0ke_t3st_bailout 'no command and no .exec file found'
    fi
  fi
  (
  if [ -r "$0".in ]; then exec <"$0".in; else exec </dev/null; fi
  local k9s0ke_t3st_out=
  if [ -r "$0".out ]; then
    k9s0ke_t3st_out=$(k9s0ke_t3st_slurp_cmd '' <"$0".out)
    k9s0ke_t3st_out=${k9s0ke_t3st_out%$k9s0ke_t3st_nl*}
  fi
  k9s0ke_t3st_one rc="$(if test -r "$0".rc; then cat "$0".rc; else echo 0; fi)" out="$k9s0ke_t3st_out" nl=false cnt=false infile=- "$@"
  )
  k9s0ke_t3st_cnt=$(( k9s0ke_t3st_cnt + 1 ))
}

k9s0ke_t3st_enter () {
  k9s0ke_t3st_cnt=0
  case "$(set +o)" in
    *'-o errexit'*)
      k9s0ke_t3st_bailout 'Do not "set -e" in your test file; use errexit=true or $k9s0ke_t3st_hook_test_pre'
    ;;
  esac
  return 0  # plan printed at end
}
k9s0ke_t3st_leave() {
  echo "${1:-1..$k9s0ke_t3st_cnt}"
}

