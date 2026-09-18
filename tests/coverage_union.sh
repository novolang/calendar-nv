#!/usr/bin/env bash
#
# tests/coverage_union.sh — one line-coverage number for src/.
#
# `novo test --cov` measures one suite file at a time, and this package
# has ten of them, so no single run answers what fraction of src/ the
# tests cover.  This script unions the runs.
#
# A line is uncovered overall exactly when every suite reports it
# uncovered, so the answer is the intersection of the per-suite
# uncovered sets.  The denominator is every instrumented line in src/.
# It is measured by running a package whose only test touches nothing,
# so that every line of src/ comes back uncovered and the list is the
# whole of it.
#
# Usage: bash tests/coverage_union.sh [path-to-novo]

set -u
NOVO="${1:-$HOME/.novo/bin/novo}"
PKG="$(cd "$(dirname "$0")/.." && pwd)"

python3 - "$PKG" "$NOVO" <<'PY'
import glob, os, re, shutil, subprocess, sys, tempfile

PKG, NOVO = sys.argv[1], sys.argv[2]
SRC = set(os.path.basename(p) for p in glob.glob(os.path.join(PKG, "src", "*.nv")))


def uncovered(pkg, suite):
    out = subprocess.run([NOVO, "test", suite, "--cov", "--report=text"],
                         cwd=pkg, capture_output=True, text=True).stdout
    m = re.search(r"Lines uncovered:([^\n]*)", out)
    if m is None:
        return None
    return set(t for t in m.group(1).split() if t.split(":")[0] in SRC)


tmp = tempfile.mkdtemp()
base = os.path.join(tmp, "calendar-nv")
shutil.copytree(PKG, base, ignore=shutil.ignore_patterns("_novo", ".git"))
shutil.rmtree(os.path.join(base, "tests"))
os.mkdir(os.path.join(base, "tests"))
open(os.path.join(base, "tests", "empty_tests.nv"), "w").write(
    "use std.test\n\n@test\nfn test_nothing() [io]\n    test.assert(true)\n")
universe = uncovered(base, "tests/empty_tests.nv")
shutil.rmtree(tmp)
if universe is None:
    print("FAIL could not measure the instrumented lines of src/")
    sys.exit(1)

rest = set(universe)
suites = sorted(glob.glob(os.path.join(PKG, "tests", "*_tests.nv")))
for suite in suites:
    u = uncovered(PKG, os.path.relpath(suite, PKG))
    if u is None:
        print("FAIL %s did not report coverage" % os.path.relpath(suite, PKG))
        sys.exit(1)
    rest &= u

total = len(universe)
covered = total - len(rest)
print("%d of %d line(s) of src/ covered by %d suite(s) — %.2f%%"
      % (covered, total, len(suites), 100.0 * covered / total))
if rest:
    print("FAIL uncovered: " + " ".join(sorted(rest)))
    sys.exit(1)
print("OK every line of src/ is covered")
PY
