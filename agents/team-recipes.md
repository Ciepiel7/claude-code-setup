---
name: team-recipes
version: 1.1.0
description: Predefined Agent Team compositions for common workflows. Use when asked for "full review", "pre-deploy check", "parallel debug", or "feature team". Requires CLAUDE_CODE_EXPERIMENTAL_AGENT_TEAMS=1.
tools: Read, Grep, Glob
model: haiku
---

# Agent Team Recipes

Predefined team compositions for common multi-agent workflows. Copy-paste these prompts to spawn a coordinated team.

## Prerequisites

Agent Teams must be enabled in `~/.claude/settings.json`:
```json
{
  "env": {
    "CLAUDE_CODE_EXPERIMENTAL_AGENT_TEAMS": "1"
  }
}
```

---

## Recipe 1: Full Review (3 teammates)

**When:** Before merging a PR or major branch.
**Uses:** `code-reviewer.md`, `security-auditor.md`, `dependency-auditor.md`

**Before Running:** Verify all 3 agent files exist in `~/.claude/agents/`.

```
Create an agent team to review the current branch changes.
Spawn 3 teammates working in parallel:
1. Code Reviewer — run the code-reviewer checklist (logic, quality, conventions)
2. Security Auditor — run OWASP Top 10 checks on changed files
3. Dependency Auditor — audit all project dependencies for CVEs

Each teammate should:
- Read CLAUDE.md for project context first
- Focus only on their specialization
- Report findings in their standard output format (CRITICAL/HIGH/MEDIUM/LOW)

When all finish, synthesize a single verdict: APPROVE, REQUEST CHANGES, or BLOCK.
```

---

## Recipe 2: Pre-Deploy Check (3 teammates)

**When:** Before deploying to production.
**Uses:** `test-runner.md`, `security-auditor.md`, `dependency-auditor.md`

**Before Running:** Verify all 3 agent files exist in `~/.claude/agents/`.

```
Create an agent team for pre-deploy verification.
Spawn 3 teammates:
1. Test Runner — detect and run all test suites, report pass/fail
2. Security Auditor — scan for OWASP Top 10 vulnerabilities
3. Dependency Auditor — check for known CVEs in dependencies

Each teammate works independently. When all finish, produce a deploy/no-deploy decision.
Block deploy if: any test fails, any CRITICAL/HIGH security finding, any CRITICAL CVE.
```

---

## Recipe 3: Debug Investigation (3-5 teammates)

**When:** A bug has multiple possible causes and you want parallel investigation.
**Uses:** `debug-assistant.md` (each teammate uses the same agent protocol)

**Before Running:** Verify `debug-assistant.md` exists in `~/.claude/agents/`.

```
Create an agent team to debug: [describe the bug].
Spawn 3 teammates, each investigating a different hypothesis:
1. Hypothesis A: [e.g., race condition in async handler]
2. Hypothesis B: [e.g., incorrect database query]
3. Hypothesis C: [e.g., stale cache from CDN]

Each teammate follows the 6-phase debug protocol:
- Gather evidence for/against their hypothesis
- Report confidence level (HIGH/MEDIUM/LOW) with evidence

After investigation, have teammates debate findings to converge on root cause.
```

---

## Recipe 4: New Feature (3 teammates)

**When:** Implementing a significant new feature across multiple layers.
**Uses:** No specific agent files — general-purpose teammates.

```
Create an agent team to implement [feature description].
Spawn 3 teammates:
1. Backend — handles data model, API endpoints, business logic
2. Frontend — handles UI components, state management, API integration
3. Tests — writes tests for both backend and frontend changes

Rules:
- Backend teammate completes API design first, shares contract with Frontend
- Frontend waits for API contract before implementing calls
- Tests teammate writes tests as features are completed
- No two teammates edit the same file
```

---

## Recipe 5: Documentation Sprint (2 teammates)

**When:** Multiple files need Doc-Index v4 documentation.
**Uses:** `doc-maintainer.md`

**Before Running:** Verify `doc-maintainer.md` exists in `~/.claude/agents/`.

