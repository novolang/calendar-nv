---
package: calendar-nv
title: Six modules name CalError without use calerror, so a single-file check of any of them fails
slug: six-modules-name-calerror-without-use-calerror
status: wontfix
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

The package was correct: SPEC § 9.2 and § 9.4 allow a module to name a
sibling's type and variants without a `use` line, and `novo pkg build`
accepts it.  The single-file check was the toolchain's defect, filed as
`novo/build-check-of-a-package-module-refuses-a-siblings-type-the-package-build-accepts`
and fixed for novo 0.13.0: a module under `src/` is now checked with the
package's whole module set.  Every module of this package checks on its
own with that toolchain.  Nothing in the package changes.

## History

- 2026-09-26 — filed during the 0.2.0 publish, where the single-file
  check was one of the release gates.
- 2026-09-27 — the defect was the toolchain's single-file check, fixed
  in novo 0.13.0; no change to the package.
- 2026-09-27 — closed as wontfix
