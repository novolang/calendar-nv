# Changelog

All notable changes to calendar-nv are recorded here. The format is
[Keep a Changelog](https://keepachangelog.com/en/1.1.0/), and this
package follows [Semantic Versioning](https://semver.org/spec/v2.0.0.html)
with the pre-1.0 rule that a breaking change bumps the MINOR number.

## [0.0.1] — 2026-09-09

**The interface, published before anyone implements it.** Every public
type and function carries its full signature, its effect row and its
doc comment; every body is `todo()`; the release is recorded
`implemented = false`.

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
- `novo test` is red, and that is the release's expected state: every
  assertion in the API suite reaches
  `not implemented: calendar-nv.<fn>`. Run it with `--isolate` for one
  verdict per test naming the function it stopped at.
