#!/usr/bin/env python3
"""Measure and police the Bulan documentation context budget.

Run from the repository root:

    python scripts/context-audit.py

Token figures are ESTIMATES, not tokenizer output. The approximation is
characters / 4, which is the usual rough ratio for English prose and is stable
enough to compare one revision of a document against another. Do not quote
these numbers as exact.

Exit status:
    0  no failures (warnings may still be printed)
    1  at least one enforceable violation
    2  the script was run from the wrong directory

Only the Python standard library is used, so this runs anywhere the repository
can be checked out.
"""

from __future__ import annotations

import argparse
import re
import sys
from pathlib import Path

CHARS_PER_TOKEN = 4

# Directories that are vendored, generated, or build output. Never scanned.
EXCLUDED_DIRS = {
    ".git",
    ".vs",
    ".vscode",
    "build",
    "libs",
    "node_modules",
    "release",
    "debug",
    "moonlight-common-c",
    "qmdnsengine",
    "SDL_GameControllerDB",
    "h264bitstream",
    "soundio",
}

# Documents an agent reads at the start of every session, before it knows what
# the task is. AGENTS.md owns the reading order; this list mirrors it.
STARTUP_SET = [
    "CLAUDE.md",  # loaded automatically by Claude Code, which also pulls AGENTS.md
    "AGENTS.md",
    "HANDOFF.md",
]

# Read on top of the startup set, but only while a task is open.
ACTIVE_TASK_SET = ["TASK-BRIEF.md"]

# Per-file estimated-token ceilings. Exceeding one is a failure.
#
# AGENTS.md is allowed 2150 rather than the 2000 the other entry points get.
# Compressing it further meant cutting whole safety rules -- the push
# authorization, the working-tree ownership handover, the validation-honesty
# clause -- rather than words. The startup package as a whole still fits its
# budget, which is the number that actually costs context every session.
BUDGETS = {
    "AGENTS.md": 2150,
    "CLAUDE.md": 1000,
    "HANDOFF.md": 1000,
    "TASK-BRIEF.md": 1500,
    "BUGS.md": 700,
    # Domain authorities are loaded on demand, not at startup, and carry ~5%
    # headroom so an ordinary one-sentence edit does not trip the gate. FLOW.md
    # gets the most: roughly a third of it is the canonical Mermaid diagram,
    # which cannot be shortened without deleting states or edges.
    "ROADMAP.md": 2200,
    "FLOW.md": 2700,
    "DESIGN-SYSTEM.md": 2100,
    "bulan-creative-brief.md": 2000,
    # REVIEW-CHECKLIST.md is allowed more than a current-authority document
    # because it is a procedure, loaded only when a hardware review is actually
    # being run. Its value is in the detail -- what "wrong" looks like and what
    # it costs -- and compressing that turns checks into things nobody can
    # answer. It is never part of the startup package.
    "REVIEW-CHECKLIST.md": 3800,
}

STARTUP_BUDGET = 4000

# Startup plus an open task brief, before any domain authority is loaded.
TASK_PACKAGE_BUDGET = STARTUP_BUDGET + BUDGETS["TASK-BRIEF.md"]

# Current-state and current-authority documents. These must state one current
# answer rather than striking out an older one.
ACTIVE_DOCS = [
    "AGENTS.md",
    "CLAUDE.md",
    "HANDOFF.md",
    "BUGS.md",
    "ROADMAP.md",
    "FLOW.md",
    "DESIGN-SYSTEM.md",
    "bulan-creative-brief.md",
    "REVIEW-CHECKLIST.md",
    "TASK-BRIEF.md",
]

# Reusable procedures. A dated result belongs in docs/validation/, not here.
PROCEDURE_DOCS = [
    "REVIEW-CHECKLIST.md",
    "BUILDING-WINDOWS.md",
    "BUILDING-DECK.md",
    "BUILDING-MAC.md",
]

# Only AGENTS.md may tell an agent what to read at session start. Anywhere else
# it re-creates the read-everything startup this layout exists to remove.
READING_ORDER_HEADING = re.compile(
    r"^#{1,6}\s+.*(required reading|start every session|before you start reading)",
    re.IGNORECASE,
)
READING_ORDER_PHRASE = re.compile(
    r"required reading|read (?:all|every|each) (?:of the )?(?:relevant |major |project )?document",
    re.IGNORECASE,
)

STRIKETHROUGH = re.compile(r"~~.+?~~", re.DOTALL)

# "# Results — 28 July 2026", "## Validation record — 2 August 2026", etc.
DATED_RESULT_HEADING = re.compile(
    r"^#{1,6}\s+.*\b(?:result|validation|outcome|record|session|review|pass)\w*.*"
    r"\b\d{1,2}\s+(?:january|february|march|april|may|june|july|august|september"
    r"|october|november|december)\s+\d{4}\b",
    re.IGNORECASE,
)

