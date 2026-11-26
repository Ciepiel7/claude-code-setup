#!/bin/bash
# design-gate.sh — UserPromptSubmit hook: przy rozmowie o designie UI albo logo kaze Claude
# SAMEMU wywolac skill (unslop / logo-design), bo uzytkownik nie musi wpisywac /komend.
# NIGDY nie blokuje (zawsze exit 0) — tylko dokleja kontekst. Regula: CLAUDE.md # "Design UI i logo".

PY=python3; command -v python3 >/dev/null 2>&1 || PY=python

HOOK_INPUT="$(cat || true)" $PY - <<'PY' 2>/dev/null
import sys, json, os, re

try:
    d = json.loads(os.environ.get("HOOK_INPUT", ""))
except Exception:
    sys.exit(0)

prompt = d.get("prompt") or ""
if not prompt or prompt.lstrip().startswith("/"):
    sys.exit(0)  # jawna komenda: nie dublujemy

LOGO = re.compile(
    r"\blog(o|a|iem|otyp\w*)\b|favicon|ikon\w* aplikacji|app icon|sygnet|znak firmow"
    r"|identyfikacj\w* wizualn|branding|brand ?(mark|kit|book)|ksi[eę]g\w* znaku",
    re.IGNORECASE,
)
UI = re.compile(
    r"design|redesign|\bui\b|\bux\b|wygl[aą]d|[lł]adn\w*|brzydk|styl(e|u|ow|izacj)|layout|uk[lł]ad"
    r"|landing|\bhero\b|dashboard|sekcj\w|typografi|font|kolor|palet|odst[eę]p|spacing|padding"
    r"|przycisk|button|tailwind|\bcss\b|makiet|mockup|frontend|interfejs|slop|jak z ai|wygenerowan\w* przez ai",
    re.IGNORECASE,
)

out = []
if LOGO.search(prompt):
    out.append("- temat LOGO/identyfikacji -> wywolaj teraz Skill `logo-design:logo-design` (plugin logo-design)")
if UI.search(prompt):
    out.append("- temat DESIGNU UI -> wywolaj teraz Skill `unslop:unslop` (glowny plugin do designu); nowe UI od zera: najpierw `frontend-design:frontend-design`, potem przebieg `unslop:unslop`")
if not out:
    sys.exit(0)

print("[design-gate] Uzytkownik nie wpisuje /komend. Uzyj skilla SAM, bez pytania, zanim zaczniesz prace:\n"
      + "\n".join(out)
      + "\n- pytanie niezwiazane z wygladem (np. kolor w logach, font w terminalu) -> zignoruj to przypomnienie")
PY
exit 0
