# Claude instructions

## General best practices

- Run shell scripts through shellcheck.
- Use `tmp/` (project-local) for intermediate files and comparison
  artifacts, not `/tmp`. This keeps outputs discoverable and
  project-scoped, and avoids requesting permissions for `/tmp`.

### SESSION.md

While working, if you come across any bugs, missing features, or other
oddities about the implementation, structure, or workflow, **add a
concise description of them to `SESSION.md` at the root of the
repository being worked on** to defer solving such incidental tasks
until later. The file is already covered by my global gitignore, so
just create it if it doesn't exist. You do not need to fix the entries
straight away unless they block your progress; writing them down
is often sufficient. **Do not write your accomplishments into this file.**

## Rust guidelines

- When adding dependencies to Rust projects, use `cargo add`.
- In code that uses `eyre` or `anyhow` `Result`s, consistently use
  `.context()` prior to every error-propagation with `?`. Context
  messages in `.context` should be simple present tense, such as to
  complete the sentence "while attempting to ...".
- Prefer `expect()` over `unwrap()`. The `expect` message should be very
  concise, and should explain why that expect call cannot fail.
- When designing `pub` or crate-wide Rust APIs, consult the checklist in
  <https://rust-lang.github.io/api-guidelines/checklist.html>.
- For ad-hoc debugging, create a temporary Rust example in `examples/`
  and run it with `cargo run --example <name>`. Remove the example after
  use.

### Useful Rust frameworks for testing

- **`quickcheck`**: Property-based testing for when you have an
  obviously-correct comparison you can test against.
- **`insta`**: Snapshot testing for regression prevention. Use `cargo
  insta test` as a stand-in for `cargo test` to run the snapshot tests.

### Writing compile_fail Tests

Use `compile_fail` doctests to verify when certain code should _not_
compile, such as for type-state patterns or trait-based enforcement.
Each `compile_fail` test should target a specific error condition since
the doctest only has a binary output of whether it fails to compile, not
the many reasons _why_. Make sure you clearly explain exactly WHY the
code should fail to compile.

If there is no obvious item to add the doctest to, create a new private
item with `#[allow(dead_code)]` that you add the compile-fail tests to.
Document that that's its purpose.

Before committing, create a temporary example file for each compile-fail
test and check the output of `cargo run --example <name>` to ensure it
fails for the correct reason. Remove the temporary example after.

## Python guidelines

- Always use `uv` as the package manager (`uv add`, `uv run`,
  `uv sync`). Never invoke `pip` directly.
- PyO3 projects are properly set up, so there is no need to compile
  before testing: just run `uv run pytest`. `uv` will recompile as
  needed.

### Testing

- Use `pytest`, not `unittest`.
- **Use on `pytest.mark.parametrize` for any test that varies only
  by input/expected output.** If you catch yourself writing `test_foo_a`,
  `test_foo_b`, `test_foo_c`, stop and parametrize.
- **Use `hypothesis` for property-based testing whenever an
  obviously-correct comparison or invariant exists** (round-trip
  serialization, idempotence, ordering invariants, equivalence
  against a slow reference implementation). Use `@given` strategies;
  let `hypothesis` shrink failures rather than crafting fixtures by hand.
- Combine the two when it fits: `@pytest.mark.parametrize` over
  scenarios, `@given` over input space within each scenario.

### Style

- Type-annotate all public functions and class attributes. Type-check
  with `ty`, format & lint with `ruff`: `ty check`, `ruff format`,
  `ruff check --fix`.
- Prefer `pathlib.Path` over `os.path` string manipulation.
- Use `dataclasses` or `pydantic` models over ad-hoc dicts at API
  boundaries.

## Git workflow

Use the `commit-writer` skill, if available, to draft commit messages.
It reads the current diff and produces a message following the
conventions below.

Make sure you use git mv to move any files that are already checked into
git.

When writing commit messages, ensure that you explain any non-obvious
trade-offs we've made in the design or implementation.

Wrap any prose (but not code) in the commit message to match git commit
conventions, including the title. Also, follow semantic commit
conventions for the commit title.

