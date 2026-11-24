# scripts/chrome-claude.sh

## fn
main -> uruchamia dedykowany Chrome (CDP 9333, profil ~/.chrome-claude), czeka na endpoint

## vars
const PORT=9333 -> zgodny z env.BU_CDP_URL w settings.json
profil: $HOME/.chrome-claude (macOS/Linux), $USERPROFILE\.chrome-claude (Windows)

## fx
- idempotentny: curl /json/version odpowiada -> "chrome-claude: dziala", exit 0
- macOS: open -na "Google Chrome" --args ...; Linux: google-chrome albo chromium (nohup, tlo)
- MINGW/MSYS/CYGWIN: /c/Program Files/Google/Chrome/Application/chrome.exe
- po starcie poll do ~10s; brak odpowiedzi -> exit 1
- NIGDY niczego nie ubija (glowny Chrome wlasciciela nietykalny)

## deps
< settings.json (env.BU_CDP_URL)
> scripts/browser-gate.sh, CLAUDE.global.md (wskazane jako naprawa polaczenia)