MD_LINK = re.compile(r"(?<!!)\[[^\]]*\]\(([^)\s]+)(?:\s+\"[^\"]*\")?\)")
BACKTICKED_DOC = re.compile(r"`([A-Za-z0-9_][A-Za-z0-9_./-]*\.md)`")
HEADING = re.compile(r"^(#{1,6})\s+(.*?)\s*$")
FENCE = re.compile(r"^\s*(?:```|~~~)")

# Referenced in prose as a convention rather than as an existing file.
DOC_REFERENCE_ALLOWLIST = {"TASK-BRIEF.md", "SPEC-*.md", "BUILDING-*.md"}


class Report:
    def __init__(self) -> None:
        self.failures: list[str] = []
        self.warnings: list[str] = []

    def fail(self, message: str) -> None:
        self.failures.append(message)

    def warn(self, message: str) -> None:
        self.warnings.append(message)


def estimate_tokens(char_count: int) -> int:
    return round(char_count / CHARS_PER_TOKEN)


def slugify(heading_text: str) -> str:
    """GitHub's heading-anchor rule, close enough for link checking."""
    text = re.sub(r"`([^`]*)`", r"\1", heading_text)
    text = re.sub(r"\[([^\]]*)\]\([^)]*\)", r"\1", text)
    text = re.sub(r"[*_~]", "", text)
    text = text.strip().lower()
    text = re.sub(r"[^\w\s-]", "", text, flags=re.UNICODE)
    return re.sub(r"\s+", "-", text)


def strip_code_fences(lines: list[str]) -> list[str]:
    """Blank out fenced blocks so diagrams and shell samples are not parsed."""
    out: list[str] = []
    inside = False
    for line in lines:
        if FENCE.match(line):
            inside = not inside
            out.append("")
            continue
        out.append("" if inside else line)
    return out


def discover_markdown(root: Path) -> list[Path]:
    found: list[Path] = []
    for path in root.rglob("*.md"):
        if any(part in EXCLUDED_DIRS for part in path.relative_to(root).parts):
            continue
        found.append(path)
    return sorted(found, key=lambda p: p.relative_to(root).as_posix())


def measure(root: Path, paths: list[Path]) -> dict[str, dict]:
    measurements: dict[str, dict] = {}
    for path in paths:
        text = path.read_text(encoding="utf-8")
        rel = path.relative_to(root).as_posix()
        measurements[rel] = {
            "path": path,
            "lines": text.count("\n") + (0 if text.endswith("\n") or not text else 1),
            "chars": len(text),
            "tokens": estimate_tokens(len(text)),
            "text": text,
        }
    return measurements


def check_budgets(measurements: dict[str, dict], report: Report) -> None:
    for name, ceiling in sorted(BUDGETS.items()):
        entry = measurements.get(name)
        if entry is None:
            continue
        if entry["tokens"] > ceiling:
            report.fail(
                f"{name}: ~{entry['tokens']} est tokens exceeds its {ceiling} budget"
            )


def check_startup(measurements: dict[str, dict], report: Report) -> tuple[int, int]:
    """Return (startup total, startup plus any open task brief)."""
    total = sum(
        measurements[name]["tokens"] for name in STARTUP_SET if name in measurements
    )
    if total > STARTUP_BUDGET:
        report.fail(
            f"startup package: ~{total} est tokens exceeds the "
            f"{STARTUP_BUDGET} budget"
        )

    task_total = total + sum(
        measurements[name]["tokens"]
        for name in ACTIVE_TASK_SET
        if name in measurements
    )
    if task_total > TASK_PACKAGE_BUDGET:
        report.fail(
            f"startup package plus the active task brief: ~{task_total} est "
            f"tokens exceeds the {TASK_PACKAGE_BUDGET} budget"
        )
    return total, task_total


def check_strikethrough(measurements: dict[str, dict], report: Report) -> None:
    for name in ACTIVE_DOCS:
        entry = measurements.get(name)
        if entry is None:
            continue
        body = "\n".join(strip_code_fences(entry["text"].splitlines()))
        hits = STRIKETHROUGH.findall(body)
        if hits:
            report.fail(
                f"{name}: {len(hits)} strikethrough passage(s); a current document "
                f"states the current answer instead of striking out the old one"
            )


def check_dated_results(measurements: dict[str, dict], report: Report) -> None:
    for name in PROCEDURE_DOCS:
        entry = measurements.get(name)
        if entry is None:
            continue
        for number, line in enumerate(entry["text"].splitlines(), start=1):
            if DATED_RESULT_HEADING.match(line):
                report.fail(
                    f"{name}:{number}: dated result heading in a reusable "
                    f"procedure -- {line.strip()!r}; move it to docs/validation/"
                )


def check_reading_order(measurements: dict[str, dict], report: Report) -> None:
    for name, entry in sorted(measurements.items()):
        if name == "AGENTS.md" or name.startswith("docs/"):
            continue
        for number, line in enumerate(entry["text"].splitlines(), start=1):
            if READING_ORDER_HEADING.match(line):
                report.fail(
                    f"{name}:{number}: a startup reading order outside AGENTS.md "
                    f"-- {line.strip()!r}"
                )

    total = 0
    for name, entry in measurements.items():
        if name.startswith("docs/"):
            continue
        hits = len(READING_ORDER_PHRASE.findall(entry["text"]))
        if hits:
            total += hits
            if hits > 1:
                report.warn(f"{name}: {hits} required-reading phrases")
    if total > 4:
        report.warn(
            f"{total} required-reading phrases across active documents; "
            f"AGENTS.md should be the only place that sets a reading order"
        )


