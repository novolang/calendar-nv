# calendar-nv

Civil time is a date and a time of day with no time zone attached.
`2026-03-15T09:30` is a civil date-time: it says what a wall clock
reads, and it does not say which wall. This package is civil dates,
times and lengths of time for novo-lang, on the proleptic Gregorian
calendar, written and read in the interchange formats of
[ISO 8601](https://www.iso.org/iso-8601-date-and-time-format.html) and
[RFC 3339](https://www.rfc-editor.org/rfc/rfc3339). Five packages on
the registry are built on it:
[chrono-nv](https://novo-lang.org/packages/chrono-nv),
[tz-nv](https://novo-lang.org/packages/tz-nv),
[cron-nv](https://novo-lang.org/packages/cron-nv),
[humantime-nv](https://novo-lang.org/packages/humantime-nv) and
[ntp-nv](https://novo-lang.org/packages/ntp-nv).

## What it is

A **civil date** is a year, a month and a day. A **civil time** is an
hour, a minute, a second and a nanosecond. A **civil date-time** is one
of each. None of the three carries a zone or an offset, so none of them
names an instant. Turning a civil date-time into an instant needs a
zone, and a zone needs either a clock or a database. Both of those are
elsewhere: chrono-nv reads the machine, and tz-nv carries the zone
rules.

The calendar is **proleptic Gregorian**, without exception. Proleptic
means the Gregorian rules are applied to years before the calendar was
adopted. Year 0 exists, year -1 is 2 BC, and the Julian calendar is not
modelled anywhere. This is the rule Rust's `chrono` and Python's
`datetime.date` both use, and it is the rule under which the difference
between two dates is a subtraction rather than a lookup.

A **length of time** is a `TimeDelta`: whole seconds plus a nanosecond
field, signed, exact. It has no month unit, because a month is not a
length of time. Adding months to a date is a calendar operation and
lives in a separate module.

Every constructor **validates**. `civil.date(2023, 2, 29)` answers an
error naming the three numbers it was given, rather than the 1st of
March. Every parser validates the same way, and a parse error carries
the byte offset in the input where the parser stopped.

The types take the names below. Three of the obvious names are declared
by the standard library already, and a package that redeclares one is
refused with error E2000 before it compiles a line.

| Type here | The name in Rust's `chrono` | Why not the obvious name |
| --- | --- | --- |
| `CivilDate` | `NaiveDate` | `Date` is a standard-library struct |
| `CivilTime` | `NaiveTime` | for consistency with `CivilDate` |
| `CivilDateTime` | `NaiveDateTime` | for consistency with `CivilDate` |
| `TimeDelta` | `TimeDelta` | `Duration` is a standard-library struct |
| `Weekday`, `Month` | `Weekday`, `Month` | the obvious names are free |

These are the ranges every value in the package is checked against.

| Field | Range |
| --- | --- |
| Year | -999 999 999 to 999 999 999 |
| Month | 1 to 12 |
| Day | 1 to 31, and no more than the month and year allow |
| Hour | 0 to 23 |
| Minute, second | 0 to 59 |
| Nanosecond | 0 to 999 999 999 |
| Day of the year | 1 to 365, or 366 in a leap year |
| ISO week number | 1 to 52, or 53 in a year that has one |
| Weekday number | 1 for Monday to 7 for Sunday |
| `TimeDelta.nanos` | 0 to 999 999 999, never negative |
| Seconds in a day | 86 400, always |

## Install

```
novo pkg add calendar-nv
```

calendar-nv needs a novo-lang toolchain of 0.9.1 or newer.

## Example

```novo
use arith
use calerror
use iso8601

// The day an invoice issued on `issued` falls due, one month later.
fn due_date(issued: Str) -> Result<Str, CalError>
    // Read the text as a calendar date. A date that does not exist,
    // such as 2026-02-30, is refused here rather than corrected.
    let d = iso8601.parse_date(issued)!

    // Move the date one month on. The day is clamped to the last day
    // of the target month, so the 31st of January becomes the 28th.
    let due = arith.add_months(d, 1)!

    // Write the answer back out as `YYYY-MM-DD`.
    Ok(iso8601.format_date(due))

fn main() [io]
    match due_date("2026-01-31")
        Ok(s)  => println(s)                // 2026-02-28
        Err(e) => println(e.message())
```

Build with `novo pkg build` and run the suites with `novo test`.

## What the package contains

| Module | Contents |
| --- | --- |
| `civil` | The five types, the constructors that validate, the conversions to and from a day number, leap years, month lengths, ordinal dates, ISO week numbers and three-way comparison. |
| `span` | `TimeDelta`, a signed length of time exact to the nanosecond: the constructors from nanoseconds up to days, addition, subtraction, negation, magnitude and comparison. |
| `arith` | Moving a date: days, months, years and a length of time, the three difference operations, and the first and last day of a month. |
| `iso8601` | The two interchange formats in both directions: ISO 8601 dates, times, date-times and durations, and RFC 3339 timestamps with their offset. |
| `strfmt` | A `strftime`-shaped formatter and parser over a named set of directives, in one locale. |
| `calerror` | The ten reasons a value could not be built or a string could not be read, and the byte offset of the one that stopped a parse. |

## How to choose an entry point

There are two formatters, and they answer different questions.

**`iso8601` writes output another program will read.** It is a fixed
grammar with a round-trip guarantee, and it is what an API, a log line
and a configuration file want.

**`strfmt` writes output a person will read.** The caller supplies the
shape, so the same date-time can be printed as `Sunday, 15 March 2026`
or as `15/03/2026`.

There are also two ways to move a date, and the difference is the
subject of rule 2 below. **`arith.add_days` counts days** and is exact.
**`arith.add_months` and `arith.add_years` are calendar operations**
and clamp the day.

## The rules a user needs

1. **Every constructor validates, and refuses rather than normalises.**
   `civil.date(2023, 2, 29)` is `DayOutOfRange(2023, 2, 29)`, not the
   1st of March. The year is carried in the error because February's
   answer depends on it.
2. **`add_months` clamps the day to the last day of the target month.**
   One month after the 31st of January is the 28th of February, or the
   29th in a leap year. This is the reading Rust's
   `chrono::checked_add_months` and Python's
   `dateutil.relativedelta` both take.
3. **That clamp is not reversible.** Add a month to the 31st, subtract
   one, and the answer is the 28th. A caller who needs the round trip
   keeps the original date.
4. **`months_between` counts whole months, so it is not the inverse of
   `add_months`.** From the 31st of January to the 28th of February is
   zero whole months. A difference that answered one could be added
   back and land somewhere else.
5. **A `TimeDelta` has no month unit.** A month is not a length of
   time. `span.days(30)` is thirty days of 86 400 seconds each and says
   so.
6. **A day in `span` is exactly 86 400 seconds.** That is the only
   reading available to a package with no zone in it. A caller who
   means "the same clock time tomorrow" wants `arith.add_days`, which
   moves the date and leaves the time alone.
7. **A `TimeDelta` keeps its sign in the seconds field.** The
   nanosecond field is never negative, so minus one and a half seconds
   is `secs = -2, nanos = 500 000 000`. `span.as_seconds` therefore
   truncates toward negative infinity: `as_seconds(milliseconds(-1500))`
   is -2.
8. **The ISO week-numbering year is not the calendar year.** An ISO
   week runs Monday to Sunday and belongs to the year that holds its
   Thursday. The 1st of January 2027 is a Friday in week 53 of 2026.
   `civil.iso_week` returns both halves together, and there is no
   function that answers the week alone.
9. **`parse_rfc3339` returns the offset beside the value, not folded
   into it.** A `CivilDateTime` has no zone, and the offset the sender
   wrote is information. `Z`, `z` and `-00:00` are all offset 0; RFC
   3339 section 4.3 gives `-00:00` the separate meaning "offset
   unknown", which this package does not model and neither does
   `std.time`.
10. **A leap second is accepted by the RFC 3339 parser and refused by
    the constructor.** RFC 3339 section 5.7 permits a second of 60, and
    `iso8601.parse_rfc3339` maps it onto the first instant of the
    following minute. `civil.time_of(23, 59, 60, 0)` is
    `TimeOutOfRange`, because that value does not exist.
11. **`parse(format(x))` is `x` for every value this package can
    build. The reverse is not promised.** `09:30`, `09:30:00` and
    `09:30:00.000` are one value with three spellings, and output picks
    one. RFC 3339 section 5.6 allows all three.
12. **An ISO 8601 duration may not carry `Y` or `M`.**
    `iso8601.parse_duration("P1M")` is a `BadFormat` naming that
    reason, rather than thirty days. `W` is accepted and is seven days.
13. **A `%` directive outside `strfmt`'s table is an error, not a
    literal.** `UnknownDirective` carries the two characters as written
    and the offset of the `%`. `strfmt.directives()` answers the whole
    list, so a program can show a user what is available.
14. **A `strfmt` format string that cannot determine a date is refused
    before the input is read.** `"%H:%M"` names no day. Missing time
    fields default to midnight, because a date with no time on it is an
    ordinary thing to write.
15. **Parse errors carry a 0-based byte offset into the input, and
    range errors carry -1.** `calerror.offset_of` answers it. The four
    parse reasons point at a byte; the five range reasons are about
    numbers the caller passed in, and there is no string to point at.
    The `Error` trait that `Result<T, CalError>` requires is SPEC
    section 3.4.
16. **A function that answers a `Result` allocates one heap cell for
    the answer.** That holds on the `Ok` path as well as the `Err`
    one, because a `Result` is an enum and an enum is a heap cell. A
    caller moving a date inside a loop can avoid it: `civil.epoch_day`,
    `civil.date_from_epoch_day`, `arith.days_between`,
    `civil.compare_date` and every constructor in `span` answer a plain
    value and touch no heap. `tests/alloc_scan.sh` reads the emitted
    LLVM of those 41 functions and finds no call to the allocator.

## What is not included

- **Time zones, offsets applied to a value, and an instant.** A zone
  needs a clock or a database.
  [tz-nv](https://novo-lang.org/packages/tz-nv) is the database and
  [chrono-nv](https://novo-lang.org/packages/chrono-nv) is the clock.
- **A clock.** There is no `now` here. Every function is arithmetic
  over integers the caller already holds, which is what lets a test pin
  the date without a fixture that freezes time.
- **Leap seconds as values.** A `CivilTime` second of 60 is refused.
  See rule 10 for what the parser does with the text.
- **The Julian calendar.** The proleptic Gregorian rule is applied all
  the way back, so `civil.is_leap_year(1500)` is `false`.
- **`%Z`, `%z` and `%s` in `strfmt`.** The first two are a zone and the
  third needs an epoch, which needs a zone.
- **`%c`, `%x` and `%X` in `strfmt`.** They are locale-defined, and
  this package has one locale: English, ASCII.
- **`%U` and `%W` in `strfmt`.** They are the two non-ISO week
  numberings. `%V` is the ISO one and is present.
- **ISO 8601's basic format, intervals and recurring intervals.**
  `20260315` without separators, `2026-W11` as a whole week, and a
  comma as the decimal mark are all refused.
- **Fractional seconds past the ninth digit.** They are refused rather
  than dropped, because silent truncation is how a round trip stops
  being one.
- **A build for a microcontroller.** Both formatters build strings, and
  a string needs a heap allocator. The arithmetic half touches no heap,
  and the package is not built for a target without one.

## Related packages

- [chrono-nv](https://novo-lang.org/packages/chrono-nv) is the half
  that asks the machine: the wall clock, today, the host's UTC offset
  and a monotonic reading. It depends on this package and declares the
  effects this one does not have.
- [tz-nv](https://novo-lang.org/packages/tz-nv) is the IANA time zone
  database as data, and it turns a civil date-time from this package
  into an instant.
- [cron-nv](https://novo-lang.org/packages/cron-nv) is crontab
  expressions. It computes the next fire in civil time, which is this
  package's arithmetic.
- [humantime-nv](https://novo-lang.org/packages/humantime-nv) reads and
  writes lengths of time as people spell them, such as `2h 30m`, and
  crosses to this package's `TimeDelta`.
- `std.time` in the standard library is the machine's own clocks and
  its own date type. Its `Tz` is a fixed number of minutes east of UTC:
  there is no zone-name lookup, no daylight saving and no historical
  offset table, so `Tz.parse("Europe/Copenhagen")` is `None`. That is a
  decision rather than a gap, written up in `docs/stdlib/time.md`
  under "Timezone data". tz-nv is the package that carries the
  database. `std.time.Duration` is microseconds in an `Int` and is what
  a monotonic clock hands you; `TimeDelta` is signed seconds plus
  nanoseconds and is what subtracting two civil date-times gives.
  chrono-nv is where the two meet.

## Tests

```bash
novo test tests/civil_tests.nv               # 10 tests: the types and the questions
novo test tests/span_tests.nv                #  5 tests: the signed length of time
novo test tests/arith_tests.nv               #  8 tests: moving a date, and the clamp
novo test tests/format_tests.nv              # 10 tests: both formatters, both ways
novo test tests/gregorian_vectors_tests.nv   #  9 tests: the calendar against published values
novo test tests/span_edges_tests.nv          #  5 tests: the ends of a TimeDelta
novo test tests/arith_edges_tests.nv         #  6 tests: the counts that are refused
novo test tests/iso8601_vectors_tests.nv     #  8 tests: every accepted and refused string
novo test tests/strftime_vectors_tests.nv    #  7 tests: every directive, both ways
novo test tests/error_reporting_tests.nv     #  2 tests: what a refusal says and where
```

Seventy tests over ten files.

```bash
bash tests/coverage_union.sh         # 751 of 751 lines of src/ — 100.00%
```

`novo test <file> --cov` measures one file at a time, so that script
unions the ten runs: a line is uncovered overall exactly when every
suite reports it uncovered. No line is excused.

```bash
bash tests/alloc_scan.sh             # the arithmetic path allocates nothing
```

That script compiles `tests/alloc_probe.nv` with optimisation off,
reads the emitted LLVM, and fails if any of the 41 functions named in
it contains a call to `novo_alloc`. Rule 16 above says which functions
are not on that list and why.

The reference implementation is Rust's `chrono`, minus everything that
touches a machine: `NaiveDate`, `NaiveTime`, `NaiveDateTime`,
`TimeDelta`, `Weekday`, `Month`, `checked_add_months` and the `format`
module's directive table. Python's `datetime.date` is the second check,
for the constructor-validates rule and for `isocalendar`. The
day-number conversions are Howard Hinnant's `civil_from_days` and
`days_from_civil`, which are the same algorithms `std.time`'s `Zoned`
uses, so the two agree by construction.

The suite asserts that a date that does not exist is refused and names
its three numbers, that the end-of-month clamp holds in both a leap
year and a common one, that `months_between` counts whole months, that
the sign of a `TimeDelta` lives in the seconds field, that
`parse(format(x))` is `x`, that the ISO week-numbering year differs
from the calendar year at the turn of 2027, and that `%Y` and the rest
of the directive table agree with `directives()`.

## Licence

Apache-2.0. See `LICENSE`.

<!-- docs/writing-a-readme.md is the style guide for this page. -->
