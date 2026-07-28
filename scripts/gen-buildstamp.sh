#!/bin/sh
#
# Writes a one-line header naming the commit the binary is being built from, so
# the app can state it in its log at startup.
#
# Why this exists: three sessions on this project drew conclusions from a build
# that was not the one on screen -- an old instance still running, an interface
# served from a stale cache, or the Deck's Flatpak recipe building a source path
# that was not the checkout in front of the person. Every one of those was
# diagnosed by inference from outside the app, and every one was diagnosed wrong.
# The log saying it outright costs one line and ends the guessing.
#
# Two things matter about how this is generated:
#
#   It runs on every build, not at qmake time. A stamp that can describe an
#   older commit than the binary carrying it is worse than no stamp at all --
#   it does not merely fail to help, it actively misleads, which is the exact
#   failure mode it exists to prevent.
#
#   It only rewrites the header when the value actually changes. Otherwise
#   every single build would recompile main.cpp and relink.
#
# Usage: gen-buildstamp.sh <output-header> <source-dir>

set -e

OUT="$1"
SRC="$2"

if [ -z "$OUT" ] || [ -z "$SRC" ]; then
    echo "usage: $0 <output-header> <source-dir>" >&2
    exit 1
fi

# --dirty marks uncommitted changes, which is the normal state mid-session and
# is itself worth seeing. Failures are swallowed: a tarball or an exported tree
# is a legitimate way to build this, and "unknown" is an honest answer.
DESCRIBE=$(cd "$SRC" && git describe --always --dirty --tags 2>/dev/null || true)
BRANCH=$(cd "$SRC" && git rev-parse --abbrev-ref HEAD 2>/dev/null || true)

[ -n "$DESCRIBE" ] || DESCRIBE="unknown"
[ -n "$BRANCH" ] || BRANCH="unknown"

printf '#define BUILD_STAMP_STR "%s @ %s"\n' "$BRANCH" "$DESCRIBE" > "$OUT.tmp"

if cmp -s "$OUT.tmp" "$OUT"; then
    rm -f "$OUT.tmp"
else
    mv "$OUT.tmp" "$OUT"
fi
