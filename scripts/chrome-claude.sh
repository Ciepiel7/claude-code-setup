#!/bin/bash
# chrome-claude.sh — uruchamia dedykowany profil Chrome dla automatyzacji (CDP port 9333, ~/.chrome-claude).
# Idempotentny: gdy endpoint juz odpowiada, nic nie robi. NIGDY niczego nie ubija — glowny Chrome wlasciciela jest nietykalny.

PORT=9333
URL="http://127.0.0.1:$PORT/json/version"

if curl -s --max-time 2 "$URL" >/dev/null 2>&1; then
    echo "chrome-claude: dziala"
    exit 0
fi

# Domyslnie headless: brak okna = brak kradziezy focusu, a karty nie sa "hidden" (bez throttlingu renderu).
# CHROME_CLAUDE_HEADED=1 -> okno (np. reczne logowanie), startowane w tle bez aktywacji.
MAC_BIN="/Applications/Google Chrome.app/Contents/MacOS/Google Chrome"

case "$(uname -s)" in
    Darwin)
        if [ "${CHROME_CLAUDE_HEADED:-0}" = "1" ]; then
            open -gna "Google Chrome" --args --user-data-dir="$HOME/.chrome-claude" --remote-debugging-port=$PORT --no-first-run \
                --disable-backgrounding-occluded-windows --disable-renderer-backgrounding --disable-background-timer-throttling
        else
            nohup "$MAC_BIN" --headless=new --user-data-dir="$HOME/.chrome-claude" --remote-debugging-port=$PORT --no-first-run \
                --window-size=1440,900 >/dev/null 2>&1 &
        fi
        ;;
    MINGW*|MSYS*|CYGWIN*)
        "/c/Program Files/Google/Chrome/Application/chrome.exe" --user-data-dir="$USERPROFILE\\.chrome-claude" --remote-debugging-port=$PORT --no-first-run >/dev/null 2>&1 &
        ;;
    *)
        CHROME=""
        for c in google-chrome chromium; do
            command -v "$c" >/dev/null 2>&1 && { CHROME="$c"; break; }
        done
        [ -n "$CHROME" ] || { echo "chrome-claude: nie znaleziono google-chrome ani chromium" >&2; exit 1; }
        nohup "$CHROME" --user-data-dir="$HOME/.chrome-claude" --remote-debugging-port=$PORT --no-first-run >/dev/null 2>&1 &
        ;;
esac

for _ in $(seq 1 20); do
    sleep 0.5
    if curl -s --max-time 2 "$URL" >/dev/null 2>&1; then
        echo "chrome-claude: uruchomiony (port $PORT)"
        exit 0
    fi
done
echo "chrome-claude: nie odpowiada na porcie $PORT po ~10s" >&2
exit 1
