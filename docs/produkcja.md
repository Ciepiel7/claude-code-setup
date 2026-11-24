# Droga na produkcję — playbook (każdy projekt)

Przy stawianiu
nowego projektu przejdź checklist od góry; przy istniejącym — audytuj wg sekcji.
Zasada nadrzędna: **przy użytkownikach na prodzie liczy się odzyskiwalność i czas
wykrycia awarii, nie skalowanie.** Jeden VPS + atomic deploy uniesie pierwsze
tysiące userów; brak backupu przed migracją nie uniesie jednego złego deployu.

## Dzień 1 nowego repo (5 minut, zanim powstanie kod)

- [ ] Branch protection na `main`: required status check (nazwa joba CI), block force push.
      UWAGA: Claude nie może tego zrobić sam (classifier blokuje PUT na protection) — klik w UI
      albo `gh api -X PUT repos/<owner>/<repo>/branches/main/protection --input protection.json`.
- [ ] Auto-delete gałęzi po merge: `gh api -X PATCH repos/<owner>/<repo> -f delete_branch_on_merge=true`
- [ ] CI z jednym jobem-gatem (lint + testy + audit zależności). **Bez `paths-ignore`**
      jeśli job jest required checkiem — inaczej docs-only PR nigdy się nie zmerguje (deadlock).

## Git (multi-sesja Claude)

- Zmiany na main TYLKO przez PR z zielonym CI. Małe PRy, szybki merge —
  długie gałęzie (100+ commitów) = piekło integracji między sesjami.
- Każda sesja Claude w worktree na WŁASNEJ gałęzi (nigdy main w worktree).
  Po EnterWorktree: projektowy `scripts/worktree-init.sh`, fallback
  `~/.claude/scripts/worktree-init.sh` (.env + vendor/node_modules z głównego katalogu).
- Rytuał końca sesji: zero niezacommitowanej pracy w worktree — PR / draft PR /
  świadome skasowanie. Porzucona praca ginie bezgłośnie.
- Gałęzie zmergowane do main = śmieci, kasuj bez pytania.

## Baza danych

- Migracje nazywane timestampem `YYYYMMDDHHMM_opis.sql` (kolejne numery kolidują
  między równoległymi sesjami; timestamp sortuje się alfabetycznie po starych numerach).
- Migracje w stylu **expand-contract**: nowa kolumna obok starej, stary kod musi działać
  na nowej schemie; usuwanie dopiero w następnym release. Powód: rollback kodu
  (symlink/redeploy) NIE cofa schematu.
- Deploy robi `mysqldump`/`pg_dump` PRZED migracjami (fail dumpa = abort deployu).
- Nocny backup bazy + config, lokalnie z retencją ORAZ offsite (R2/S3).
  Weryfikuj DANYMI (plik z dzisiejszą datą w buckecie), nie opisem w docs.

## Deploy

- Atomic release switch (symlink swap / platformowy odpowiednik) — rollback w sekundy.
- Migracje przed przełączeniem; fail = stary release dalej serwuje.
- **Smoke test po przełączeniu** (curl na 2-3 kluczowe ścieżki, na ORIGIN z pominięciem
  CDN: `curl --resolve domena:443:127.0.0.1`); fail = auto-rollback + czerwony workflow.
- Retencja starych release'ów czyszczona dopiero PO udanym smoke (rollback musi mieć cel).
- Tag `prod-YYYYMMDD-HHMM` po udanym deployu — "co jest na prodzie" bez ssh.
- Staging auto z main, prod tylko ręcznie; te same gate'y na obu (rozjazd gate'ów =
  zielony staging, niepromowalny prod).

## Infra jako kod (anty-dryf)

- Crontab w repo (`config/crontab.prod`), deploy instaluje przez `crontab <plik>`.
  Ręczne `crontab -e` znika przy deployu — celowo. Crony systemowe (/etc/cron.d) poza tym.
- Sekrety w JEDNYM pliku shared poza release'ami (symlink do release); nigdy `sed -i`
  na tym pliku (psuje symlink/właściciela), edycja przez truncate+write.
- Zanim uwierzysz, że automatyzacja działa/nie działa: dowód z danych
  (mtime logu, wiersze w tabeli), nie z dokumentacji.

## Monitoring (od pierwszego użytkownika)

- Alert o fatalach w czasie rzeczywistym: shutdown handler → Telegram/Discord webhook
  (rate-limit ~1/5 min, w 100% defensywny — własne błędy połyka, zero sekretów w treści).
- Sentry (albo odpowiednik) na pełny error tracking — SDK wpięte od początku, DSN z env.
- ZEWNĘTRZNY uptime monitor (UptimeRobot/BetterStack) — monitor na własnym VPS
  nie zauważy padu VPS-a.
- Płatności: klucze TESTOWE na stagingu. Live klucze na stagingu = test płatności
  robi realną transakcję.

## i18n (projekty wielojęzyczne)

- Gate parytetu kluczy w CI (skrypt porównujący tablice tłumaczeń, exit 1 przy różnicy).
  Nigdy `merge -X ours` na plikach tłumaczeń — cicho gubi czyjeś klucze.