def check_closed_bugs(measurements: dict[str, dict], report: Report) -> None:
    entry = measurements.get("BUGS.md")
    if entry is None:
        return
    for number, line in enumerate(entry["text"].splitlines(), start=1):
        match = HEADING.match(line)
        if match and match.group(2).strip().lower().startswith("closed"):
            report.fail(
                f"BUGS.md:{number}: a Closed section; resolved defects belong in "
                f"a validation report, retrospective, or Git history"
            )


def check_links(root: Path, measurements: dict[str, dict], report: Report) -> None:
    anchors: dict[str, set[str]] = {}
    for name, entry in measurements.items():
        slugs: set[str] = set()
        for line in strip_code_fences(entry["text"].splitlines()):
            match = HEADING.match(line)
            if match:
                slugs.add(slugify(match.group(2)))
        anchors[name] = slugs

    for name, entry in sorted(measurements.items()):
        source_dir = entry["path"].parent
        body = "\n".join(strip_code_fences(entry["text"].splitlines()))

        for target in MD_LINK.findall(body):
            if re.match(r"^(?:[a-z][a-z0-9+.-]*:|//|#)", target, re.IGNORECASE):
                continue
            file_part, _, anchor = target.partition("#")
            if not file_part:
                continue
            resolved = (source_dir / file_part).resolve()
            if not resolved.exists():
                report.fail(f"{name}: link target does not exist -- {target}")
                continue
            if anchor and resolved.suffix == ".md":
                try:
                    rel = resolved.relative_to(root).as_posix()
                except ValueError:
                    continue
                if rel in anchors and anchor.lower() not in anchors[rel]:
                    report.fail(f"{name}: anchor does not exist -- {target}")

        for reference in set(BACKTICKED_DOC.findall(body)):
            if reference in DOC_REFERENCE_ALLOWLIST:
                continue
            if (source_dir / reference).exists() or (root / reference).exists():
                continue
            report.fail(f"{name}: refers to a document that does not exist -- {reference}")


def print_table(
    measurements: dict[str, dict], startup_total: int, task_total: int
) -> None:
    print("Markdown inventory (token figures are ESTIMATES: characters / 4)")
    print()
    print(f"{'file':<44}{'lines':>7}{'chars':>9}{'est tok':>9}  budget")
    print("-" * 78)
    total_tokens = 0
    for name, entry in measurements.items():
        total_tokens += entry["tokens"]
        ceiling = BUDGETS.get(name)
        if ceiling is None:
            note = ""
        elif entry["tokens"] > ceiling:
            note = f"OVER {ceiling}"
        else:
            note = f"{ceiling} ok"
        print(
            f"{name:<44}{entry['lines']:>7}{entry['chars']:>9}"
            f"{entry['tokens']:>9}  {note}"
        )
    print("-" * 78)
    print(f"{'all scanned markdown':<44}{'':>7}{'':>9}{total_tokens:>9}")
    print()
    print("Default startup package (read before the task is known):")
    for name in STARTUP_SET:
        if name in measurements:
            print(f"  {name:<42}{measurements[name]['tokens']:>9}")
    print(f"  {'TOTAL':<42}{startup_total:>9}   budget {STARTUP_BUDGET}")
    if task_total != startup_total:
        for name in ACTIVE_TASK_SET:
            if name in measurements:
                print(f"  {name:<42}{measurements[name]['tokens']:>9}")
        print(
            f"  {'TOTAL WITH ACTIVE TASK':<42}{task_total:>9}"
            f"   budget {TASK_PACKAGE_BUDGET}"
        )
    else:
        print("  (no active task brief)")
    print()


def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument(
        "--quiet",
        action="store_true",
        help="print only failures and warnings, not the inventory table",
    )
    args = parser.parse_args()

    root = Path.cwd()
    if not (root / "AGENTS.md").exists():
        print("error: run this from the repository root", file=sys.stderr)
        return 2

    report = Report()
    measurements = measure(root, discover_markdown(root))

    check_budgets(measurements, report)
    startup_total, task_total = check_startup(measurements, report)
    check_strikethrough(measurements, report)
    check_dated_results(measurements, report)
    check_reading_order(measurements, report)
    check_closed_bugs(measurements, report)
    check_links(root, measurements, report)

    if not args.quiet:
        print_table(measurements, startup_total, task_total)

    if report.warnings:
        print(f"WARNINGS ({len(report.warnings)})")
        for message in report.warnings:
            print(f"  warning: {message}")
        print()

    if report.failures:
        print(f"FAILURES ({len(report.failures)})")
        for message in report.failures:
            print(f"  FAIL: {message}")
        print()
        return 1

    print("context audit passed")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
