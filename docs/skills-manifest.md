# scripts/skills-manifest.sh

## fn
main -> zapisuje skills.txt (root repo): <nazwa>\t<zrodlo>, posortowane, jedna linia na wpis ~/.claude/skills

## vars
const LOCK:path=~/.agents/.skill-lock.json -> .skills[name].source (python json, bez jq)
zrodlo: lock source | plugin:<sciezka> (symlink do ~/.claude/plugins) | repo (jest w skills/) | local

## fx
- wpisy z kropka na poczatku pomijane
- brak lock lub brak ~/.claude/skills: lock ignorowany / exit 1
- install.sh (zwykla instalacja) drukuje skille z skills.txt brakujace na maszynie: `npx skills add <zrodlo>`; nic nie instaluje

## deps
< ~/.agents/.skill-lock.json, ~/.claude/skills
> skills.txt, install.sh
