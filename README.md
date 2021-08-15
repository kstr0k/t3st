# `t3st`

## _Lightweight shell TAP testing library_

**TLDR**
- clone this repo and run `prove -v t/t3st-hello.t :: --help` ([`...helo.t`](t/t3st-hello.t) is a lightweight demo that also prints further instructions)
- read the self-tests in [`t3st.t`](t/t3st.t) (which uses the [`t3st-ttt0.sh`](t/t3st-lib/t3st-ttt0.sh) framework)
- run `/src/t3st/git-t3st-setup` inside an existing git project

`t3st` is a shell library to produce [TAP output](https://testanything.org/tap-specification.html). It can test shell functions, or any commands / scripts. It requires only a **POSIX shell** (but works under bash / zsh as well as busybox / mksh / BSD sh / others) and a TAP framework (**`prove`** comes with any system perl). The defaults make tests easy to write without sacrificing correctness or flexibility. The test API completely avoids **namespace pollution**, which guarantees complete interoperability with any source. Features:
- easy setup: adding to existing projects (`git-t3st-setup`), and running multiple tests under multiple shells (`git t3st-prove` / `make -C t/`) are one-liners. In addition to the basic library, there is an ["opinionated" framework](#with-the-t3st-ttt0-framework) reducing boilerplate / friction to a minimum.
- output + exit code testing, with precise final newline handling
- full shell integration: tests are real shell scripts with no special formatting or syntax magic; you can request tests conditionally / from loops / inside pipelines
- `errexit` ([`set -e`](#errexit)) and `set -u` tests
- [subshells and pipes](#subshells-and-pipes)
- repeated tests (usable for stress-testing / benchmarking)
- TAP directives (`TODO`)

*Notes*
- development takes place at [**GitLab** `t3st`](https://gitlab.com/kstr0k/t3st) but you can also report issues at the [GitHub `t3st` mirror](https://github.com/kstr0k/t3st).
- watch the [changelog](CHANGELOG.md) if using the `git` version &mdash; there are no API guarantees at this stage


## Highlights

- [Installing](#installing)
- [Usage](#usage)
  - [t3st-ttt0 framework](#with-the-t3st-ttt0-framework)
  - [Hand-rolled](#hand-rolled)
  - [`errexit` & `nounset`](#errexit)
- [Test function](#test-function)
  - [Subshells, pipes](#subshells-and-pipes)
  - [Redirects](#redirects)
- [Extras](#extras)
- [File-based (`_me`) tests](#file-based-_me-tests)
- [Using `prove`](#using-prove)
- [Supported shells](#supported-shells)
- [Copyright & license](#copyright)


## Installing

Add `t3st` to a project directly:
```
cd myproject
URL=https://gitlab.com/kstr0k/t3st/-/raw/master/git-t3st-setup
curl -s "$URL" | sh  # or ... | sh -s -- --tdir=./mytests
```

[Use `prove`](#using-prove), or the git aliases and Makefile targets, to run / add tests :
```
prove -v t/t3st-hello.t :: --help
git t3st-new         # or make -C t/ new
git t3st-prove [-v]  # from anywhere in repo, multiple shells
git t3st-setup       # update / repair
git config t3st.prove-shells 'sh,bash#,etc'  # saved in repo's .git/config
```

The script **adds to `repo/.git/config`** file (displayed at startup), but won't overwrite unrelated (or subsequently modified) settings. Specifically, it
* sets up a no-tags, no-push `kstr0k-t3st` git remote
* creates a test directory (`--tdir=t/` by default) and copies the library to it directly from `git`. It also adds a simple `t3st-hello.t` example with instructions, and a more complete framework (`t/t3st-lib/t3st-ttt0.sh`) for heavier development.
* adds `git` aliases (which conveniently work from anywhere in the repo) to
  - run the tests in multiple shells: `git t3st-prove` (controlled by `git config t3st.prove-shells`)
  - create a new test: `git t3st-new`
  - re-run itself: `git t3st-setup`
* creates a `t3st.mk` makefile (symlinked to `Makefile`) with `t3st-prove` (default) and `new` targets. Use with `make -C t/`
* accepts special setup parameters: `--reset` (removes all `t3st`-related `git` settings as a first step); `--no-setup`: don't re-add `t3st` settings (combine with `--reset`)

For manual installation, clone this repo and run `git-t3st-setup [--help]` from another project. Or just copy `k9s0ke_t3st_lib.sh` in a testsuite.


## Usage

Once you have a `t/` folder with "`*.t`" tests, run them [using `prove`](#using-prove) (or any TAP test harness):
```
prove -v  # or change the shell:
prove -e 'busybox sh'
prove -vr tests  # rename t/, recursive
```

### With the `t3st-ttt0` framework

Run `git t3st-new` (or `make -C t/ new`). Rename and edit `new.t` and `new-e.t` (or delete the latter). `new.t` sources [`t/t3st-lib/t3st-ttt0.sh`](t/t3st-lib/t3st-ttt0.sh) and defines a set of tests in `TTT__tfile_tests`; if needed, extend (see below) or replace methods inside `TTT__tfile_entry`. See the [test function](#test-function), now aliased to `TTT`, `TTT_de` / `TTT_ee` and `TTT_xe` (the `_?e` ones for specific `errexit` disable / enable modes; `_xe` calls `TTT_de`, then `TTT_ee` &mdash; it's not a single test).

The `*.t` methods (`TTT__tfile_*`, &mdash; a file-wide namespace prefix) receive the absolute path to `*.t` in `"$1"`, followed (where noted) by whatever arguments the test harness supplies (e.g. `prove .. :: ARG..`). You can override them; once `...METHOD` is overridden, you can still access the initial default with the corresponding `..._METHOD_0` (i.e. internally, `...METHOD` simply calls `...METHOD_0`). They are (users are normally concerned with the first three):
- `..._tests` (in `new.t`): add tests here
- `..._setup` (in `t3st-ttt0`): by default, sources `k9s0ke_t3st_lib.sh` and defines `TTT*`. Extend this to source other libraries.
- `..._thelp` (in `t3st-ttt0`): by default, prints some debug info.
- `..._entry` (in `new.t`): called by `*.t` itself if run as a script, or by any script using `*.t` as a library
- `..._early` (in `t3st-ttt0`): called right after sourcing `t3st-ttt0`. Sets up some globals (`$..._mypath`, `$...myname`, `$..._mydirn` based on the `*.t` filename; getting this right is rather tricky &mdash; some naive attempts to use `$0` will fail under different scenarios / shells).
- `..._runme` (in `t3st-ttt0`): sequences the other functions. Checks for `--help`, calls `..._setup`, `k9s0ke_t3st_enter`'s, then calls `..._tests`, and finally `k9s0ke_t3st_leave`'s.

### Hand-rolled

A `sample.t` file (using defaults aggressively, and peculiar formatting to highlight tested code) might look like
```
#!/bin/sh
# real shell script -- no syntax / formatting magic

. "$(dirname -- "$0")/k9s0ke_t3st_lib.sh  # or wherever
TTT() { k9s0ke_t3st_one "$@"; }           # or whatever

k9s0ke_t3st_enter

TTT spec='as bare as it gets' \
  -- echo
TTT nl=false rc='-ne 0' spec='standard command "false" -> non-0 exit status' \
  -- false
TTT out=// hook_test_pre='cd /' spec='use eval for multiple commands' \
  -- eval 'printf $PWD; pwd'

if (type __str_subst >/dev/null 2>&1); then
  TTT out=abcbcbc nl=false \
  -- __str_subst abbb b bc
else k9s0ke_t3st_skip 1 \
  'no str_subst (http://gitlab.com/kstr0k/mru-files.kak/-/tree/master/k9s0ke-shlib)'
fi

k9s0ke_t3st_leave
```

That is: source [`k9s0ke_t3st_lib.sh`](k9s0ke_t3st_lib.sh) (along with any tested code you need to reference) and call
- `k9s0ke_t3st_enter [test_plan]` to start TAP output. Omit the plan to have the library count tests automatically and print the plan at the end.
- `k9s0ke_t3st_one [param=value]... [-- cmd args...]` (see [test function](#test-function) for defaults) for each test; it executes everything after "`--`" (a single command or function call &mdash; use `eval '...'` otherwise) in a subshell and checks the output and exit status. Usually aliased to `TTT`.
- `k9s0ke_t3st_me` &mdash; alternative file-based tests (see [`_me` tests](#file-based-_me-tests))
- `k9s0ke_t3st_leave [test_plan]`: ends TAP output. If no plan was given to `..._enter`, it prints the supplied test plan, or generates one that matches the total number of test calls ("1..`k9s0ke_t3st_one`-call-count"). The simplest setup is to not pass a test plan to either `_enter` or `leave`.

### `errexit`

**Don't "set -e" globally** (i.e. outside a `_one` or `_me` call): the library code will refuse to run (it can't properly record exit statuses with `set -e`). Instead, either
- define a shortcut function (`TTT_ee() { k9s0ke_t3st_one errexit=true $@; }`), OR
- use `errexit=true` in individual `..._one` / `..._me` calls, OR
- set a **global errexit default** (`k9s0ke_t3st_g_errexit=true`) in the `.t` file or in the environment (`k9s0ke_t3st_g_errexit=true prove...`), OR
- `set -e` inside the tested code

To run tests with **both `set -e` and `set +e`**, create a `...-e.t` file which adds a global `errexit` default, then sources the base `.t` file. The `-e.t` file can also define additional tests. [t/t3st-e.t](t/t3st-e.t) implements this; so do `new.t` / `new-e.t` generated files (see [t3st-ttt0](#with-the-t3st-ttt0-framework));

`set -u` does not affect operation &mdash; set it either way globally and/or use `set_pre=[-/+]u` parameters (or the `$k9s0ke_t3st_g_set_pre` global default).


## Test function

Call `k9s0ke_t3st_one` once per test in `*.t` (you may want to alias it, e.g. to `TTT`, possibly with some pre-set parameters). Minimal, though contrived, succeeding tests are the first tests in [t/t3st.t](t/t3st.t)
```
TTT() { k9s0ke_t3st_one "$@"; }

TTT -- echo   # expect out=('' + default \n)
TTT in=       # stdin = '' + \n; expect '' + \n
TTT nl=false  # stdin = /dev/null; expect out=''
```

These illustrate the defaults: call `cat` if no command is supplied, expect exit status `rc=0`, expect output `out=''`, add a **final newline** to the expected output (`nl=true`), **stdin from `/dev/null`**. The available arguments (before "`--`"; all optional, in any order; some defaults can be overridden by setting a corresponding **`k9s0ke_t3st_g_...` global**) are:
  - `nl={ true | false }`: adds a newline to the expected `out=`, as well as any `in=` parameters described below (but not to `infile= / outfile=`). This is the default (most commands work with full lines); override with `nl=false`.
  - `out='expected...'` (default: empty) compare the command's output (including any final newline) to the specified string (plus a newline if `nl=true`). For more complex conditions, use `pp=` ([extras](#extras)).
  - `outfile='...'`: load `out=` from a file (*won't clobber* host files, despite the name); `nl=` does not apply.
  - `infile={ 'path' | [-] }`: redirect the command's input, or **leave stdin alone** (use caller's environment); without any `infile=` (or `in=`), all tests run with input from **`/dev/null`**. `nl=` has no influence.
  - `in='...'`: input to pass on `stdin` to the command; an **additional newline** is added with (the default) `nl=true` (even for an empty `in`). For a completely empty input, don't specify either `in=` or `infile=`, or use `in= nl=false`; for a single newline, use `in=` or `in="$k9s0ke_t3st_nl" nl=false`. As noted above, `nl=` also affects expected output.
  - `rc={ $rc | '-$cmp $rc'}`: compare the command's exit status (`$?`) to the supplied value / uses the value as a shell `test` condition (e.g. **`rc='-lt 2'`** checks that `$?` is 0 or 1). If omitted, the expected exit is 0; if set to `''`, the exit status is ignored.
  - `spec='...'`: print this after the test result (in particular, "`# TODO`" directives mark sub-tests as possibly failing, without causing the entire test file to fail). Defaults to the first word of the command. You can also use `todo='comment..'` (syntactic sugar).
  - `pp='shell code...'`: post-process the output (available as `$1`) and exit status (`$2`). This code runs within a temporary function; whatever it outputs replaces the original output, and its exit status (from its last statement, or an explicit `return`) replaces the original `$?`. The `rc=` and `out=` parameters then match against these post-processed values. "`pp=`" allows test conditions to become arbitrarily complex.
  - `errexit={ true | false }`: run the test under `set -e` conditions. Defaults to false or the global `*_g_*` override. [**Do not 'set -e' globally** in `*.t`](#errexit).
  - `set_pre={ -? | +? }*` (e.g. `set_pre=-f` turns off globbing). Defaults to nothing or the global `*_g_*` override.
  - `repeat=N`: repeat this test `N` times, or until it first fails. Defaults to 1, or `$k9s0ke_t3st_g_repeat`.
  - `cnt={ true | false }`: the test counter `$k9s0ke_t3st_cnt` normally auto-increments; this can be disabled for pipes and subshells &mdash; see below

Note that shell variables (including `in=`, `out=`, and the internal variable that stores actual output) cannot contain `NUL` (`\0`) characters. The `infile=`, however, as well as pipes / redirects, can. Preprocess any `NUL`s' before they reach the library (e.g. `eval '... | tr \\0 \\n'`; **`pp=` won't help**).

### Redirects

`infile=` can be used with any local files (permanent or created on the fly). **Here-doc** (`<<'EOF'`) redirects work directly, but can't create non-`\n`-terminated inputs.

You can specify redirects (or anything that changes the environment) in the **pre-test hook**, which runs in the same subshell as the tested command:
```
TTT hook_test_pre='cd /tmp || exit; exec 2>&1' ...
```

The standard error log of each test is normally pasted as TAP '`# `' comments below the test (`prove -v` displays them); `exec 2>/dev/null` in the hook gets rid of it.

### Subshells and pipes

`k9s0ke_t3st_one` can run in a pipeline, but it *might* execute in a different (forked) process than the main script. As such, pass `infile=-` (avoids the default `</dev/null`), `cnt=false` (in case the test part of the pipeline might run in the script process), and increment the counter manually after each such test:
```
echo 'XX YY' | k9s0ke_t3st_one out=XX infile=- cnt=false \
  -- eval 'read -r x rest; echo "$x"'
k9s0ke_t3st_cnt=$(( k9s0ke_t3st_cnt + 1 ))
```

This is also necessary if you call `k9s0ke_t3st_one` from a subshell. If the forked process might run an undetermined number of tests, use
- `k9s0ke_t3st_cnt_save` at the end of a subshell / pipe
- `k9s0ke_t3st_cnt_load` back in the top-level shell


## Extras

- `k9s0ke_t3st_bailout [message]`: stop testing, output a TAP bailout marker, exit
- `k9s0ke_t3st_skip skip_count reason`: mark a few tests as skipped. This keeps the total number of tests constant with conditional tests. The plan (including the final test counter) is printed at the end by default, so this is not required (but helps with debugging).
- `k9s0ke_t3st_g_on_fail={bailout | skip-rest | ignore-rest }` (*experimental*): bailout or skip / ignore all tests after first (non-TODO) failure
- `..._one hook_test_pre=...`: code to be `eval`'d before the test command (defaults to `k9s0ke_t3st_g_hook_test_pre`, or empty). The framework adds additional code to this hook (`errexit` / `set_pre` setup, redirects).
- `..._one diff_on={ ok, | notok, }*`: print actual vs expected results (as TAP "# ..." comments) for some tests. The default is `notok`, or `$k9s0ke_t3st_g_diff_on` if defined. Use '`=ok,notok`' to print all diffs or '`=,`' to print none.
- `..._one` supports key+=value arguments (which append to previous values, or the default). For example, you can have a `TTT_myfun` wrapper which calls `..._one` including a `spec=` argument, then call `TTT_myfun spec+='...'`

### Utilities

- `out_rc=$( k9s0ke_t3st_slurp_exec 'prelude' [cmd args]... )`: load a command's output plus exit code into a shell variable. Before executing the command, `eval()` the prelude (e.g. `set -e`). Use this, along with `k9s0ke_t3st_slurp_split`, to avoid truncating final newlines, as the `$()` construct does in all shells. If no command is supplied, it runs `cat`; to slurp a file, use `...slurp_exec <...`
- `k9s0ke_t3st_slurp_split "$out_rc" outvar [rcvar]`: split an `out_rc` string (as obtained above); sets `outvar` to the output and `rcvar` (if supplied and not empty) to the exit status. Both `*var` parameters are variable names (don't prepend a "`$`")
- `$k9s0ke_t3st_tmp_dir` is a temporary workdir (removed at the end, unless `k9s0ke_t3st_g_keep_tmp = true`). You can use it, but paths starting with `.t3st*` are reserved for the library.
- `k9s0ke_t3st_mktemp outvar` creates a temporary file and sets `outvar` to its path. It will be automatically removed when testing ends (`..._leave` or `..._bailout`).
- `k9s0ke_t3st_dump_str str` outputs a compact one-line representation of a string

For convenience, the library defines a few **character constants**, most notably `k9s0ke_t3st_nl` (`\n`), but also a tab, `['"<>|&;]` etc (named `k9s0ke_t3st_ch_` + the HTML entity name mostly &mdash; see the source)

## File-based (`_me`) tests

TLDR: [`t/t3st.t`](t/t3st.t) contains two `_me` tests, complete with `.out`, `.rc` and `.exec`.

Call `k9s0ke_t3st_me FILE [PARAM=..]..` (like `_one` but without `-- cmd..`); instead of `rc=`, `in=` and `out=`, create `FILE.{rc,in,out}` files. `nl=false` is assumed. The actual command can be supplied as an initial `exec=...` argument (after FILE). If no `exec=` is supplied, `_me()` (unlike `_one()` which defaults to `cat`) looks for an `.exec` file and uses that.

`_me()` calls `_one()` internally, so the `in`, `rc`, and `out` defaults still apply, and other parameters can be supplied.

The expected output `.out` is read in a shell variable, so it still can't contain `NUL` (`\0`) characters. The `.in` file (if any), however, is used as an `infile=` parameter (a real redirect) and thus can contain anything.

`..._me()` can be called multiple times with different arguments, and doesn't preclude invoking regular `_one()` in the same `.t` file. You may wish to stick to one style per test file for clarity, though.


## Supported shells

While the library itself only uses POSIX shell code, it can test scripts that require `bash` (or others) &mdash; the library code works in several shells. Use an appropriate shebang in `*.t`, or pass `prove` a `-e SHELL` argument. The following is being used to test `t3st` itself (with no errors):

```
for shell in dash bash bash44 bash32 'busybox sh' mksh yash zsh 'zsh --emulate sh' posh
  do printf '\n%s\n' "$shell"; prove -e "$shell"
done
# or `git t3st-prove`
```

### Individual shell notes

- `posh` doesn't honor `set -e` inside eval; explicit `errexit=true` tests are auto-skipped.
- FreeBSD sh: works, but has exhibited nested parameter expansion bugs in the past (`t3st` does not currently use this)

### zsh

`t3st` itself does not depend on the following behaviors, but zsh has not been fully tested, so there may be other problems. The major differences from POSIX seem to be that by default:
- `sh_option_letters` = off; some `set -?` options have a different meaning (in particular, '`set -F`', rather than '`-f`', is `noglob`). Avoid this by using `set {+o|-o} OPTNAME` instead of option letters (`+o` = disabled); this will make your code portable to both POSIX shells and `zsh` (for POSIX options, that is).
- `shwordsplit` = off
- `nomatch` = on (causes failures with `set -e`)
- `posixcd` = off, causing directory names starting with `+/-` to be reinterpreted as dirstack entries
- `posixargzero` = off (`$0` switches to the function name inside a function)

Use `set {-|+}o OPTNAME` individually to turn these on/off (don't combine, for maximum portability, and *definitely* don't omit `{+|-}o` before each option). Or invoke zsh with `--emulate [k]sh` to turn on POSIX mode / `ksh` mode (the latter is close to bash). `emulate` also works as a command, or as a wrapper (`emulate sh -c '...'`). Check "`[ "${ZSH_VERSION:-}" ]`" to see if running under zsh (possibly in emulation).


## Using `prove`

`prove` (distributed with `perl`) acts as both a test harness and a TAP producer. Since `t3st` relies on `prove` for shell scripts, some command-line options are more relevant than others (for the full details, review the [`prove perldoc`](https://perldoc.perl.org/prove)):
- `prove [options] [FILE-or-DIR].. [ :: SCRIPT_ARG..]`: `prove` accepts multiple directories and/or files; with no positional parameters, it looks for a `t/` directory. Inside directories (but not subdirs), it looks for `.t` files.
- everything after `::` &mdash; passed to every `*.t` (e.g. `--help`, `--db=...`).
- `-r`: recurse into subdirs too
- `-v`: verbose mode; without it, you won't see individual test names, actual-vs-expected lines, SKIP / TODO's etc &mdash; only a summary.
- `-e SHELL`: controls what shell `prove` uses for all `*.t`'s. Otherwise, executable `.t`'s use their own shebang (`#!`) line, i.e. probably `/bin/sh`. Non-executable `.t`'s get run with Perl, which won't do much good.
- `-j9`: enables parallel execution (don't combine with `-v`)
- `-Q`: really quiet &mdash; no progress
- `--timer`
- `-a tap.tgz`: produces an archive of TAP results, which you can pass to other utilities. The `*.t` in the archive are, somewhat confusingly, TAP logs named identically to the tests that produced them.
- `--formatter=TAP::Formatter::HTML`


## See also

- Projects using `t3st`:
  - [`bashaaparse`](https://gitlab.com/kstr0k/bashaaparse)'s `min-template.sh` (a sh / bash / zsh argument parser) has [tests](https://gitlab.com/kstr0k/bashaaparse/-/blob/master/t/min-template.t) that use temporary files, `pp=` post-processing and `hook_test_pre` to enforce complex conditions (grep in stderr, check globals assigned by code)
  - The [`mru-files.kak` test branch](https://gitlab.com/kstr0k/mru-files.kak/-/tree/test) has a self-contained `t3st` + `git` setup, with separate worktrees / branches. That project includes a [POSIX shell library](https://gitlab.com/kstr0k/mru-files.kak/-/tree/master/k9s0ke-shlib), the [test file](https://gitlab.com/kstr0k/mru-files.kak/-/blob/test/t/k9s0ke-shlib/all.t) for which can also serve as inspiration.
- [TAP consumers](https://testanything.org/consumers.html): if you want to go beyond the widely available `prove` command. The language they're written in doesn't matter as long as they can parse TAP output. For example, ESR's [`tapview`](https://gitlab.com/esr/tapview/). You'll still need to generate the TAP output in the first place; see ["Using prove"](#using-prove) (`-a tap.tgz`).
- other frameworks: [`shellspec`](https://github.com/shellspec/shellspec), [`sharness`](https://github.com/chriscool/sharness), [`bats-core`](https://github.com/bats-core/bats-core), [`shspec`](https://github.com/rylnd/shpec), [`assert.sh`](https://github.com/lehmannro/assert.sh)

## Copyright

`Alin Mr. <almr.oss@outlook.com>` / MIT license
