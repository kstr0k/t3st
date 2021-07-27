# t3st

## _Lightweight shell TAP testing library_

**TLDR: [t3st.t](t/t3st.t)** tests the framework and serves as an example.

`t3st` is a shell library to produce [TAP output](https://testanything.org/tap-specification.html). Use it to test shell functions, or any commands / scripts. It requires only a **POSIX shell** (but works under bash / dash / busybox / mksh / zsh / BSD sh / others) and a TAP framework (**`prove`** comes with any system perl). It supports testing both command **outputs** and **exit codes**, `errexit` ([`set -e`](#errexit)) and `set -u` tests, **pipes** ([redirects](#redirects)), implicit / explicit **final newline** handling and TAP directives. The defaults make tests easy to write without sacrificing correctness or flexibility. The test API completely avoids **namespace pollution** which guarantees complete interoperability with any source.

*Notes*
- development takes place at [GitLab `t3st`](https://gitlab.com/kstr0k/t3st) but you can also report issues at the [GitHub `t3st` mirror](https://github.com/kstr0k/t3st).
- watch the [CHANGELOG](CHANGELOG.md) if using the `git` version &mdash; there are no API guarantees at this stage

## Highlights

- [Usage](#usage)
  - [errexit & nounset](#errexit)
- [Test function](#test-function)
  - [Redirects](#redirects)
- [Extras](#extras)
- [File-based (`_me`) tests](#file-based-_me-tests)
- [Supported shells](#supported-shells)
- [Copyright & license](#copyright)

## Usage

Create a directory `t/` with "`.t`" tests. These can be run using any TAP test harness, e.g.
```
prove -v  # or change the shell:
prove -e 'busybox sh'
prove -vr tests  # rename t/, recursive
```

A `sample.t` file (using defaults aggressively, and peculiar, *but not magic*, formatting to highlight tested code) might look like
```
#!/bin/sh
# This is a real shell script, there's no syntax / formatting magic

. "${0%/*}"/../k9s0ke_t3st_lib.sh  # or wherever
TTT() { k9s0ke_t3st_one "$@"; }    # or whatever

k9s0ke_t3st_enter

# defaults imply cat, out='', append \n (overriden), </dev/null
TTT nl=false  # as bare as it gets #1

TTT spec='as bare as it gets #2' \
  -- echo
TTT nl=false \
  -- true
TTT nl=false rc='-ne 0' \
  -- false
TTT out=/ spec='use eval if not single command' \
  -- eval 'cd /; pwd'

k9s0ke_t3st_leave
```

That is: source [`k9s0ke_t3st_lib.sh`](k9s0ke_t3st_lib.sh) (along with any tested code you need to reference) and call
- `k9s0ke_t3st_enter` to start TAP output.
- `k9s0ke_t3st_one [key=value]... [-- cmd args...]` (see [test function](#test-function) for defaults) for each test; it executes everything after "`--`" (a single command or function call &mdash; use `eval '...'` otherwise) in a subshell and checks the output and exit status.
- `k9s0ke_t3st_me` &mdash; alternative file-based tests (see [`_me` tests](#file-based-_me-tests))
- `k9s0ke_t3st_leave [test_plan]`: ends TAP output. It prints the supplied test plan, or "1..`k9s0ke_t3st_one`-call-count"

### errexit

**Don't "set -e" globally** (i.e. anywhere outside a `_one` or `_me` call); this would make it impossible to properly record exit status, and the library code itself must run without `set -e`. Instead, either
- set a **global pre-test hook** (`k9s0ke_t3st_hook_test_pre='set -e'`), OR
- use `errexit=true` in individual `..._one` / `..._me` calls, OR
- `set -e` inside the tested code (or inside a `-- eval` argument).

To run tests with **both `set -e` and `set +e`**, create a `...-e.t` file which adds a global `set -e` hook, then sources the base `.t` file. [t/t3st-e.t](t/t3st-e.t) implements a more general version of this for making scripts usable as both commands and libraries.

`set -u` does not affect operation &mdash; set it either way globally and/or use `nounset=` parameters.

## Test function

Call `k9s0ke_t3st_one` once per test in a `.t` file (you may want to alias it, e.g. to `TTT`). Minimal, though contrived, examples are the first two tests in [t/t3st.t](t/t3st.t)
```
k9s0ke_t3st_one -- echo
k9s0ke_t3st_one nl=false
```

These take advantage of the defaults: call `cat` if no command is supplied, expected exit status `rc=0`, expected output `out=''`, add a final newline to the expected output (`nl=true`), stdin from `/dev/null`. The available arguments (before "`--`"; all optional, order doesn't matter) are:
  - `spec='...'`: print this after the test result (in particular, "`# TODO`" directives mark sub-tests as possibly failing, without causing the entire test file to fail)
  - `rc={ $rc | '-$cmp $rc'}`: compare the command's exit status (`$?`) to the supplied value / uses the value as a shell `test` condition (e.g. **`rc='-lt 2'`** checks that `$?` is 0 or 1). If omitted, the expected exit is 0; if set to `''`, the exit status is ignored.
  - `nl={ true | false }`: adds a newline to the expected `out[file]=`, as well as to any `in[file]=` parameters described below. This is the default (most commands work with full lines); override with `nl=false`.
  - `out='expected...'` (default: empty) compare the command's output (including any final newline) to an expected string. See "`nl=`". If you need more complex conditions, use `pp=` ([extras](#extras)).
  - `in='...'`: input to pass on `stdin` to the command; an additional newline is added with the (default) `nl=true`. `in=... nl=false` is unsupported for now &mdash; use [redirects](#redirects), `$k9s0ke_t3st_nl`, and/or `infile=` with repository or temporary files.
  - `infile={ 'path' | [-] }`: redirect the command's input, or **leave stdin alone**; without any `infile=`, all tests run with **`/dev/null` as input**. `nl=` still applies.
  - `outfile='...'`: load `out=` from a file (despite the name this *will not clobber* host files); `nl=` still applies
  - `pp='shell code...'`: post-process the output (available as `$1`) and exit status (`$2`). This code runs within a temporary function; whatever it outputs replaces the original output, and its exit status (from its last statement, or an explicit `return`) replaces the original `$?`. The `rc=` and `out=` parameters then match against these post-processed values. "`pp=`" allows test conditions to become arbitrarily complex.
  - `errexit={ true | false }`: run the test under `set -e` conditions. **Do not use 'set -e' globally** in your `.t` files, as [mentioned](#errexit) in the intro.
  - `nounset={ true | false }`: run the test under `set -u` conditions. You can also `set -u` globally and disable it selectively.
  - `cnt={ true | false }`: the test counter `$k9s0ke_t3st_cnt` normally auto-increments; this can be disabled for pipes and subshells &mdash; see below

A more typical example (from [k9s0ke-shlib](https://gitlab.com/kstr0k/mru-files.kak/-/tree/master/k9s0ke-shlib)):
```
k9s0ke_t3st_one out=abcbcbc nl=false -- __str_subst abbb b bc
```

Note that shell variables (including `in=` and `out=`) cannot contain `NUL` (`\0`) characters. The `infile=`, however, as well as pipes / redirects, can. Preprocess any `NUL`s' before they reach the library (e.g. `eval '... | tr \\0 \\n'`; **`pp=` will not help**).

### Redirects

Here-doc (`<<'EOF'`) redirects work directly, but can't create non-`\n`-terminated inputs.

You can pipe input into `k9s0ke_t3st_one`, but it will possibly run in a different (forked) process. As such, pass `infile=-` (avoids the default `</dev/null`), `cnt=false`, and increment the counter manually after each such test:
```
echo 'XX YY' | k9s0ke_t3st_one out=XX infile=- cnt=false \
  --  eval 'x=$(cat); echo ${#x}'
k9s0ke_t3st_cnt=$(( k9s0ke_t3st_cnt + 1 ))
```

This will also be necessary if you call `k9s0ke_t3st_one` from a subshell.

## Extras

- `k9s0ke_t3st_bailout [message]`: stop testing, output a TAP bailout marker, exit
- `..._one notok_diff={ true | false }`: print actual vs expected results (as TAP "# ..." comments) for failed tests. The default is true.
- `out_rc=$( k9s0ke_t3st_slurp_exec 'prelude' [cmd args]... )`: load a command's output plus exit code into a shell variable. Before executing the command, `eval()` the prelude (e.g. `set -e`). Use this, along with `k9s0ke_t3st_slurp_split`, to avoid truncating final newlines, as the `$()` construct does in all shells. If no command is supplied, it runs `cat`; you may wish to redirect input from a file (`...slurp_exec <...`)
- `k9s0ke_t3st_slurp_split "$out_rc" outvar [rcvar]`: split an `out_rc` string (as obtained above); sets `outvar` to the output and `rcvar` (if supplied and not empty) to the exit status. Both `*var` parameters are variable names (don't prepend a "`$`")

For convenience, the library defines a few **character constants**, most notably `k9s0ke_t3st_nl` (`\n`), but also a tab, `['"<>|&;]` etc (named `k9s0ke_t3st_ch_` + the HTML entity name mostly &mdash; see the source)

## File-based (`_me`) tests

TLDR: [`t/t3st.t`](t/t3st.t) contains two `_me` tests, complete with `.out`, `.rc` and `.exec`.

Call `k9s0ke_t3st_me [ -- cmd...]`; instead of `rc=`, `in=` and `out=`, create `testname.t.{rc,in,out}` files. `nl=false` is assumed. The actual command can be supplied as `..._me()` arguments (after `--` just as with `_one`). If no command is supplied, `_me` (unlike `_one` which defaults to `cat`) looks for an `.exec` file and uses that. If the `.exec` file is not executable, it is run using the system shell `sh`.

`_me()` calls `_one()` internally, so the `in`, `rc`, and `out` defaults still apply, and other parameters can be supplied before `--`.

The expected output `.out` is read in a shell variable, so it still can't contain `NUL` (`\0`) characters. The `.in` file (if any), however, is used as an `infile=` parameter (a real redirect) and thus can contain anything.

`..._me()` can be called multiple times with different arguments, and doesn't preclude invoking regular `_one()` in the same `.t` file. You may wish to stick to one style per test file for clarity, though: all your `_me` tests can consist in a prelude to load the library, plus a single test:
```
k9s0ke_t3st_me
```

## Supported shells

While the library itself only uses POSIX shell code, you may wish to test scripts that require `bash` (or others). This is supported &mdash; the library code will run under a variety of shells. Use an appropriate shebang in your `.t` file, or pass `prove` a `-e` argument. For example, the following has been used to test `t3st` itself with no errors:

```
for shell in dash bash 'busybox sh' mksh yash zsh # posh
  do prove -e "$shell"
done
```

### Individual shell notes

- zsh: the only major difference from POSIX seems to be the `shwordsplit` (`setopt -y`) option being turned off by default. `t3st` avoids this usage and thus needs no workarounds. However zsh has not been fully tested and there may be other problems.
- `posh` only fails the `errexit` test, and only because it doesn't honor `set -e` inside eval.
- FreeBSD sh: works, but has exhibited nested parameter expansion bugs in the past (`t3st` does not currently use this)

## See also

- [TAP consumers](https://testanything.org/consumers.html) if you want to go beyond the widely available `prove` command. It doesn't matter in what language they are written as long as they can parse TAP output. For example, ESR's [tapview](https://gitlab.com/esr/tapview/).
- other frameworks: [`shellspec`](https://github.com/shellspec/shellspec), [`sharness`](https://github.com/chriscool/sharness), [`bats-core`](https://github.com/bats-core/bats-core), [`shspec`](https://github.com/rylnd/shpec), [`assert.sh`](https://github.com/lehmannro/assert.sh)

## Copyright

`Alin Mr. <almr.oss@outlook.com>` / MIT license
