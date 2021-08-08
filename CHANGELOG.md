* v0.9.2
  * `git-t3st-setup`: add `t3st` testing to a project with a one-liner
  * `repeat=N` tests, `k9s0ke_t3st_g_repeat` global
  * skipped tests (`k9s0ke_t3st_skip`); skip-all-after-failure mode
  * spec defaults to command's first word
  * `_one:`: syntax: `ARG+=...` (append to default / current arg value)
  * stderr as comment lines
  * `diff_on={ok,|notok,}*` replaces `notok_diff`
  * better support for subshells / pipelines (`{save,load}_cnt`)
  * support dubious `in='' nl=true` for consistency
  * add `k9s0ke_t3st_mktemp` (fast mktemp + cleanup)

* v0.9.1
  * zsh support without `-y`
  * errexit not TODO anymore; `posh` will fail
  * github mirror

* v0.9.0
  * TAP output (prove)
  * self-test suite
  * `_one` / `_me` tests
  * `rc=`{ int | '-cmp int' } expected exit status
  * `in[file]=`, `out[file]=` input / expected output specs
  * automatic test counter
  * errexit (`set -e`) support; `set -u` "just works"
  * pipe / redirect into tests
  * tests in subshells
  * actual vs expected diff
  * bailout, directives
  * no namespace pollution
  * docs == code
