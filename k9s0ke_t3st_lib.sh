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

# run "$@", copy output, append \n$?
k9s0ke_t3st_slurp_exec() {  # args: 1=prelude 2...=command
  [ $# -gt 0 ] || { unset Error; : "${Error?internal: slurp}"; }
  [ $# -gt 1 ] || set -- "$@" cat
  # anything past "$@" would possibly not run (e.g. if $1 contains set -e)
  # thus it's impossible to avoid \n-trimming here with $()
  # OTOH $1 eval must be in subshell (set -e again)
  # result: impossible to avoid double subshell with capturing
  (if [ "$1" ]; then eval "$1"; fi; shift; "$@")
  echo "$k9s0ke_t3st_nl$?"
}
# split _slurp_exec() output into actual output and $?
k9s0ke_t3st_slurp_split() {  # args: 1=slurp 2=outvar 3=rcvar
  [ -z "${2:-}" ] || eval "$2=\${1%\"$k9s0ke_t3st_nl\"*}"
  [ -z "${3:-}" ] || eval "$3=\${1##*\"$k9s0ke_t3st_nl\"}"
}

k9s0ke_t3st_mktemp() {  # args: outvar [suffix]
  k9s0ke_t3st_tmp_cnt=$(( k9s0ke_t3st_tmp_cnt + 1 ))
  set -- "$1" "${2:-}"
  eval "$1=\$k9s0ke_t3st_tmp_dir/tmp.\"\$2\".$k9s0ke_t3st_tmp_cnt"
}

k9s0ke_t3st_bailout() {
  [ $# -gt 0 ] || set -- ''  # posh workaround
  printf '%s\n' "Bail out! ${*}"
  k9s0ke_t3st_leave
  exit 1
}

k9s0ke_t3st_dump_str() {
  local _pl
  if _pl=$(which perl 2>/dev/null); then
    "$_pl" -wE 'use Data::Dumper; $Data::Dumper::Useqq=1; $Data::Dumper::Terse=1; print Dumper( $ARGV[0] )' -- "$@"
  else printf %s\\n "$@"
  fi
}

k9s0ke_t3st_one() { # args: kw1=val1 kw2='val 2' ... -- cmd...
  # set defaults
  local k9s0ke_t3st_arg_spec= k9s0ke_t3st_arg_rc=0 k9s0ke_t3st_arg_out= k9s0ke_t3st_arg_nl=true k9s0ke_t3st_arg_cnt=true k9s0ke_t3st_arg_notok_diff=true  k9s0ke_t3st_arg_pp= k9s0ke_t3st_arg_infile=/dev/null k9s0ke_t3st_arg_outfile= k9s0ke_t3st_arg_in=
  local k9s0ke_t3st_arg_hook_test_pre="${k9s0ke_t3st_hook_test_pre:-}" k9s0ke_t3st_arg_errexit=false k9s0ke_t3st_arg_nounset=false k9s0ke_t3st_arg_repeat=${k9s0ke_t3st_repeat:-1}

  # load parameters
  while [ $# -gt 0 ]; do
    [ "$1" != -- ] || { shift; break; }
    local "k9s0ke_t3st_arg_$1"; shift
  done

  # process parameters
  case "$k9s0ke_t3st_arg_rc" in
    ''|*' '*) ;;  # '' will ignore $rc
    *) k9s0ke_t3st_arg_rc="-eq $k9s0ke_t3st_arg_rc" ;;
  esac
  ! $k9s0ke_t3st_arg_nl || k9s0ke_t3st_arg_out=$k9s0ke_t3st_arg_out$k9s0ke_t3st_nl
  ! $k9s0ke_t3st_arg_errexit ||
    k9s0ke_t3st_arg_hook_test_pre="set -e$k9s0ke_t3st_nl${k9s0ke_t3st_arg_hook_test_pre:-}"
  ! $k9s0ke_t3st_arg_nounset ||
    k9s0ke_t3st_arg_hook_test_pre="set -u$k9s0ke_t3st_nl${k9s0ke_t3st_arg_hook_test_pre:-}"
  if [ "$k9s0ke_t3st_arg_outfile" ]; then  # outfile= overrides out=, nl=
    k9s0ke_t3st_out=$(k9s0ke_t3st_slurp_exec '' <"$k9s0ke_t3st_arg_outfile") ||
      k9s0ke_t3st_bailout "not found: outfile $k9s0ke_t3st_arg_outfile"
    k9s0ke_t3st_slurp_split "$k9s0ke_t3st_out" k9s0ke_t3st_arg_out ''
  fi
  if [ "$k9s0ke_t3st_arg_in" ]; then  # in= overrides infile=
    k9s0ke_t3st_arg_infile="$k9s0ke_t3st_tmp_dir"/.t3st.$k9s0ke_t3st_cnt.infile
    { printf '%s' "$k9s0ke_t3st_arg_in"
      ! $k9s0ke_t3st_arg_nl || echo
    } >"$k9s0ke_t3st_arg_infile"
    [ -r "$k9s0ke_t3st_arg_infile" ] ||
      k9s0ke_t3st_bailout "could not write $k9s0ke_t3st_arg_infile"
  fi
  if [ - != "${k9s0ke_t3st_arg_infile:--}" ]; then
    k9s0ke_t3st_arg_hook_test_pre='exec <"$k9s0ke_t3st_arg_infile"
'${k9s0ke_t3st_arg_hook_test_pre:-}
  fi
  [ $# -gt 0 ] || set -- cat  # posh workaround

  # loop: execute, load output and $?
  k9s0ke_t3st_repeat_cnt=1
  while :; do
  k9s0ke_t3st_out=$(k9s0ke_t3st_slurp_exec "$k9s0ke_t3st_arg_hook_test_pre" "$@")
  k9s0ke_t3st_slurp_split "$k9s0ke_t3st_out" k9s0ke_t3st_out k9s0ke_t3st_rc

  # post-process
  if [ "$k9s0ke_t3st_arg_pp" ]; then
    k9s0ke_t3st_out=$(eval "k9s0ke_t3st_tmp() { $k9s0ke_t3st_arg_pp $k9s0ke_t3st_nl}"
      k9s0ke_t3st_slurp_exec '' k9s0ke_t3st_tmp "$k9s0ke_t3st_out" "$k9s0ke_t3st_rc")
    k9s0ke_t3st_slurp_split "$k9s0ke_t3st_out" k9s0ke_t3st_out k9s0ke_t3st_rc
  fi

  # figure out results
  k9s0ke_t3st_ok=true
  # zsh would need 'setopt -y' (shwordsplit), but let's eval and be done
  eval '[ $k9s0ke_t3st_rc '"$k9s0ke_t3st_arg_rc"' ]' && [ "$k9s0ke_t3st_out" = "${k9s0ke_t3st_arg_out:-}" ] || k9s0ke_t3st_ok=false
  if $k9s0ke_t3st_ok && [ $k9s0ke_t3st_repeat_cnt -lt $k9s0ke_t3st_arg_repeat ]; then
    k9s0ke_t3st_repeat_cnt=$(( k9s0ke_t3st_repeat_cnt + 1 ))
  else break
  fi
  done
  local ok out rc; out=$k9s0ke_t3st_out; rc=$k9s0ke_t3st_rc; ok=$k9s0ke_t3st_ok
  # end of loop

  # print results
  $ok || printf 'not '
  printf 'ok%s\n'  " $(( $k9s0ke_t3st_cnt + 1 )) $([ $k9s0ke_t3st_arg_repeat -le 1 ] || echo "($k9s0ke_t3st_repeat_cnt/$k9s0ke_t3st_arg_repeat) ")$k9s0ke_t3st_arg_spec"
  if $k9s0ke_t3st_arg_notok_diff && ! $ok; then
    printf '%s%6s out=' '# Expect: rc=' "$k9s0ke_t3st_arg_rc"
    k9s0ke_t3st_dump_str "$k9s0ke_t3st_arg_out" | tr \\n '|'; echo
    printf '%s%6s out=' '# Actual: rc=' "$rc"
    k9s0ke_t3st_dump_str "$out"                 | tr \\n '|'; echo
  fi

  # cleanup, prepare next test
  (rm -f "$k9s0ke_t3st_tmp_dir"/.t3st.$k9s0ke_t3st_cnt.*) 2>/dev/null ||
    :  # zsh yaks if none, fails 'set -e' (but errexit=off here); setopt -3
  ! $k9s0ke_t3st_arg_cnt || k9s0ke_t3st_cnt=$(( k9s0ke_t3st_cnt + 1 ))
}

k9s0ke_t3st_me() {
  [ $# -gt 0 ] || set -- cat  # posh workaround
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
    set -- outfile="$0".out "$@"
  fi
  k9s0ke_t3st_one rc="$(if test -r "$0".rc; then cat "$0".rc; else echo 0; fi)" out="$k9s0ke_t3st_out" nl=false cnt=false infile=- "$@"
  )
  k9s0ke_t3st_cnt=$(( k9s0ke_t3st_cnt + 1 ))
}

k9s0ke_t3st_skip() {  # args: count comment
  local _cnt; _cnt=$1; shift
  while [ $_cnt -gt 0 ]; do
    k9s0ke_t3st_cnt=$(( k9s0ke_t3st_cnt + 1 ))
    printf '%s%s\n' "ok $k9s0ke_t3st_cnt # SKIP " "$1"
    _cnt=$(( $_cnt - 1 ))
  done
}

k9s0ke_t3st_enter() {
  k9s0ke_t3st_cnt=0
  k9s0ke_t3st_tmp_dir=$(mktemp -d)
  k9s0ke_t3st_tmp_cnt=0

  touch "$k9s0ke_t3st_tmp_dir"/.t3st
  [ -r "$k9s0ke_t3st_tmp_dir"/.t3st ] ||
    k9s0ke_t3st_bailout "could not create workdir"
  case "$(set +o)" in
    *'-o errexit'*)
      k9s0ke_t3st_bailout 'Do not "set -e" in your test file; use errexit=true or $k9s0ke_t3st_hook_test_pre'
    ;;
  esac
  return 0  # plan printed at end
}
k9s0ke_t3st_leave() {
  echo "${1:-1..$k9s0ke_t3st_cnt}"
  [ -d "$k9s0ke_t3st_tmp_dir" ] && rm -rf "$k9s0ke_t3st_tmp_dir"
  k9s0ke_t3st_tmp_dir=
}
