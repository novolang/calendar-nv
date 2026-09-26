---
package: calendar-nv
title: Six modules name CalError without use calerror, so a single-file check of any of them fails
slug: six-modules-name-calerror-without-use-calerror
status: open
discovered: 2026-09-26
fixed:
version: 0.2.0
toolchain: 0.12.0
platform: linux/x86_64
fixed_in:
class: debt
refs: []
upstream:
related: []
area:
discovered_during:
duplicate_of:
tracker:
---

# Six modules name CalError without use calerror, so a single-file check of any of them fails

## Symptoms

`novo build --check` of a single module under `src/` fails for six of
the seven modules: `arith`, `civil`, `iso8601`, `scan`, `span` and
`strfmt`.  Only `calerror` passes.  Each failure is E2033 on the type
`CalError` and E2003 on its variants, for example:

```text
src/civil.nv:165:19: type error: undefined function: 'MonthOutOfRange' [E2003]
src/span.nv:280:43: type error: undefined type: `CalError`. ... [E2033]
```

`novo pkg build`, `novo pkg publish` and every test file pass.  The
failure is the same on 0.1.1 and 0.2.0.

## Repro

```sh
cd calendar-nv
novo build --check src/civil.nv     # exit 1, six E2003 lines
novo build --check src/calerror.nv  # exit 0
novo pkg build                      # exit 0
```

Expected: every module checks on its own.

## Cause

None of the six modules has a `use calerror` line, although each names
`CalError` or one of its variants.  `novo pkg build` loads every module
under `src/`, so the names resolve there, and each test file that needs
them writes `use calerror` itself.  A single-file check loads only the
modules the file names with `use`, so `CalError` is undefined.
`arith` and `iso8601` fail through `span`, which they `use`.

## Workaround

Check the package with `novo pkg build`, which checks every module.

## Fix

(Filled in when `status` becomes `fixed`.)  The likely fix is a
`use calerror` line in each of the six modules.

## History

- 2026-09-26 — filed during the 0.2.0 publish, where the single-file
  check was one of the release gates.
