---
name: video-claude
description: >
  Use when making videos with Claude: motion graphics, YouTube intros/outros,
  overlays for talking-head footage, animated case studies, Shorts/Reels with
  burned-in captions, explainers. Covers the Remotion pipeline (React frame
  rendering -> headless Chromium -> ffmpeg), brand references, spring physics
  and audio sync, and the self-critique loop with /watch. Triggers: "film",
  "wideo", "animacja", "motion design", "intro", "YouTube", "short", "reel",
  "Remotion", "render MP4".
---

# Filmy z Claude (motion design przez kod)

Zrodlo metody: reel @raycfu „How to make a motion design studio with Claude” (10.2026).
Idea: nie generujesz klipu, tylko raz stawiasz STUDIO (repo), ktore renderuje kolejne filmy.

## 1. Silnik: Remotion, nie wlasny
- React rysuje kazda klatke z `useCurrentFrame()`, headless Chromium robi zrzut, ffmpeg skleja MP4. Wlasnej petli Playwright nie pisz.
- Start: `npx create-video@latest`, render: `npx remotion render <Composition> out/x.mp4`, podglad: `npx remotion studio`.
- Licencja: darmowa dla firm do 3 osob (sprawdz aktualne warunki na remotion.dev/license przed uzyciem komercyjnym).
- Jedno repo na marke (np. `brand-video`): `brand/`, `src/scenes/` (scena = komponent), `src/compositions/` (film = sekwencja scen), `public/` (audio, footage).

## 2. Referencje i prawdziwe assety (bez tego wychodzi AI-slop)
- `brand/`: logo SVG, fonty (pliki), paleta jako stale TS, screeny prawdziwych realizacji, 3-5 filmow-wzorcow ze stylem.
- `CLAUDE.md` repo wymienia wzorce i zakazy. Domyslnie ZAKAZANE: centered caps na fioletowym gradiencie, glow, generyczne „AI magic”, stockowe ikony zamiast prawdziwych UI.
- Kierunek domyslny: editorial, wyrownanie do lewej, prawdziwa typografia, prawdziwe screeny UI.

## 3. Ruch i dzwiek
- Kazda animacja przez `spring({frame, fps, config: {damping, stiffness}})`. Zakaz `transition: all .3s ease`, CSS animations i liniowego `interpolate` bez easingu dla ruchu obiektow.
- Zadna klatka nie stoi martwo dluzej niz ~1 s: zawsze cos sie porusza (dryf, parallax, mikro-skala).
- Audio w `<Audio>`, ciecia i wejscia elementow zablokowane na beat (beat grid w klatkach jako stala). SFX moga byc syntetyzowane w kodzie albo z `public/sfx/`.
- Napisy do Shorts: lokalny Whisper przez `@remotion/install-whisper-cpp` (bez klucza API), slowo po slowie.

## 4. Petla samokrytyki (najwazniejszy krok)
Po kazdym renderze:
1. `/watch out/x.mp4` z intencja „znajdz martwe klatki, ocen kazda scene 1-10 za ruch, timing do beatu, czytelnosc, zgodnosc z marka”.
2. Popraw sceny ponizej 8/10, wyrenderuj ponownie (mozna tylko fragment: `--frames=120-240`).
3. Powtarzaj, az kazda scena ma >= 8/10. Oceny i poprawki wpisuj do `wiki/` projektu.

## Czego Claude nie zrobi
- Nie nagra wlasciciela ani lektora: talking head i glos dostarcza czlowiek (albo TTS).
- Footage czlowieka: `<OffthreadVideo>` + overlaye w Remotion, albo eksport overlayow z alfa (`--codec=prores --prores-profile=4444`) do zewnetrznego montazu.

## Formaty
- YouTube 16:9: 1920x1080, 30 fps. Shorts/Reels 9:16: 1080x1920, 30 fps.
- Gotowe klocki do ponownego uzycia: intro/outro marki, lower thirds, plansze z liczbami, przewijany screen strony klienta.
