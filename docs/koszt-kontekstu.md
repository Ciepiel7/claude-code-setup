# Koszt kontekstu — dlaczego bramka czytania stoi tak nisko

Uzasadnienie liczbowe dla sekcji `## Model Routing` w CLAUDE.md. Zmierzone na
wlasnych transkryptach Claude Code. Pomiar nie kosztowal ani jednego wywolania modelu — `usage` per
wiadomosc lezy juz w `~/.claude/projects/**/*.jsonl`.

## Na co ida pieniadze
| Skladnik | Udzial |
|---|---|
| odczyt cache | **61%** |
| zapis cache | 28% |
| output | 11% |
| wejscie niecache | 0% |

**89% rachunku to cache, nie pisanie.** Placi sie za to, ile agent NIESIE w kontekscie
przez kazda ture, a nie za to, ile generuje.

## Wzmocnienie kontekstu
Z proporcji zapisow i odczytow cache wychodzi, ze **kazdy token wchodzacy do
kontekstu glownej sesji jest oplacany srednio ~52 razy** (~5,3x ceny wejscia z samych
odczytow). Stad prog bramki czytania stoi na trzech plikach, a nie na trzydziestu.

Plik przeczytany przez sesje kosztuje ~52 odczyty na drogim modelu. Ten sam plik u scouta:
jeden odczyt na haiku. Dlatego wartosc scouta to **(co przeczytal − co zwrocil) × 52** —
oszczedza przez KOMPRESJE, nie przez tanszy model. Scout oddajacy 80% tego, co przeczytal,
nie oszczedza prawie nic; stad wymog `plik:linia — fakt` w `agents/scout.md` nie jest
kwestia stylu, tylko calym mechanizmem oplacalnosci.

## Dlugosc sesji
| Tur w sesji | Wzmocnienie |
|---|---|
| 0–50 | 10,2x |
| 50–150 | 28,3x |
| 150–400 | 38,4x |
| 400–1000 | 61,8x |
| 1000+ | **65,9x** |

Sesja powyzej 1000 tur placi 2,5x wiecej za ture. Koszt jest skoncentrowany: najdluzsze sesje
(ok. 10% wszystkich) to ponad polowa rachunku. To dzwignia niezalezna od tieru modelu.

## Ile realnie daje routing
Na pracy, ktora przez petle przechodzi, routing zbija koszt o **~65%**
w przykladowym projekcie. Ale petla obslugiwala tylko **13% wolumenu tokenow** w tym
projekcie i **2,6% globalnie**, wiec oszczednosc na CALYM rachunku wyniosla 11,5% i 1,3%.

> Wniosek, ktory musi przetrwac: "oszczedza 30% na rachunku" jest **nieprawda** — zly
> mianownik. "Na pracy przechodzacej przez petle zbija ~65%" jest zmierzone. Nie podawaj
> procentu bez podania, czego dotyczy.

## Co z tego wynika
1. Bramka petli ma mierzyc **ile musisz przeczytac**, nie ile zmieniasz. Dlatego bramki sa dwie.
2. "Pytanie bez edycji" to **najdrozszy** przypadek, nie najtanszy — nic nie piszesz, a
   wciagasz kilkanascie plikow i placisz je przez reszte sesji.
3. **Nie przenos implementacji na tansze modele dla oszczednosci.** Output to 11% rachunku —
   nawet darmowy dalby 11%, a gorszy kod = wiecej tur = wiecej cache = drozej. Tanie modele
   oplacaja sie na CZYTANIU, nie na pisaniu.
4. Regula bez egzekucji kosztuje: `Explore` mial chodzic tylko na haiku, przeszedl kilkadziesiat razy na
   najdrozszym modelu i kosztowal ponad trzykrotnosc calej oszczednosci
   z routingu w tamtym projekcie. Naprawil to dopiero hook, nie zdanie w pliku.

## Pulapka metodyczna
Pierwszy przebieg analizy dal ODWROTNY wynik ("zero subagentow"), bo glob `*/*.jsonl` nie
siega transkryptow subagentow — te leza o poziom glebiej, w `<sesja>/subagents/`. Uratowala
to tylko sprzecznosc z `~/.claude/agent-routing.log`. Kontrola: ~187 plikow plasko vs ~300
rekurencyjnie.

## Sprawdzian
Skutecznosc zmiany: udzial subagentow w wolumenie ma rosnac powyzej 13%,
a wzmocnienie kontekstu spadac ponizej 52x.