```
Create an agent team for documentation.
Spawn 2 teammates:
1. Documenter A — document files in src/ directory
2. Documenter B — document files in lib/ directory

Each teammate:
- Read CLAUDE.md for Doc-Index v4 format
- Check which files >30 lines lack docs/<basename>.md
- Create missing documentation files
- Update CLAUDE.md Docs table

Do not overlap — each teammate owns their directory.
```

---

## Recipe 6: Migration Review (2 teammates)

**When:** Reviewing a database migration or major refactor.
**Uses:** `code-reviewer.md`, `security-auditor.md`

**Before Running:** Verify both agent files exist in `~/.claude/agents/`.

```
Create an agent team to review the migration.
Spawn 2 teammates:
1. Safety Reviewer — check for data loss risks, missing rollback, breaking changes
2. Performance Reviewer — check for slow queries, missing indexes, lock contention

Both read the migration files and report findings independently.
Synthesize into: SAFE TO RUN / NEEDS CHANGES / DANGEROUS.
```

---

## Recipe 7: TypeScript-to-Rust Port (3 teammates)

**When:** Porting a specific subsystem from TypeScript reference to Rust implementation (claw-code project).
**Uses:** `parity-tracker.md` for gap analysis, general-purpose teammates.

**Before Running:** Verify `parity-tracker.md` exists in `~/.claude/agents/`.

```
Create an agent team to port [subsystem] from TypeScript to Rust.
Spawn 3 teammates:
1. Analyst — reads src/reference_data/*.json, identifies the TS module surface and behavior contracts, delivers spec
2. Implementer — writes Rust implementation in rust/crates/<target-crate>/ following existing patterns
3. Tester — writes tests in rust/crates/<target-crate>/tests/ matching behavioral spec

Rules:
- Analyst delivers spec to Implementer BEFORE coding starts
- Implementer follows existing Rust crate patterns (see config.rs, hooks.rs for style)
- Tester writes tests matching behavioral spec, not implementation details
- All teammates read CLAUDE.md and PARITY.md first
- No two teammates edit the same file
- After completion, update PARITY.md with new status
```

---

## Recipe 8: Board — ocena sensu projektu lub ruchu (4 teammates)

**When:** User mowi "board", "board review", "czy to ma sens", "ocen pomysl" — przed startem projektu, duza decyzja architektoniczna, zakupem narzedzia, zmiana strategii.
**Uses:** `board-sceptyk.md`, `board-realista.md`, `board-analityk.md`, `board-strateg.md` (wszystkie sonnet, read-only).

**Before Running:** Opisz pomysl w 3-5 zdaniach: co, po co, dla kogo, jaki koszt (czas/pieniadze), jaki stack.

```
Create an agent team to evaluate: [pomysl w 3-5 zdaniach].
Spawn 4 teammates, each with its own agent definition:
1. board-sceptyk — czy to w ogole powinno istniec (YAGNI, realny problem, istniejace rozwiazania)
2. board-realista — wykonalnosc w tym stacku, zlozonosc, koszt utrzymania, ukryte pulapki
3. board-analityk — koszt vs korzysc, odbiorca, ROI czasu/pieniedzy, koszt alternatywny
4. board-strateg — ryzyka, prostsze drogi do tego samego celu, plan minimalny vs pelny, koszt wyjscia

Rules:
- Kazdy ocenia NIEZALEZNIE, bez czytania opinii pozostalych; read-only, zero edycji
- Kazdy konczy: werdykt (go / no-go / go-if) + pewnosc 1-5 + 3 najwazniejsze argumenty
- Lead syntezuje: jeden werdykt, top 3 ryzyka, plan minimalny na start, co musialoby byc prawda, zeby zmienic zdanie
- Bez pochlebstw: sceptyk i strateg maja wprost szukac powodow, by NIE robic
```

---

## Team Best Practices

- **Size:** 3-5 teammates works best. Larger teams increase token costs linearly.
- **Task granularity:** 5-6 tasks per teammate keeps everyone productive.
- **File ownership:** Never have two teammates edit the same file — assign file ownership.
- **Communication:** Use direct messages for coordination, broadcast sparingly.
- **Lead role:** The lead synthesizes results and makes final decisions.
- **Start with research:** Have teammates investigate before implementing.
- **Monitor:** Check in periodically — don't let teams run unattended too long.
