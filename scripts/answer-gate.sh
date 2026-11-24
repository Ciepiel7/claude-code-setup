#!/bin/bash
# answer-gate.sh — UserPromptSubmit hook: przypomina o zrodle "plik:linia" przy pytaniach
# o dzialanie kodu ("jak dziala X", "co robi Y"). Ogolne "dlaczego/czemu/why" strzela tylko razem ze slowem o kodzie.
# NIGDY nie blokuje (zawsze exit 0) — to tylko przypomnienie, nie gate na tool call.
#
# Po co: docs/*.md i wyciag scouta to mapa, nie dowod. Odpowiedz o dzialaniu kodu
# bierze sie z kodu przeczytanego w tej sesji. Regula: CLAUDE.md #
# "Odpowiedzi o dzialaniu kodu".

PY=python3; command -v python3 >/dev/null 2>&1 || PY=python

HOOK_INPUT="$(cat || true)" $PY - <<'PY' 2>/dev/null
import sys, json, os, re

try:
    d = json.loads(os.environ.get("HOOK_INPUT", ""))
except Exception:
    sys.exit(0)

prompt = d.get("prompt") or ""
if not prompt:
    sys.exit(0)

STRONG = re.compile(
    r"jak (to |ten |ta |te )?dzia[lł]a"
    r"|jak jest (to )?zrobion"
    r"|jak (to )?zaimplementowan"
    r"|jak (to )?liczy"
    r"|co (dokladnie |dokładnie )?robi"
    r"|sk[aą]d (sie |się )?bierze"
    r"|sk[aą]d wie"
    r"|w kt[oó]rym miejscu"
    r"|gdzie jest (obs[lł]ugiwan|liczon|ustawian)"
    r"|where is .* (handled|set|computed)",
    re.IGNORECASE,
)

WEAK = re.compile(r"dlaczego|czemu|why (does|is|do)|how (does|is|do)|what does", re.IGNORECASE)
CODE = re.compile(
    r"kod|funkcj|plik|klas|metod|hook|endpoint|komponent|modu[lł]|skrypt|zwraca|zapytani"
    r"|function|file|class|method|component|module|script|return|query|handler|middleware",
    re.IGNORECASE,
)

if not (STRONG.search(prompt) or (WEAK.search(prompt) and CODE.search(prompt))):
    sys.exit(0)

print(
    "[answer-gate] Pytanie o dzialanie kodu. Zanim odpowiesz:\n"
    "- kazde twierdzenie ma `plik:linia` przeczytane w TEJ sesji; docs/*.md i wyciag scouta to mapa, nie dowod\n"
    "- nie czytales -> \"nie sprawdzilem\"; oznaczaj [sprawdzone] / [wniosek]; sledz przeplyw do definicji, nie do sygnatury"
)
PY
exit 0
