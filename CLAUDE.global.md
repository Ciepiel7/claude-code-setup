# Twarde zakazy (kazdy projekt, kazda sesja)

- **NIGDY nie zamykaj/ubijaj przegladarki uzytkownika** (`taskkill chrome.exe`, `pkill`/`killall` Chrome, `osascript quit` itp.) — glowny Chrome to praca wlasciciela, otwarte karty i sesje. Do automatyzacji sluzy WYLACZNIE dedykowany profil `~/.chrome-claude` (macOS/Linux) albo `%USERPROFILE%\.chrome-claude` (Windows), CDP port 9333, `BU_CDP_URL` w settings.json. Jesli nie dziala, uruchom go przez `bash ~/.claude/scripts/chrome-claude.sh` i nie ruszaj glownego Chrome. Hook `guard-destructive.sh` blokuje ubijanie Chrome.

# Przegladarka: zawsze browser-harness

- Kazda interakcja z webem (automatyzacja, scraping, testy, screenshoty, sprawdzenie strony) idzie przez skill `browser-harness`: w Bash `browser-harness <<'PY' ... PY`.
- MCP `claude-in-chrome`, `chrome-devtools` i wbudowana przegladarka sa blokowane hookiem `browser-gate.sh`.
- Tylko gdy user jawnie prosi o te narzedzia: uruchamia sesje z `ALLOW_BROWSER_MCP=1`. Sam tego nie omijaj.
- Problemy z polaczeniem: `browser-harness --doctor`, potem `bash ~/.claude/scripts/chrome-claude.sh`.
- **Nie kradnij focusu** (wlasciciel pracuje rownolegle): profil automatyzacji chodzi headless (`chrome-claude.sh`, okno tylko z `CHROME_CLAUDE_HEADED=1`). Zakaz `activate_tab`, `switch_tab(activate=True)`, `Page.bringToFront`, `osascript ... activate`, `open` bez `-g`. Karta "hidden"/zamrozony render = restart przez skrypt, nie wyciaganie okna na wierzch.

# No AI slop (ZAWSZE — kazdy tekst poza kodem)

Przy **kazdym** prose poza kodem (odpowiedzi w chacie, commit message, PR, docs, README, UI copy, maile, changelog, marketing) stosuj skill `no-ai-slop`:
- Pelne reguly: `~/.claude/skills/no-ai-slop/SKILL.md`
- Self-check przed oddaniem tekstu: `~/.claude/skills/no-ai-slop/eval.md`
- **Kazda tresc dla ludzi (klient, posty, reklamy, wiadomosci, raporty, oferty) przechodzi DWA przejscia: skill `humanizer` (`~/.claude/skills/humanizer/SKILL.md`), potem `no-ai-slop`.** Decyzja wlasciciela 24.09.2026, obowiazuje w kazdym projekcie.
- **Tekst po polsku (strona, blog, maile, wiadomosci do klientow, posty, raporty, docs) przechodzi TRZECIE przejscie: skill `polszczyzna` (`~/.claude/skills/polszczyzna/SKILL.md`, self-check `eval.md`).** Poprawia jezyk i typografie, nie zmienia tresci. Uruchamiaj sam, bez wywolania przez usera.

**Nie dotyczy:** kodu zrodlowego, configow, komend shell, diffow, danych JSON/YAML, cytatow ktore user kaze zachowac.

Skrot: lead with the point; active voice; konkrety zamiast abstrakcji; bez throat-clearing ("Here's the thing"), binary contrasts ("It's not X. It's Y."), faux-insight, colon reveals, importance puffery, weasel attribution, synonym cycling, dramatic fragments, emoji w naglowkach, dekoracyjnego bolda, em-dash jako default rytmu. Zakazane: delve, leverage, utilize, facilitate, empower, streamline, robust, cutting-edge, paradigm shift, game changer, tapestry, realm, beacon, multifaceted, meticulous, intricate, paramount, transformative, elevate, embark, supercharge, harness, ever-evolving. W chacie: zero fillerow typu "Great question!" / "I'd be happy to help"; koniec na konkretnym punkcie, bez recap.

# Prostota (YAGNI) — kazdy projekt

