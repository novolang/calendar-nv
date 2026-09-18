# Changelog

All notable changes to calendar-nv are recorded here. The format is
[Keep a Changelog](https://keepachangelog.com/en/1.1.0/), and this
package follows [Semantic Versioning](https://semver.org/spec/v2.0.0.html)
with the pre-1.0 rule that a breaking change bumps the MINOR number.

## 0.1.1 — 2026-09-18

The documentation and comments in plain prose; no signature changed.

## 0.1.0 — 2026-09-18

Civil dates, spans, arithmetic, ISO 8601 and strftime, with ten test
suites beside them.

### Breaking

- **The toolchain floor is 0.9.1**, raised from 0.8.9. `strfmt` writes
  a literal byte of a format string back out with `str.from_byte`,
  which 0.9.1 added. The call that existed before it,
  `str.from_char`, reads its argument as a Unicode code point: a
  format string holding any character above U+007F would come back
  with a replacement character where each of its bytes was. No
  signature changed.

### Added

- `civil.nano_of_day` — the nanosecond of the day a `CivilTime` names,
  which is the one number two times of day are compared by.
- `civil.weekday_of` — the weekday an ISO 8601 day-of-week number
  names, the inverse of `civil.weekday_number`. Both parsers need it:
  an ISO week date and a `%u` directive each arrive as a digit.
- `tests/alloc_probe.nv` and `tests/alloc_scan.sh` — the arithmetic
  path compiled with optimisation off, and a scan of the emitted LLVM
  asserting that none of 41 named functions calls `novo_alloc`.
- Six test suites: the calendar against published values, the ends of
  a `TimeDelta`, the counts each date operation refuses, every accepted
  and refused ISO 8601 string, every `strftime` directive in both
  directions, and what each of the ten refusals says and where it
  points. Seventy tests over ten files.
- `tests/coverage_union.sh` — one line-coverage number for `src/`.
  `novo test --cov` measures one suite file at a time, so the script
  unions the ten runs against a denominator measured from a package
  whose only test touches nothing. It reports 751 of 751 lines, which
  is 100%, with no line excused.

### Changed

- `CivilDate`, `CivilTime`, `CivilDateTime` and `TimeDelta` are
  `@value` structs (SPEC section 14). They are inline storage with no
  cell and no reference count, which is what lets the arithmetic path
  run with the heap untouched. No field name, no field type and no
  function signature changed, and a `@value` struct cannot change the
  meaning of a program the compiler accepts.
- `stability` is `experimental`: the signatures may still move while
  the packages built on this one are written.
- A function that answers a `Result` allocates one heap cell for the
  answer, on the `Ok` path as well as the `Err` one, because a `Result`
  is an enum and an enum is a heap cell. The README names the functions
  that answer a plain value instead.

### Known

- `strfmt.parse` reads `%B` and `%b` as the month rather than only as a
  name checked against the date. A month name names a month, so
  `"%B %d %Y"` is a format that determines a date. `%A` and `%a` are
  read and checked against the date and contribute nothing a date can
  be built from.
- `src/scan.nv` is a new module and is package-internal: nothing in it
  is `pub`, so it is not part of the public interface (SPEC section
  9.2). It holds the byte readers `iso8601` and `strfmt` share.

## 0.0.3 — 2026-09-15

- README rewritten to the package README style guide (docs/writing-a-readme.md); no change to the interface.

## 0.0.2 — 2026-09-10

- **Toolchain floor is 0.8.9**: the signatures use what 0.8.9 added (a bound effect parameter, the four layers), and the manifest says so instead of letting an older toolchain fail on an undefined function.  No signature changed.

## [0.0.1] — 2026-09-09

The declarations: every public type and function with its full
signature, its effect row and its doc comment, and no function bodies.

### Added

- `civil` — `CivilDate`, `CivilTime`, `CivilDateTime`, `Weekday` and
  `Month`, with constructors that validate rather than normalise, the
  epoch-day conversions every other operation is written in terms of,
  leap years and month lengths under the proleptic Gregorian rule,
  ordinal dates in both directions, ISO week numbers in both
  directions, and three-way comparison.
- `span` — `TimeDelta`, signed and exact to the nanosecond, with the
  sign in the seconds field and the nanosecond field never negative.
  Constructors from nanoseconds to days, addition, subtraction,
  negation, magnitude and comparison.
- `arith` — `add_days`, `add_months`, `add_years`, `add_delta`, the
  three difference operations, and the two month boundaries. The
  end-of-month rule is written down here and in the README: the day is
  clamped to the last day of the target month, the operation is not
  reversible, and `months_between` counts whole months so that a
  difference can be added back.
- `iso8601` — calendar, ordinal and week dates; times with a fraction
  to nine digits; RFC 3339 with the offset returned beside the value
  rather than folded into it; ISO durations, which refuse `Y` and `M`
  because a month is not a length of time.
- `strfmt` — a `strftime`-shaped formatter and parser over a named
  subset in one locale, with `directives()` so the list is not only in
  a comment.
- `calerror` — ten reasons, the range ones carrying the numbers they
  saw and the parse ones carrying a byte offset into the input.

### Known

- The type names are `CivilDate`, `CivilTime`, `CivilDateTime` and
  `TimeDelta` rather than `Date`, `Time`, `DateTime` and `Duration`:
  three of those four are standard-library struct names, and a package
  that redeclares one does not compile. The README has the table.
