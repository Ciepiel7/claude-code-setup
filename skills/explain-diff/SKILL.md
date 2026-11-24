---
name: explain-diff
description: >
  Explains the user's own code changes in plain Polish so a non-expert understands
  what the code does: one-sentence summary, a flow diagram, before/after per file,
  glossary, risks. Use on "/explain-diff", "wytlumacz moje zmiany", "co robi ten diff",
  "rozrysuj co zmienilem", before or after a commit/PR.
---

# Explain diff

Cel: wlasciciel kodu ma po 2 minutach wiedziec, co robi jego zmiana, bez czytania kodu linia po linii. Pisz dla kogos, kto zna projekt, ale nie zna kazdej funkcji.

## 1. Zbierz zmiane

Argument (opcjonalny): commit, zakres, branch albo numer PR. Bez argumentu, po kolei:
1. `git diff main...HEAD` (zmiany na branchu),
2. jesli puste: `git diff HEAD` (niezacommitowane),
3. jesli puste: `git show HEAD` (ostatni commit).

Do tego `git diff --stat`. Dla kazdej zmienionej funkcji otworz jej definicje i 1-2 miejsca, ktore ja wywoluja (`grep`). Diff bez kontekstu wywolan nie mowi, co kod robi.

## 2. Zasady tresci

- Kazde twierdzenie z kodu przeczytanego w tej sesji, z `plik:linia`. Domysly oznacz `[wniosek]`.
- Jezyk prosty: "zapisuje zamowienie do bazy", nie "persystuje encje". Termin techniczny tylko gdy konieczny, wtedy trafia do slowniczka.
- Opisuj zachowanie (co sie dzieje, gdy user kliknie / przyjdzie request / odpali sie cron), nie skladnie.
- Trudny mechanizm: jedna analogia z zycia, nie wiecej.
- Proza przechodzi `no-ai-slop` i `polszczyzna`.

## 3. Forma

**Maly diff (< ~50 linii, 1-2 pliki):** odpowiedz w czacie: zdanie podsumowania, przeplyw jako strzalki tekstowe (`klik "Zapisz" -> saveOrder() -> walidacja -> INSERT orders`), sekcje 3-6 ponizej w skrocie.

**Wiekszy diff:** strona Artifact (najpierw zaladuj `artifact-design` i `artifact-diagramming`). Sekcje w tej kolejnosci:

1. **Jednym zdaniem** — co ta zmiana daje uzytkownikowi koncowemu albo systemowi.
2. **Diagram przeplywu** — skad startuje (akcja usera, request, cron), przez jakie funkcje/pliki idzie, gdzie konczy (baza, ekran, API). Nowe elementy na zielono, zmienione na zolto, usuniete przekreslone. Maks ~10 wezlow; wiecej = podziel na 2 diagramy.
3. **Plik po pliku** — tabela: plik | wczesniej | teraz | po co. Jedno zdanie na komorke.
4. **Slowniczek** — terminy uzyte wyzej, po jednym zdaniu.
5. **Co moze sie zepsuc** — 1-3 konkretne scenariusze ("jesli koszyk jest pusty, X zwroci null"), tylko te widoczne w kodzie.
6. **Przeczytaj sam** — 2-3 miejsca `plik:linia`, ktore warto zrozumiec na wlasne oczy, z powodem.

Na koniec w czacie: link do strony i jedno zdanie podsumowania. Bez powtarzania tresci strony.