Przed napisaniem kodu przejdz drabinke i zatrzymaj sie na pierwszym szczeblu, ktory wystarcza:
1. Czy to w ogole musi istniec? Spekulacja na zapas = pomin i powiedz to jednym zdaniem.
2. Jest juz w tym repo (helper, util, typ, wzorzec)? Uzyj. Najpierw szukaj, potem pisz.
3. Robi to stdlib? Uzyj.
4. Robi to platforma natywnie (`<input type="date">` zamiast pickera, CSS zamiast JS, constraint w DB zamiast kodu)? Uzyj.
5. Robi to juz zainstalowana zaleznosc? Uzyj. Nowa zaleznosc dla kilku linii — nie.
6. Da sie w jednej linii? Jedna linia.
7. Dopiero wtedy: minimum kodu, ktore dziala.

- Zero abstrakcji na zapas: interfejs z jedna implementacja, fabryka jednego produktu, config dla wartosci, ktora sie nie zmienia, scaffolding "na pozniej".
- Fix buga = przyczyna, nie objaw. Przed edycja grep po WSZYSTKICH wywolaniach funkcji; guard we wspolnej funkcji, nie w kazdym callerze.
- Swiadome uproszczenie z sufitem oznacz komentarzem: `# ponytail: <sufit>, <upgrade gdy>` (np. `# ponytail: globalny lock, per-konto gdy throughput`).
- Nietrywialna logika (branch, petla, parser, sciezka pieniedzy/security) zostawia JEDEN uruchamialny check: assert w `__main__`/`demo()` albo jeden maly `test_*`. Bez frameworkow, bez suite per funkcja. One-linery testu nie potrzebuja.
- Nie upraszczaj NIGDY: walidacji na granicy zaufania, obslugi bledow chroniacej dane, security, podstaw a11y, niczego, o co user poprosil wprost. User nalega na pelna wersje -> budujesz, bez ponownej dyskusji.

Drabinka skraca ROZWIAZANIE, nigdy czytanie: najpierw przesledz caly przeplyw, ktory zmiana dotyka, potem wybierz szczebel. Najmniejszy diff w zlym miejscu to drugi bug.

# Odpowiedzi o dzialaniu kodu (ZAWSZE — kazdy projekt)

- Kazde twierdzenie "jak dziala X" ma zrodlo `plik:linia` przeczytane W TEJ SESJI.
- `docs/*.md` i wyciag scouta to MAPA, nie dowod. Odpowiedz o dzialaniu kodu bierze sie z kodu.
- Nie czytalem -> pisze "nie sprawdzilem". Zero zgadywania z nazwy funkcji, pliku ani konwencji.
- Oznaczaj: [sprawdzone] = widzialem w kodzie, [wniosek] = wywnioskowane. Bez oznaczenia = sprawdzone.
- Sledz przeplyw do konca: wywolanie -> definicja -> co naprawde zwraca/zmienia. Sygnatura to nie odpowiedz.
- Sprzecznosc z wlasna wczesniejsza odpowiedzia -> mowie od razu, jednym zdaniem, bez owijania.
- Hook `scripts/answer-gate.sh` (UserPromptSubmit) przypomina te regule przy pytaniach o dzialanie. Tylko przypomina.

# Doc-Index System v4

Dokumentacja on-demand: `docs/<basename>.md` per source file. CLAUDE.md = cienki router.

## Format zapisu (1 linia na symbol)
```
fn nazwa(args) -> opis 5-10 slow
hook:nazwa(prio) -> co robi
filter:nazwa -> co robi
enqueue:handle -> sciezka (cache bust)
css:.klasa -> layout/opis
css:--zmienna:#val -> do czego
@media<Xpx -> co sie zmienia
const NAZWA:typ=val -> do czego
```

