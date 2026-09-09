# calendar-nv

**Status: NOT IMPLEMENTED — interface only.**

Every public function below is published with its signature and its
effect row, and every body is `todo()`. Installing this package works;
calling it panics with `not implemented`.

## What this is

Dates, times and durations with **no clock in them**. Construction that
refuses `2023-02-29` instead of guessing what you meant; day and month
arithmetic with the end-of-month rule written down rather than
discovered; ISO 8601 and RFC 3339 in both directions; ISO week numbers,
leap years and ordinal dates; and a `strftime`-shaped formatter over a
subset this package names.

It is the arithmetic half of chrono. The half that asks a machine what
time it is — `now`, the local offset, a monotonic reading — is
`chrono-nv`, which depends on this one.

```
novo pkg add calendar-nv
novo pkg build
novo test
```

## The one example that will work

```novo
use civil
use arith
use iso8601

fn invoice_due(issued: Str) -> Result<Str, CalError>
    let d = iso8601.parse_date(issued)!
    let due = arith.add_months(d, 1)!
    Ok(iso8601.format_date(due))
```

`invoice_due("2026-01-31")` is `"2026-02-28"`. That is the rule, and it
is the reason the next section is where it is.

## The load-bearing interface

```novo
pub fn add_months(d: CivilDate, n: Int) -> Result<CivilDate, CalError>
```

Not a type: a rule. "One month after the 31st of January" has no
arithmetic answer, every date library picks a reading, and most of them
do not write it down.

**The day is clamped to the last day of the target month.**

```
add_months(2026-01-31, 1)  ==  2026-02-28
add_months(2024-01-31, 1)  ==  2024-02-29
```

Three things follow, and every other decision in the package is
downstream of them:

- the operation is **not reversible** — add a month to the 31st,
  subtract one, and you have the 28th;
- `months_between` is therefore **not** its inverse: January 31st to
  February 28th is *zero* whole months, so that a difference can be
  added back without landing somewhere else;
- a `TimeDelta` has **no month unit at all**, because a month is not a
  length of time. `span.days(30)` is thirty days and says so.

## The layer, and why

`core` — no effects, and no argument required. There is no clock here,
no zone database and no file. Every function is arithmetic over
integers the caller already holds, which is also what makes the package
testable without a fixture that freezes time.

## The names, and the three that were taken

The types are chrono's naive family under the other standard name for
the same idea:

| here | chrono | why not the obvious name |
| --- | --- | --- |
| `CivilDate` | `NaiveDate` | `Date` is a standard-library struct; redeclaring it is a compile error |
| `CivilTime` | `NaiveTime` | for consistency with the above |
| `CivilDateTime` | `NaiveDateTime` | for consistency with the above |
| `TimeDelta` | `TimeDelta` | `Duration` is a standard-library struct — and chrono renamed its own for the same reason |
| `Weekday`, `Month` | `Weekday`, `Month` | — |

`std.time.Duration` is a different type and stays one: it is
microseconds in an `Int` and is what a monotonic clock hands you, while
`TimeDelta` is signed seconds plus nanoseconds and is what you get by
subtracting two civil date-times. `chrono-nv` is where the two meet,
because that is where a clock is.

## The reference implementation

Rust's `chrono`, minus everything that touches a machine: `NaiveDate`,
`NaiveTime`, `NaiveDateTime`, `TimeDelta`, `Weekday`, `Month`,
`checked_add_months` and the `format` module's directive table. Python's
`datetime.date` for the constructor-validates rule and for
`isocalendar`. Howard Hinnant's `civil_from_days` / `days_from_civil`
for the day-number conversions — the same algorithms `std.time`'s
`Zoned` uses, so the two agree by construction.

Deliberately left out, and where it went instead:

- **`Utc`, `Local`, `TimeZone`, `DateTime<Tz>`, `Offset`** — a zone
  needs a clock or a database. `chrono-nv` and `tz-nv`.
- **`Duration::days` as a calendar month** — chrono does not do this
  either, and neither does anything here.
- **`%Z`, `%z`, `%s`, `%c`, `%x`, `%X`, `%U`, `%W`** in the formatter —
  the first three need a zone, the rest need a locale, and this package
  has one locale.
- **Leap-second values.** `civil.time_of(23, 59, 60, 0)` is an error;
  RFC 3339's `:60` is accepted by the parser and lands on the following
  minute, which is what `std.time` does with the same string.

## Status

Every function is `todo()`. `novo test` runs the API suite, and every
assertion in it reaches `not implemented: calendar-nv.<fn>` — the
expected result until the bodies land. Run it with `--isolate` for one
verdict per test naming the function it stopped at.

| module | functions | implemented |
| --- | --- | --- |
| `calerror` | 1 | no |
| `civil` | 18 | no |
| `span` | 14 | no |
| `arith` | 9 | no |
| `iso8601` | 10 | no |
| `strfmt` | 3 | no |
