#!/bin/sh
#shellcheck disable=SC1007,SC3043,SC2034

k9s0ke_t3st_nl='
'
k9s0ke_t3st_ch_newline=$k9s0ke_t3st_nl
k9s0ke_t3st_ch_tab=$(printf \\t)
k9s0ke_t3st_ch_apos="'"
k9s0ke_t3st_ch_amp='&'
k9s0ke_t3st_ch_bsol=\\
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
  if _pl=$(command -v perl 2>/dev/null); then #shellcheck disable=SC2016
    "$_pl" -wE 'use Data::Dumper; $Data::Dumper::Useqq=1; $Data::Dumper::Terse=1; print Dumper( $ARGV[0] )' -- "$@"
  else printf %s\\n "$@"
  fi
}

k9s0ke_t3st_chk_running() {
  test -d "$k9s0ke_t3st_tmp_dir" || { echo 1>&2 'test workdir gone, exiting'; exit 1; }  # probably after bailout from subshell
}
k9s0ke_t3st_one() { # args: kw1=val1 kw2='val 2' ... -- cmd...
  k9s0ke_t3st_chk_running
  local k9s0ke_t3st__l_k

  # set defaults
  local k9s0ke_t3st_arg_spec= k9s0ke_t3st_arg_rc=0 k9s0ke_t3st_arg_out= k9s0ke_t3st_arg_nl=true k9s0ke_t3st_arg_cnt=true k9s0ke_t3st_arg_diff_on=${k9s0ke_t3st_g_diff_on:-notok} k9s0ke_t3st_arg_pp= k9s0ke_t3st_arg_infile=/dev/null k9s0ke_t3st_arg_outfile= k9s0ke_t3st_arg_in=
  local k9s0ke_t3st_arg_hook_test_pre="${k9s0ke_t3st_g_hook_test_pre:-}" k9s0ke_t3st_arg_errexit=${k9s0ke_t3st_g_errexit:-false} k9s0ke_t3st_arg_set_pre=${k9s0ke_t3st_g_set_pre:-} k9s0ke_t3st_arg_repeat=${k9s0ke_t3st_g_repeat:-1}


  # load parameters
  [ $# -gt 0 ] || set -- --
  while [ $# -gt 0 ]; do
    [ "$1" != -- ] || { shift; break; }
    k9s0ke_t3st__l_k="${1%%=*}"
    case "$k9s0ke_t3st__l_k" in
      *'+')
        k9s0ke_t3st__l_k=${k9s0ke_t3st__l_k%'+'}
        eval k9s0ke_t3st__l_v="\${k9s0ke_t3st_arg_$k9s0ke_t3st__l_k:-}"
        local "k9s0ke_t3st_arg_$k9s0ke_t3st__l_k=$k9s0ke_t3st__l_v${1#*=}"
        ;;
      *) local "k9s0ke_t3st_arg_$1" ;;
    esac
    local "k9s0ke_t3st_has_arg_$k9s0ke_t3st__l_k=true"; shift
  done
  [ $# -gt 0 ] || set -- cat

  # process parameters
  case "$k9s0ke_t3st_arg_rc" in
    ''|*' '*) ;;  # '' will ignore $rc
    *) k9s0ke_t3st_arg_rc="-eq $k9s0ke_t3st_arg_rc" ;;
  esac
  ! $k9s0ke_t3st_arg_nl || k9s0ke_t3st_arg_out=$k9s0ke_t3st_arg_out$k9s0ke_t3st_nl
  if $k9s0ke_t3st_arg_errexit  # after -> overrides
    then k9s0ke_t3st_arg_set_pre="$k9s0ke_t3st_arg_set_pre -e"
    else k9s0ke_t3st_arg_set_pre="$k9s0ke_t3st_arg_set_pre +e"
    # set_pre never empty
  fi
  k9s0ke_t3st_arg_hook_test_pre="set $k9s0ke_t3st_arg_set_pre$k9s0ke_t3st_nl$k9s0ke_t3st_arg_hook_test_pre"
  if [ "$k9s0ke_t3st_arg_outfile" ]; then  # outfile= overrides out=, nl=
    k9s0ke_t3st_out=$(k9s0ke_t3st_slurp_exec '' <"$k9s0ke_t3st_arg_outfile") ||
      k9s0ke_t3st_bailout "not found: outfile $k9s0ke_t3st_arg_outfile"
    k9s0ke_t3st_slurp_split "$k9s0ke_t3st_out" k9s0ke_t3st_arg_out ''
  fi
  if "${k9s0ke_t3st_has_arg_in:-false}"; then  # in= overrides infile=
    k9s0ke_t3st_arg_infile="$k9s0ke_t3st_tmp_dir"/.t3st."$k9s0ke_t3st_cnt".infile
    { printf '%s' "$k9s0ke_t3st_arg_in"
      ! $k9s0ke_t3st_arg_nl || echo
    } >"$k9s0ke_t3st_arg_infile"
    [ -r "$k9s0ke_t3st_arg_infile" ] ||
      k9s0ke_t3st_bailout "could not write $k9s0ke_t3st_arg_infile"
  fi
  if [ - != "${k9s0ke_t3st_arg_infile:--}" ]; then #shellcheck disable=SC2016
    k9s0ke_t3st_arg_hook_test_pre='exec <"$k9s0ke_t3st_arg_infile"
