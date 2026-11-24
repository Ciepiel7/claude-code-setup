# guard-untrusted-repo.sh

PreToolUse/Bash hook: skanuje zdalne repo przez SkillSpector (NVIDIA) zanim Claude je sklonuje
lub zainstaluje. Dwa progi: twarda blokada na malware/instruction override, ostrzezenie
(systemMessage) na reszte HIGH.

## fn
```
allow() -> {"permission":"allow"}, exit 0 (BEZ hookSpecificOutput — patrz fx)
deny(reason) -> permission:deny + hookSpecificOutput.permissionDecision + stderr, exit 2
blocking(issue) -> YARA Match z "[malware]" w pattern | Prompt Injection/Instruction Override
```

## flow
```
stdin JSON -> tool_name != Bash -> allow
command nie pasuje do trigger list -> allow
brak URL github/gitlab w komendzie -> allow
URL na ALLOWLIST -> allow
cache hit -> parse; miss -> skillspector scan --no-llm --format json
blocking() -> BLOCK -> deny (exit 2)
inne HIGH/CRITICAL w WARN_CATS -> systemMessage, exit 0 (komenda idzie dalej)
```

## vars
```
const CACHE=~/.claude/cache/skillspector -> raport JSON per URL (klucz = URL z tr -c A-Za-z0-9 _)
const LOG=~/.claude/skillspector.log -> data \t URL \t BLOCK|WARN opis | ok
const ALLOWLIST=~/.claude/skillspector-allow -> swiadomie zaufane URL, jeden na linie
const WARN_CATS={Prompt Injection, Supply Chain, YARA Match, Privilege Escalation,
                 Data Exfiltration, Rogue Agent} -> kategorie warte ostrzezenia
trigger: git clone | pip install git+ | uv tool install | npx shadcn | plugin install | marketplace add
```

## Kalibracja progow (pomiar 2026-09-22, 39 skilli w ~/.agents/skills)
```
Prompt Injection/Hidden Instructions -> 6/39 skilli, 100% falszywek
  (regula zapala sie na kazdym komentarzu HTML w przykladzie kodu: <!-- LCP image -->)
YARA [agent_skills] -> falszywki na <!-- phpunit.xml --> i na przykladach atakow w docs
Supply Chain/Known Vulnerable Dependency -> JEDYNE prawdziwe trafienie (8 CVE w seo-audit)
```
Stad: blokuja tylko `[malware]` i `Instruction Override`; CVE ida jako ostrzezenie,
bo decyzja "instalowac mimo CVE" nalezy do czlowieka, nie do hooka.

## JSON raportu SkillSpector
```
risk_assessment.score:int 0-100
risk_assessment.severity:str LOW|MEDIUM|HIGH|CRITICAL
issues[].{id,category,pattern,severity,confidence,location.file,location.start_line}
```
Uwaga: klucze to `issues` i `risk_assessment`, NIE `findings`/`risk_score` (te sa w formacie MCP registry).

## fx
- fail-open: brak binarki `skillspector`, blad skanu albo pusty raport -> `allow` + stderr. Hook nie
  moze zablokowac pracy przez wlasna awarie.
- **Sciezka allow NIE zwraca `hookSpecificOutput`.** `permissionDecision:"allow"` w Claude Code
  omija pytanie o zgode dla KAZDEJ przepuszczonej komendy — hook zamienilby sie w globalny
  auto-approve. Brak decyzji = normalny flow uprawnien.
- Top-level `{"permission":"deny"}` (format Cursora) Claude Code IGNORUJE. Bez
  `hookSpecificOutput.permissionDecisionReason` blokada dziala (exit 2), ale model nie
  dostaje powodu i probuje wariantow komendy. Stad oba klucze w jednym obiekcie + stderr.
- SkillSpector nie idzie za symlinkami. `~/.claude/skills` to w ~90% symlinki do
  `~/.agents/skills` — skan tego pierwszego pokryl 4 z 40 skilli i nie powiedzial ani slowa.
  Skanuj katalog docelowy.
- cache jest trwaly per URL — re-scan wymaga `rm ~/.claude/cache/skillspector/<plik>.json`.
  Nie odswieza sie po nowym commicie w skanowanym repo.
- pierwszy skan duzego repo: 1-3 min (clone + 71 wzorcow). Stad `timeout: 180000` w settings.json.
- skanuje tylko pierwszy URL w komendzie.

## deps
```
skillspector (uv tool install git+https://github.com/NVIDIA/skillspector.git)
python3, grep -E
```

## Powiazania
`< settings.json (PreToolUse/Bash, po guard-destructive.sh)`
`> install.sh (--health: sprawdza skrypt + obecnosc binarki)`