## Architektura docs/
- Root CLAUDE.md = stack, konwencje, deploy, tabela `## Docs` (source->docs/*.md)
- `docs/<basename>.md` = pelna dokumentacja per source file (on-demand)
- ZERO CLAUDE.md per subdirectory — usuwaj jesli znajdziesz
- Hook szuka `docs/<basename>.md` first, CLAUDE.md fallback

## Sekcje docs/*.md
`## fn` `## hooks` `## css` `## deps` `## fx` `## vars` `## DOM` `## SQL`
Powiazania: `< plik1, plik2` / `> plik1, plik2`

## Reguly
- Indexuj pliki > 30 linii, skip < 10 linii
- Prywatne fn > 15 linii: sygnatura + dlaczego
- Max 10 slow opisu, styl notatkowy
- Przed nowa fn: grep docs/*.md czy istnieje podobna
- Po edycji: sprawdz docs/<basename>.md, dodaj brakujace, update powiazania
- Brak docs/<basename>.md + plik significant -> stworz wg formatu
- Max 80 linii na docs file (wiecej niz v3 bo pelna dokumentacja)

## Root CLAUDE.md projektu
Stack, struktura, konwencje, komendy, tabela `## Docs` mapujaca source->docs/*.md.

## Tier systemu agentow

| Tier | Kto instaluje | Gdzie | Agenty |
|------|--------------|-------|--------|
| 1 — Uniwersalne | `install.sh` (zawsze) | `~/.claude/agents/` | code-reviewer, doc-maintainer, git-workflow, security-auditor, debug-assistant, test-runner, dependency-auditor, project-detector, health-checker |
| 2 — Technologia | `install.sh --type=X` | `~/.claude/agents/` | wp-researcher, css-builder (wordpress) / nextjs-helper (nextjs) / python-helper (python) |
| 3 — Projekt | Recznie lub `--init-project` | `<project>/.claude/agents/` | agenty specyficzne dla projektu |

## Izolacja sesji (OBOWIAZKOWE — multi-session)
Wlasciciel pracuje na WIELU sesjach Claude naraz w KAZDYM projekcie, wszystkie w tym samym katalogu repo. Bez izolacji sesje mieszaja branche i pliki.
- **Na starcie sesji, ZANIM cokolwiek zedytujesz lub zacommitujesz, wejdz do wlasnego worktree** przez `EnterWorktree` (nazwa opisowa wg tematu). Obowiazkowy pierwszy krok kazdej sesji z zapisem.
- Wyjatek: sesja czysto czytajaca/odpowiadajaca (bez edycji i commitow) nie potrzebuje worktree.
- **Zaraz po EnterWorktree**: `bash scripts/worktree-init.sh` jesli projekt go ma, inaczej `bash ~/.claude/scripts/worktree-init.sh` — podpina gitignorowane .env/vendor/node_modules z glownego katalogu (swiezy worktree bez nich nie dziala).
- Worktree zawsze na WLASNEJ galezi — nigdy nie trzymaj w nim wyczekowanego `main` (blokuje checkout maina wszedzie indziej).
- `EnterWorktree` przelacza katalog roboczy w ramach TEJ SAMEJ sesji → `/resume` w glownym katalogu widzi sesje (zywe worktree po Ctrl+W, patrz nizej), git pracuje w izolacji na swiezym branchu od `origin/main`.
- Nigdy nie commituj w glownym katalogu przy pracy rownoleglej; commituj tylko wlasne pliki (`git add <pliki>`, nigdy `-A`).
- **Rytual konca sesji**: w worktree nie zostaje NIC niezacommitowanego — skonczone → PR, nieskonczone → commit WIP + draft PR, smiec → swiadomie skasuj. Porzucona praca ginie bezglosnie.
- Po skonczeniu: `ExitWorktree` (`keep` gdy PR otwarty i wracasz, `remove` gdy zmerge'owane/porzucone).
- Sesje z worktree w `/resume` (stan 2.1.312): picker sam czyta katalogi ZYWYCH worktree, ale DOMYSLNIE pokazuje tylko sesje biezacego worktree. **Ctrl+W** w pickerze = wszystkie worktree repo; nie ma ustawienia, ktore by to utrwalilo. Po `ExitWorktree` Claude sam przenosi transkrypt do katalogu repo. Hook `SessionStart`+`Stop` -> `scripts/prune-worktree-sessions.sh` lata tylko dziure: worktree skasowany bez `ExitWorktree` -> transkrypt przeniesiony do katalogu repo; sprzata tez kopie `.superseded-*` (ten sam inode) i puste katalogi. Zywych worktree nie dotyka (hardlinki kolidowaly z natywnym przenoszeniem).
- Repo z wlasnymi instrukcjami (np. CLAUDE.md projektu) moga doprecyzowac te regule, ale jej nie znosza.

## Git i droga na produkcje (globalny standard — kazdy projekt)
Pelny playbook z checklista: `docs/produkcja.md` w repo claude-code-setup. Twarde minimum:
- Zmiany na `main` TYLKO przez PR z zielonym CI. Male PRy, szybki merge — dlugie galezie to pieklo integracji miedzy sesjami.
- Nowe repo, dzien 1: branch protection (required check CI, block force push) + auto-delete galezi po merge. CI bez `paths-ignore`, gdy job jest required checkiem (deadlock docs-only PR).
- Galezie zmergowane do main = smieci, kasuj bez pytania. `git fetch --prune` przed nowa galezia.
- Migracje DB: nazwy timestampowe `YYYYMMDDHHMM_opis` (numery koliduja miedzy sesjami); styl expand-contract, bo rollback kodu nie cofa schematu.
- Deploy: dump bazy PRZED migracjami, smoke test po przelaczeniu z AUTO-ROLLBACKIEM, tag `prod-*` po sukcesie, crony/infra w repo (nie recznie na serwerze).
- Monitoring od pierwszego usera: alert o fatalach (Telegram/webhook), zewnetrzny uptime monitor, Sentry z DSN w env. Platnosci: klucze testowe na stagingu.

## LLM Wiki (Obsidian) — kazdy projekt
Kazdy projekt ma `wiki/` = pamiec agenta miedzy sesjami (wzorzec Karpathy'ego "LLM Wiki"): Claude czyta na starcie, aktualizuje przed koncem, wiedza sie kumuluje zamiast byc odkrywana od nowa. Obsidian = przegladarka czlowieka (vault = ROOT repo). Procedura: skill `llm-wiki`; regulamin per projekt: `wiki/SCHEMA.md`.
- Brak `wiki/` a zaczynasz istotna prace -> wybierz jednostke pracy (features/experiments/strategies/...), `bash ~/.claude/scripts/wiki-init.sh <folder>`, powiedz co wybrales.
- Jest `wiki/` -> start: `index.md` + `Failed Ideas/ledger.md` + `hot.md`; koniec: strony `updated` + `log.md` + Next Actions. Porzucony pomysl = wiersz w ledger Z POWODEM.
- `docs/` = kod (Doc-Index per plik). `wiki/` = wiedza (domena, decyzje, zrodla, lekcje). Wiki LINKUJE do zrodel prawdy, nie kopiuje.
- Hook Stop commituje tylko `wiki/` + `.obsidian/` (nigdy `-A`), best-effort.

## Model Routing (OBOWIAZKOWE — kazda sesja, kazde zadanie)
Zanim ruszysz zadanie: przypisz je do tieru i napisz JEDNA linie
`route: <zadanie> -> <tier> (<agent>)`. Bez tej linii nie zaczynasz pracy.

**Jedna linia `route:` pokrywa JEDNO zadanie, nie cala sesje.** Nowe zadanie =
nowa linia. Nowym zadaniem jest kazda prosba uzytkownika poza poprawka do tego,
co wlasnie oddales; powrot do tego samego tematu po jego odpowiedzi tez.

Bramki sa DWIE, bo koszt i ryzyko leza na dwoch roznych osiach.

**Bramka ZAPISU stoi przy PIERWSZYM zapisie w zadaniu, nie "na starcie".** Zanim
wywolasz `Edit`, `Write` albo `git commit`, odpowiedz sobie na jedno pytanie:
czy to zadanie rusza wiecej niz ~20 linii ALBO wiecej niz 1 plik? Jesli tak,
a nie odpalales `scout`, to juz lamiesz ta sekcje. "Na starcie" jest nieostre
w dlugiej sesji i dokladnie tam ta regula sie sypie: piszesz `route:` przy
pierwszym pytaniu, a dwie godziny pozniej robisz sam zmiane na 40 plikow,
bo poczucie "przeciez zaczalem od route" zostalo, a zadanie dawno sie zmienilo.

**Bramka CZYTANIA stoi przy TRZECIM pliku, ktorego nie masz w kontekscie.**
Zanim otworzysz kolejny `Read`: czy w tym zadaniu czytalem juz 3 pliki, ktorych
wczesniej nie mialem? Jesli tak — reszta rozpoznania nalezy do `scout`.
Powod jest mierzalny: **89% rachunku to cache, nie pisanie** (odczyt 61%, zapis 28%,
output 11%), a kazdy token wciagniety do kontekstu glownej sesji jest oplacany
srednio **~52 razy**, bo wraca przy kazdej turze. Ten sam plik u scouta jest czytany
raz, na haiku. Nie chodzi o to, ze haiku jest tansze — chodzi o to, **zeby drogi
model nigdy nie wciagnal plikow do kontekstu**. Liczby i metoda: `docs/koszt-kontekstu.md`.
Pilnuje tego hook `scripts/read-gate.sh` (przypomina, nigdy nie blokuje).

| Tier | Model | Co tam idzie |
|---|---|---|
| frontier | model sesji (`/model`, dziedziczony = `inherit`) | planowanie, rozdawanie zadan, review diffu, poprawki punktowe, decyzje nieodwracalne |
| mid | sonnet | implementacja z planu (`implementer`), security, debug, CSS, Next.js/Python/WP helpery, board |
| cheap | haiku | rozpoznanie repo (`scout`), docs, git/commity, testy, health, detect, deps |

Frontier nie jest przybity do nazwy — to zawsze model aktualnie ustawiony w czacie. Zmiana `/model` nie wymaga edycji tego pliku.

Petla zadania implementacyjnego (obowiazkowa, gdy zmiana > ~20 linii lub > 1 plik):
1. `scout` (haiku) -> zwraca `plik:linia — fakt` + touch list. Sesja NIE czyta plikow sama.
2. Sesja planuje z wyciagu: pliki, kroki, kryteria akceptacji.
3. `implementer` (sonnet) per logiczna zmiana -> zwraca `done / not done / assumptions / verify` + `git diff --stat`.
4. Sesja czyta `git diff`, poprawia punktowo (`Edit`), nie przepisuje. Kod od zera pisze tylko, gdy implementer zawiodl (eskalacja).
5. `code-reviewer` (sonnet) gdy diff > ~200 linii albo dotyka auth/DB/platnosci; finalna ocena i tak nalezy do sesji.

**Krok 4 jest warunkiem tych oszczednosci, nie opcja.** Tryb awarii wyciagu i raportu
subagenta jest CICHY: niekompletny wyciag niczego nie wywala, prowadzi tylko do
decyzji na niepelnych danych (dowod w tym repo: implementer zaraportowal przechodzace
testy, ktore nie mialy prawa ruszyc). Im wiecej pracy idzie przez petle, tym WAZNIEJSZY
staje sie krok 4. Kazdy `verify` z raportu uruchamiasz sam.

**Podzial odpowiedzialnosci, ktory chroni jakosc:** `scout` **lokalizuje**, sesja
**ocenia**. Wyciag jest **indeksem, nie zamiennikiem** — przed decyzja zalezna od
dokladnego brzmienia kodu otworz wskazane `plik:linia`. Nigdy nie oddawaj subagentowi
decyzji wymagajacej tresci; oddajesz mu odnalezienie miejsca, nie osad.

Wyjatki od bramki ZAPISU (sesja pisze sama): zmiana < ~20 linii w jednym pliku, poprawka po review.
Wyjatki od bramki CZYTANIA: review, debug i audyt — tam trzeba widziec tresc, nie wyciag.
**"Pytanie bez edycji" NIE jest wyjatkiem od bramki czytania**, ale bramka dzieli role, nie
zwalnia z czytania: scout LOKALIZUJE (`plik:linia`), sesja CZYTA wskazane miejsca sama przed
odpowiedzia. Odpowiedz z samego wyciagu = halucynacja (patrz `# Odpowiedzi o dzialaniu kodu`).
Koszt: pytanie potrafi wciagnac kilkanascie plikow do kontekstu na reszte sesji, wiec czytasz
wskazane linie, nie cale pliki.

Zorientowales sie w trakcie, ze robisz zadanie sam wbrew petli: powiedz to
uzytkownikowi jedna linia i dokoncz przez petle od nastepnego mozliwego kroku
(zwykle diff do `code-reviewer`). Nie dopisuj `route:` wstecz, zeby wygladalo,
ze byl. Cicha kontynuacja jest gorsza niz samo pominiecie, bo zabiera
uzytkownikowi mozliwosc przerwania.

Kiedy jaki `model` w wywolaniu Agent tool:

| Typ subagenta | `model` w wywolaniu | Efekt |
|---|---|---|
| Plan, general-purpose | brak | dziedziczy = frontier = model sesji |
| Explore | `haiku` (wymagane) | hook blokuje brak modelu i frontier; lepiej: `scout` |
| agenci z frontmatterem (scout, implementer, ...) | brak | frontmatter (haiku/sonnet) |

Reguly:
- Twarde wymuszenie = `model:` w frontmatter agenta. Tabela = routing, frontmatter = egzekucja; musza sie zgadzac.
- Eskalacja tylko w gore: cheap zwrocil smiec -> powtorz na mid -> na frontier. Nigdy nie degraduj zadania ktore juz zawiodlo.
- Wynik cheap/mid dotykajacy produkcji, auth, platnosci lub schematu DB przechodzi review na frontier przed merge.
- Override jednorazowy: `model` w wywolaniu Agent tool. Zmiana stala = edycja frontmatter, nie prompt.
- Zero routingu cross-vendor (Kimi/GLM/DeepSeek) — Claude Code routuje wylacznie po tierach Anthropic. Obcy model = osobny proces/proxy, nie ten plik.
- Kontrola: hook PreToolUse/Agent (`scripts/agent-routing.sh`) pokazuje inline `subagent <agent> [<model>] <opis>`, loguje do `~/.claude/agent-routing.log`, blokuje Explore bez haiku/sonnet; `bash ~/.claude/scripts/agent-routing.sh --report` = podsumowanie. `[inherit]` = frontier, nie blad.
- **Slepy punkt kontroli:** hook `agent-routing.sh` widzi WYLACZNIE wywolania Agent tool, wiec sesja, ktora nie odpalila nikogo, nie zostawia w logu zadnego sladu. Pusty log przy duzej zmianie nie znaczy "czysty przebieg", znaczy "petla pominieta" i raport tego nie odrozni. Od teraz `read-gate.sh` przykrywa czesc tej dziury — liczy otwierane pliki i przypomina o scoucie — ale **pilnuje wylacznie CZYTANIA i tylko przypomina**. Bramka ZAPISU ma hook `write-gate.sh` (PreToolUse na `Edit`/`Write`/`MultiEdit`): przy drugim roznym pliku w sesji przypomina o petli, ale **tylko przypomina i nie blokuje**, wiec egzekucja nadal stoi na sesji.

**Dlugosc sesji to osobna dzwignia i zaden tier jej nie zalatwia.** Zmierzone: tura w sesji 1000+ kosztuje
ok. 2,5x wiecej niz w sesji ponizej 50 tur (wzmocnienie kontekstu rosnie 10x -> 66x);
najdluzsze sesje to ponad polowa rachunku. Dlugi kontekst nie poprawia tez jakosci monotonicznie —
sesja na 2000 tur niesie porzucone podejscia i decyzje juz zastapione. Rob `/clear` miedzy
zadaniami. Jest to bezpieczne **dokladnie w takim stopniu, w jakim to, co wazne, trafilo do
`wiki/`** — bez zapisu `/clear` jest czysta strata.

## Agent Coordination
- Subagenty Explore/Plan: zawsze uruchamiaj przed zlozona zmiana
- Worktree dla rownolegiej pracy, nigdy na main bezposrednio
- Memory: zapisuj wzorce w MEMORY.md, szczegoly w topic files

## Agent Teams (Experimental)
Wlaczone w settings.json (`CLAUDE_CODE_EXPERIMENTAL_AGENT_TEAMS=1`).
- Lead koordynuje, teammates pracuja rownolegle z wlasnymi kontekstami
- Komunikacja: mailbox (direct message + broadcast)
- Shared task list z dependency tracking
- Recipes: `agents/team-recipes.md` — 7 kompozycji (full-review, pre-deploy, debug, feature, docs, migration, rust-porting)
- Best practice: 3-5 teammates, kazdy ma wlasne pliki (no overlap), lead syntezuje wyniki

## Workflow dla nowej funkcjonalnosci

1. Stworz branch: `git checkout -b feat/nazwa`
2. Uruchom agent Explore — zbadaj istniejacy kod
3. Uruchom agent Plan — zaplanuj implementacje
4. Zaimplementuj (worktree jesli duza zmiana)
5. Uruchom `test-runner` — sprawdz testy
6. Uruchom `code-reviewer` — sprawdz jakosc
7. Uruchom `security-auditor` jesli zmiana dotyka auth/input/DB
8. Uruchom `git-workflow` — commit + PR

## Biblioteki UI (standard dla wszystkich projektow)

Domyslne zrodla komponentow w kazdym projekcie z shadcn. To sa rejestry shadcn
(`/r/{name}.json`), nie paczki npm — instaluje sie je przez `shadcn add`, nie `npm i`.

- Magic UI — https://magicui.design/
- SmoothUI — https://smoothui.dev/
- Unlumen UI — https://ui.unlumen.com/ (181/233 komponentow free, reszta premium na licencji Polar)
- Componentry — https://componentry.dev/ (52 komponenty, free/open-source, framer-motion)

Blok do wklejenia w `components.json` kazdego projektu:
```json
"registries": {
  "@magicui":  "https://magicui.design/r/{name}.json",
  "@smoothui": "https://smoothui.dev/r/{name}.json",
  "@unlumen":  "https://ui.unlumen.com/r/{name}.json",
  "@componentry": "https://componentry.dev/r/{name}.json"
}
```

Uzycie: `npx shadcn@latest add @magicui/marquee` (analogicznie `@smoothui/...`, `@unlumen/...`, `@componentry/...`).

Reguly:
- Szukajac komponentu UI — najpierw te cztery rejestry, dopiero potem wlasny kod. Nie pisz od zera animowanego marquee/beam/globe, ktory tam juz jest.
- Nowy projekt z shadcn: `shadcn init` i od razu dopisz blok `registries` powyzej.
- Baza primitywow: `radix` (`shadcn init -b radix -p nova`) — najwieksza zgodnosc z rejestrami third-party.
- Wszystkie cztery jada na `motion` + `lucide-react` + `cn()`, zadnych wlasnych primitywow.
- Animowane primitywy: po kazdym `shadcn add` (i w istniejacym projekcie raz) `npx @animate-ui/cli@latest animate all --dry-run`, potem bez `--dry-run`. Podmienia importy `@radix-ui`/`@base-ui` w `components/ui` na `@animate-ui/react/primitives/*` i zdejmuje klasy animacji CSS; dochodza `@animate-ui/react` + `motion`. Komponent, ktory ma zostac statyczny: `--exclude <nazwa>`. Po zmianie `tsc --noEmit` + build.
- Unlumen premium: klucz do `.env.local` jako `UNLUMEN_LICENSE_KEY`, wpis `@unlumen` zmienia sie wtedy na forme obiektowa z naglowkiem `Authorization: Bearer ${UNLUMEN_LICENSE_KEY}`. Bez zakupu zostaw forme stringowa — pusty token psuje tez pobieranie darmowych.


## Design UI i logo (standard dla wszystkich projektow)
- Uzytkownik nie wpisuje /komend. Przy kazdej pracy nad wygladem (strona, sekcja, komponent, dashboard, landing, kolory, fonty, uklad) Claude SAM wywoluje skill przez Skill tool, bez pytania. Hook `design-gate.sh` (UserPromptSubmit) przypomina, ale nie zastepuje tej reguly.
- Glowny plugin do designu UI: `unslop` (skill `unslop:unslop`). Przeglad, poprawka albo redesign ekranu idzie najpierw przez niego.
- Pozostale skille go wspieraja: `frontend-design` przy budowie nowego UI od zera (potem przebieg `unslop`), `ui-registries` po gotowe komponenty shadcn, `web-design-guidelines` i `accessibility-a11y` do audytu, `awwwards-animations` / `gsap-master` do ruchu.
- Logo, znak, favicon, ikona aplikacji, identyfikacja wizualna: skill `logo-design:logo-design` (plugin `logo-design@logo-design-skill`, biblioteka 1400+ SVG, skrypty audytu i eksportu).
- Snapshot strony i story video w `unslop` wymagaja Playwright w projekcie (`npm i -D playwright`) i ffmpeg.
