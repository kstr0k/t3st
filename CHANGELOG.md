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
