#!/bin/bash
# agent-routing.sh — PreToolUse hook (matcher: Agent): bramka + log + raport.
# Loguje kazdy spawn subagenta: czas, projekt, agent, model, opis -> ~/.claude/agent-routing.log
# i pokazuje go inline w terminalu (systemMessage). `--report` = podsumowanie logu.
# Model: jawny `model:` w wywolaniu > frontmatter agenta (.claude/agents, ~/.claude/agents) > inherit.
# inherit = model sesji = frontier (Plan/general-purpose bez `model` to poprawne).
# Bramka: Explore bez modelu lub na frontier -> deny (rozpoznanie zawsze na haiku/sonnet, lepiej: agent scout).
# Efekt uboczny: spawn scout/Explore zeruje licznik bramki czytania (read-gate.sh) — nowe rozpoznanie = nowe zadanie.

LOG="$HOME/.claude/agent-routing.log"
PY=python3; command -v python3 >/dev/null 2>&1 || PY=python

if [ "$1" = "--report" ]; then
    [ -f "$LOG" ] || { echo "brak $LOG"; exit 0; }
    echo "== spawny per model (inherit = model sesji/frontier) =="; cut -f4 "$LOG" | sort | uniq -c | sort -rn
    echo "== spawny per agent =="; cut -f3 "$LOG" | sort | uniq -c | sort -rn
    echo "== ostatnie 20 =="; tail -n 20 "$LOG" | cut -f1,3,4,5
    exit 0
fi

HOOK_INPUT="$(cat || true)" LOG="$LOG" $PY - <<'PY' 2>/dev/null
import sys, json, os, re, time
try:
    d = json.loads(os.environ.get("HOOK_INPUT", ""))
except Exception:
    sys.exit(0)
if d.get("tool_name") != "Agent":
    sys.exit(0)
ti = d.get("tool_input", {})
agent = ti.get("subagent_type") or "general-purpose"
model = ti.get("model") or ""
src = "explicit"
if not model:
    for base in (os.path.join(d.get("cwd", ""), ".claude", "agents"), os.path.expanduser("~/.claude/agents")):
        p = os.path.join(base, agent + ".md")
        if os.path.isfile(p):
            m = re.search(r"^model:\s*(\S+)", open(p, encoding="utf-8", errors="ignore").read(), re.M)
            if m:
                model, src = m.group(1), "frontmatter"
                break
if not model:
    model, src = "inherit", "default"   # wbudowane (Plan/general-purpose) dziedzicza model sesji = frontier
if agent == "Explore" and model not in ("haiku", "sonnet"):
    print(json.dumps({"hookSpecificOutput": {"hookEventName": "PreToolUse", "permissionDecision": "deny",
        "permissionDecisionReason": f"routing: Explore na [{model}] zablokowany — podaj model: haiku (lub uzyj agenta scout)"}}))
    sys.exit(0)
desc = (ti.get("description") or "")[:80].replace("\t", " ").replace("\n", " ")
proj = os.path.basename(d.get("cwd", "") or "")
# Rozpoznanie ruszylo = nowe zadanie: zeruj licznik bramki czytania (read-gate.sh).
if agent in ("scout", "Explore"):
    sid = re.sub(r"[^A-Za-z0-9_-]", "", str(d.get("session_id") or "default")) or "default"
    try:
        os.remove(os.path.join(os.path.expanduser("~/.claude/.read-gate"), sid))
    except OSError:
        pass
with open(os.environ["LOG"], "a", encoding="utf-8") as f:
    f.write("\t".join([time.strftime("%Y-%m-%d %H:%M:%S"), proj, agent, model, desc, src]) + "\n")
print(json.dumps({"systemMessage": f"subagent {agent} [{model}] {desc}"}))
PY
exit 0