'${k9s0ke_t3st_arg_hook_test_pre}
  fi
  [ "$k9s0ke_t3st_arg_spec" ] || k9s0ke_t3st_arg_spec="$1"
  if [ -r "$k9s0ke_t3st_tmp_dir"/.t3st.fail ]; then
    case "${k9s0ke_t3st_g_on_fail:-}" in
      bailout)      k9s0ke_t3st_bailout "on_fail = bailout" ;;
      skip-rest)    k9s0ke_t3st_skip 1 "after fail: $k9s0ke_t3st_arg_spec"; return 0 ;;
      ignore-rest)  return 0 ;;
    esac
  fi

  # loop: execute, load output and $?
  k9s0ke_t3st_repeat_cnt=1
  while :; do
  ! "${k9s0ke_t3st_g_keep_tmp:-false}" ||
    printf '%s\n' "$k9s0ke_t3st_arg_hook_test_pre" "$@" >"$k9s0ke_t3st_tmp_dir"/.t3st."$k9s0ke_t3st_cnt".cmd
  k9s0ke_t3st_out=$(k9s0ke_t3st_slurp_exec "$k9s0ke_t3st_arg_hook_test_pre" "$@" 2>"$k9s0ke_t3st_tmp_dir"/.t3st."$k9s0ke_t3st_cnt".stderr)
  k9s0ke_t3st_slurp_split "$k9s0ke_t3st_out" k9s0ke_t3st_out k9s0ke_t3st_rc

  # post-process
  if [ "$k9s0ke_t3st_arg_pp" ]; then
    #shellcheck disable=SC2154
    k9s0ke_t3st_out=$(eval "k9s0ke_t3st_tmp() { $k9s0ke_t3st_arg_pp $k9s0ke_t3st_nl}"
      k9s0ke_t3st_slurp_exec '' k9s0ke_t3st_tmp "$k9s0ke_t3st_out" "$k9s0ke_t3st_rc")
    k9s0ke_t3st_slurp_split "$k9s0ke_t3st_out" k9s0ke_t3st_out k9s0ke_t3st_rc
  fi

  # figure out results
  k9s0ke_t3st_ok=false
  # zsh would need 'setopt shwordsplit', but let's eval and be done
  ! eval '[ $k9s0ke_t3st_rc '"$k9s0ke_t3st_arg_rc"' ]' || [ "$k9s0ke_t3st_out" != "${k9s0ke_t3st_arg_out}" ] || k9s0ke_t3st_ok=true
  if $k9s0ke_t3st_ok && [ "$k9s0ke_t3st_repeat_cnt" -lt "$k9s0ke_t3st_arg_repeat" ]; then
    k9s0ke_t3st_repeat_cnt=$(( k9s0ke_t3st_repeat_cnt + 1 ))
  else break
  fi
  done
  local ok out rc; out=$k9s0ke_t3st_out; rc=$k9s0ke_t3st_rc; ok=$k9s0ke_t3st_ok
  # end of loop

  # print results
  if ! $ok; then
    printf 'not '
    case "$k9s0ke_t3st_arg_spec" in
      *TODO*) ;;
      *) echo "$k9s0ke_t3st_cnt" >>"$k9s0ke_t3st_tmp_dir"/.t3st.fail ;;
    esac
  fi
  printf 'ok%s\n'  " $(( k9s0ke_t3st_cnt + 1 )) $([ "$k9s0ke_t3st_arg_repeat" -le 1 ] || echo "($k9s0ke_t3st_repeat_cnt/$k9s0ke_t3st_arg_repeat) ")$k9s0ke_t3st_arg_spec"

  # maybe print diff
  (c=${k9s0ke_t3st_arg_diff_on%,},; while [ "$c" ]; do case "${c%%,*}" in
  ok) !  $ok || exit 0 ;;
  notok) $ok || exit 0;;
  esac; c=${c#*,}; done; false)
  #shellcheck disable=SC2181
  if [ $? -eq 0 ]; then
    printf '%s%6s out=' '## Expect: rc=' "$k9s0ke_t3st_arg_rc"
    k9s0ke_t3st_dump_str "$k9s0ke_t3st_arg_out" | tr \\n '|'; echo
    printf '%s%6s out=' '## Actual: rc=' "$rc"
    k9s0ke_t3st_dump_str "$out"                 | tr \\n '|'; echo
  fi

  if test -s "$k9s0ke_t3st_tmp_dir"/.t3st."$k9s0ke_t3st_cnt".stderr; then
    local _rl=
    while IFS= read -r _rl; do printf '# %s\n' "$_rl"; done \
      <"$k9s0ke_t3st_tmp_dir"/.t3st."$k9s0ke_t3st_cnt".stderr
    [ -z "$_rl" ] || printf '# %s\n' "$_rl"  #'\ no final newline'
  fi

  # cleanup, prepare next test
  "${k9s0ke_t3st_g_keep_tmp:-false}" || (rm -f "$k9s0ke_t3st_tmp_dir"/.t3st."$k9s0ke_t3st_cnt".*) 2>/dev/null ||
    :  # zsh yaks if none, fails 'set -e' (but errexit=off here); setopt nonomatch
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

k9s0ke_t3st_cnt_save() {
  local _f; _f="$k9s0ke_t3st_tmp_dir"/.t3st.cnt
  ! test -r "$_f" || k9s0ke_t3st_bailout 'would overwrite saved test counter'
  echo "$k9s0ke_t3st_cnt" >"$_f"
}
k9s0ke_t3st_cnt_load() {
  local _f; _f="$k9s0ke_t3st_tmp_dir"/.t3st.cnt
  test -r "$_f" || k9s0ke_t3st_bailout 'test counter not saved'
  IFS= read -r k9s0ke_t3st_cnt <"$_f"
  rm -f "$_f"
  k9s0ke_t3st_cnt=$(( k9s0ke_t3st_cnt + 1 ))
}

k9s0ke_t3st_skip() {  # args: count comment
  k9s0ke_t3st_chk_running
  local _cnt; _cnt=$1; shift
  while [ "$_cnt" -gt 0 ]; do
    k9s0ke_t3st_cnt=$(( k9s0ke_t3st_cnt + 1 ))
    printf '%s%s\n' "ok $k9s0ke_t3st_cnt # SKIP " "$1"
    _cnt=$(( _cnt - 1 ))
  done
}

k9s0ke_t3st_enter() {  # args: [plan]
  local _plan=; k9s0ke_t3st_plan_printed=false  # normally auto-generated by _leave
  if [ $# -gt 0 ]; then
    _plan=$1; shift
    k9s0ke_t3st_plan_printed=true
  fi
  k9s0ke_t3st_cnt=0
  k9s0ke_t3st_tmp_dir=$(mktemp -d "${TMPDIR:-/tmp}"/t3st.XXXXXX)
  k9s0ke_t3st_tmp_cnt=0

  touch "$k9s0ke_t3st_tmp_dir"/.t3st
  [ -r "$k9s0ke_t3st_tmp_dir"/.t3st ] ||
    k9s0ke_t3st_bailout "could not create workdir"
  case "$(set +o) " in
    *'-o errexit '*)
      k9s0ke_t3st_bailout 'Do not "set -e" in a test file; use k9s0ke_t3st_g_errexit=true'
    ;;
  esac
  [ -z "$_plan" ] || printf '%s\n' "$_plan"
  return 0
}
k9s0ke_t3st_leave() {  # args: [plan]
  [ $# -gt 0 ] || set -- "1..$k9s0ke_t3st_cnt"
  $k9s0ke_t3st_plan_printed || printf '%s\n' "$1"
  ! [ -d "$k9s0ke_t3st_tmp_dir" ] || "${k9s0ke_t3st_g_keep_tmp:-false}" ||
    rm -rf "$k9s0ke_t3st_tmp_dir"
  k9s0ke_t3st_tmp_dir=
}
