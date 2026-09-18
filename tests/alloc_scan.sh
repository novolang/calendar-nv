#!/usr/bin/env bash
#
# tests/alloc_scan.sh — the arithmetic path allocates nothing.
#
# `novo build` writes a module's LLVM to `_novo/<name>.ll` before it
# invokes clang, so the IR is there to read.  `--opt=0` keeps the
# functions separate.  At the default optimisation level the whole probe
# inlines into `novo_main`, there is nothing left to attribute an
# allocation to, and an assertion that no core function allocates would
# pass because no core function is there.
#
# The list below is every function that answers a plain value.  That is
# an `Int`, a `Bool`, a `CivilDate`, a `TimeDelta` or a `Weekday`.
# Those are `@value` structs and primitives, so they live on the stack
# and the heap is never touched.
#
# The functions that answer a `Result` are left off the list, and the
# reason is worth writing down.  A `Result` is an enum, an enum is a
# heap cell, and the cell is allocated on the `Ok` path as well as the
# `Err` one.  So `civil.date(2026, 3, 15)` costs one allocation for the
# answer whatever the answer is.  That is a property of the language
# rather than of this package, because there is no value-typed enum.  It
# is the reason a caller moving a date in a loop reaches for
# `civil.epoch_day`, `arith.days_between` and
# `civil.date_from_epoch_day`, which are on the list.
#
# Usage: bash tests/alloc_scan.sh [path-to-novo]

set -u
NOVO="${1:-$HOME/.novo/bin/novo}"
PKG="$(cd "$(dirname "$0")/.." && pwd)"
cd "$PKG" || exit 2

rm -rf "$PKG/_novo"
mkdir -p "$PKG/_novo"
if ! "$NOVO" build --opt=0 -o "$PKG/_novo/alloc_probe.bin" tests/alloc_probe.nv \
     > "$PKG/_novo/alloc_scan.log" 2>&1; then
  echo "FAIL the allocation probe does not build"
  grep -E 'error' "$PKG/_novo/alloc_scan.log" | head -5
  exit 1
fi

python3 - "$PKG/_novo/alloc_probe.ll" <<'PY'
import re, sys

ALLOCATION_FREE = """
civil_epoch_day civil_date_from_epoch_day civil_day_of_year civil_is_leap_year
civil_days_in_month civil_weekday civil_weekday_number civil_weekday_of
civil_month_of civil_month_number civil_midnight civil_datetime
civil_nano_of_day civil_compare_date civil_compare_datetime civil_floor_div
civil_days_in_year civil_weekday_index civil_week1_monday civil_compare_int
span_nanoseconds span_milliseconds span_seconds span_minutes span_hours
span_days span_as_seconds span_subsec_nanos span_is_negative span_compare
span_compare_int span_int_max span_int_min
arith_days_between arith_months_between arith_start_of_month
arith_end_of_month arith_floor_div arith_day_span arith_second_span
calerror_offset_of
""".split()

src = open(sys.argv[1]).read()
bodies = dict((m.group(1), m.group(2)) for m in re.finditer(
    r'^define[^\n]*?@([A-Za-z0-9_.]+)\([^\n]*\{\n(.*?)\n\}', src, re.S | re.M))

missing, offenders = [], []
for name in ALLOCATION_FREE:
    body = bodies.get("novo_user_" + name)
    if body is None:
        missing.append(name)
        continue
    n = len(re.findall(r'call[^\n]*@novo_alloc', body))
    if n:
        offenders.append("%s: %d novo_alloc call(s)" % (name, n))

if missing:
    print("FAIL not in the IR, so nothing was measured: " + ", ".join(missing))
    sys.exit(1)
if offenders:
    print("FAIL " + "; ".join(offenders))
    sys.exit(1)
print("OK %d arithmetic functions, zero novo_alloc" % len(ALLOCATION_FREE))
PY