When you refer to types or very short code snippets, place them in
backticks. When you have a full line of code or more than one line of
code, put them in indented code blocks.

## Documentation preferences

### Documentation examples

- Use realistic names for types and variables.

## Code style preferences

Document when you have intentionally omitted code that the reader might
otherwise expect to be present.

Add TODO comments for features or nuances that were deemed not important
to add, support, or implement right away.

### Literate Programming

For code with non-trivial logic — multi-phase algorithms, business
rules, integration points — write it to read top-down like a narrative:

- **Explain the why.** Comments should cover business logic, design
  decisions, and constraints — not restate what the code obviously
  does.
- **Use section banners** to mark logical phases, with a short prose
  lead-in before the code:

  ```rust
  // ==============================================================================
  // Plugin Configuration Extraction
  // ==============================================================================
  // First, we extract plugin metadata from Cargo.toml to determine
  // what files we need to build and where to put them.
  ```

- **Put context next to code**, not in a header docblock far away:

  ```python
  # Convert timestamps to UTC for consistent comparison across time zones.
  # This prevents edge cases where local time changes affect rebuild detection.
  utc_timestamp = datetime.utcfromtimestamp(file_stat.st_mtime)
  ```

- **Prefer well-commented inline code over premature decomposition.**
  Extract a function for genuine reuse, not for file organization.

Skip this style for plumbing, trivial wrappers, and code whose intent
is already clear from the signature — over-commenting obvious code is
its own kind of noise.

## Claude Code sandbox insights

### `!` (negation) workaround

The sandbox has a [separate bug][cc-24136] where the bash `!` keyword
(pipeline negation operator) is treated as a literal command name. The
command after `!` **never executes**. This affects `if !`, `while !`,
and bare `!`. The trailing-`;` workaround does **not** fix this.

```sh
# Broken:
if ! some_command; then handle_failure; fi

# Workaround — capture $?:
some_command; rc=$?
if [ "$rc" -ne 0 ]; then handle_failure; fi

# Broken:
while ! some_command; do sleep 1; done

# Workaround — use `until`:
until some_command; do sleep 1; done
```

[cc-24136]: https://github.com/anthropics/claude-code/issues/24136

### Unsandboxable commands

The following commands can never be run successfully inside the sandbox,
and thus must always be run with `dangerouslyDisableSandbox: true`.
Because they cannot be run inside the sandbox, avoid running them in
bash invocations with other commands (e.g., using `|`, `&&` or `||`).
Instead, capture their output to a file, and then operate on that file
in subsequent commands, which can then be sandboxed.

Known unsandboxable commands are:

- `gh`
- `perf record` (but _not_ `perf script`)

### Sandbox discipline

Never use `dangerouslyDisableSandbox` preemptively. Always attempt
commands in the default sandbox first. Only bypass the sandbox after
observing an actual permission error, and document which error
triggered the bypass. The standing exceptions are the commands known to
be unsandboxable.

### Prefer temp files over pipes for sub-agent CLI testing

When testing a CLI with ad-hoc input, write the input to a temp file
in `tmp/` using the Write tool (not `cat`/`echo` with heredoc + `>`),
then pass it by path rather than piping. This avoids interactive
permission prompts in sub-agents.

## Common failure modes when helping

### The XY Problem

A user with goal X often asks about their attempted solution Y rather
than X itself. Answering Y literally then wastes time on a suboptimal
path. Watch for narrow, oddly-specific, or roundabout requests with
no stated motivation — classic tell: "how do I get the last 3
characters of a filename?" when they want the file extension.

When you spot the signal, ask about the underlying goal before
answering ("what are you trying to accomplish overall?", "have you
considered ...?") and be willing to propose a different approach.

## Golden Rule

**Always prefix commands with `rtk`**. If RTK has a dedicated filter, it uses it.
If not, it passes through unchanged. This means RTK is always safe to use.

**Important**: Even in command chains with `&&`, use `rtk`:
```bash
# ❌ Wrong
git add . && git commit -m "msg" && git push

# ✅ Correct
rtk git add . && rtk git commit -m "msg" && rtk git push
```
