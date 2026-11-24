#!/usr/bin/env python3
"""Regeneruje wiki/hot.md z log.md, ledger i frontmatter stron. Stdlib only, nigdy nie rzuca (exit 0).
Blok Next Actions miedzy markerami jest zachowywany miedzy regeneracjami."""
import datetime
import pathlib
import re
import sys

WIKI = pathlib.Path(__file__).resolve().parent
HOT, LOG, LEDGER = WIKI / "hot.md", WIKI / "log.md", WIKI / "Failed Ideas" / "ledger.md"
N_LOG = 8
NA_START, NA_END = "<!-- NEXT-ACTIONS:START -->", "<!-- NEXT-ACTIONS:END -->"
DEFAULT_NA = "- (uzupelnij)"


def read(p):
    try:
        return p.read_text(encoding="utf-8")
    except OSError:
        return ""


def main():
    entries = [l for l in read(LOG).splitlines() if l.startswith("## [")]
    counts = {}
    for d in sorted(WIKI.iterdir()):
        if d.is_dir() and not d.name.startswith("."):
            n = sum(1 for _ in d.rglob("*.md"))
            if n:
                counts[d.name] = n
    active = sorted(
        f.stem for f in WIKI.rglob("*.md") if re.search(r"^status:\s*active", read(f)[:500], re.M)
    )
    failed = max(0, sum(1 for l in read(LEDGER).splitlines() if l.startswith("|")) - 2)

    m = re.search(re.escape(NA_START) + r"(.*?)" + re.escape(NA_END), read(HOT), re.S)
    next_actions = m.group(1).strip() if m and m.group(1).strip() else DEFAULT_NA
    last = entries[-1][4:14] if entries else "-"
    recent = [e.replace("## ", "- ", 1) for e in entries[-N_LOG:]] or ["- brak"]

    out = [
        "---", "type: hot", f"updated: {datetime.date.today()}", "---",
        "# HOT — stan biezacy",
        "> [!warning] AUTO-GENEROWANE przez `wiki/update_hot.py` (hook Stop). NIE edytuj reka — poza blokiem Next Actions.",
        "",
        "## Stan",
        f"- Ostatni wpis w log: {last} (wpisow: {len(entries)})",
        "- Aktywne (status: active): " + (", ".join(f"[[{a}]]" for a in active) or "brak"),
        f"- Failed Ideas: {failed} (zobacz [[ledger]])",
        "- Strony: " + (", ".join(f"{k} {v}" for k, v in counts.items()) or "0"),
        "",
        "## Ostatnie wpisy (log.md)", *recent,
        "",
        "## Next Actions (edytuj reka, script zachowuje)",
        NA_START, next_actions, NA_END, "",
    ]
    HOT.write_text("\n".join(out), encoding="utf-8")


if __name__ == "__main__":
    try:
        main()
    except Exception as e:  # ponytail: hook nie moze nigdy wywalic sesji
        print(f"update_hot: {e}", file=sys.stderr)
    sys.exit(0)
