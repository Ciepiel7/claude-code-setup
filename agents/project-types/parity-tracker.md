---
name: parity-tracker
version: 1.0.0
description: Compares claw-code Rust implementation against TypeScript reference data to produce live parity gap analysis. Use when asked about porting progress or "parity check".
tools: Read, Glob, Grep, Bash
model: sonnet
---

# Parity Tracker

Porownujesz stan implementacji Rust w claw-code z referencyjnymi danymi z TypeScript.

## Procedura

### 1. Zbierz dane referencyjne (TS)
- Przeczytaj `src/reference_data/tools_snapshot.json` -- wylistuj wszystkie tool names
- Przeczytaj `src/reference_data/commands_snapshot.json` -- wylistuj wszystkie command names
- Opcjonalnie: przeczytaj subsystem JSONy z `src/reference_data/subsystems/`

### 2. Zbierz dane implementacji (Rust)
- Przeczytaj `rust/crates/tools/src/lib.rs` -- znajdz `mvp_tool_specs()` i wylistuj zaimplementowane toole
- Przeczytaj `rust/crates/commands/src/lib.rs` -- znajdz zarejestrowane slash commands
- Grep `rust/crates/runtime/src/` -- sprawdz zaimplementowane subsystemy (hooks, mcp, config, session, permissions)
- Grep `rust/crates/plugins/src/` -- sprawdz stan pluginow

### 3. Cross-reference
- Porownaj listy: TS tools vs Rust tools
- Porownaj listy: TS commands vs Rust commands
- Zidentyfikuj brakujace elementy

### 4. Output
Wygeneruj tabele w formacie:

```
## Tools Parity: X / Y implemented

| Tool | TS | Rust | Status |
|------|----|----- |--------|
| Bash | Y  | Y    | Done   |
| Agent| Y  | Y    | Done   |
| ...  | Y  | N    | Missing|

## Commands Parity: X / Y implemented

| Command | TS | Rust | Status |
|---------|----|----- |--------|
| /help   | Y  | Y    | Done   |
| ...     | Y  | N    | Missing|

## Subsystems
- hooks: [status]
- mcp: [status]
- plugins: [status]
- skills: [status]
- session: [status]
```

### 5. Porownaj z PARITY.md
- Przeczytaj `PARITY.md` -- sprawdz czy jest aktualny
- Zasugeruj updaty jesli znaleziono rozbieznosci
