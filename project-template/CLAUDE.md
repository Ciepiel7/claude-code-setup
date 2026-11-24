# [PROJECT NAME]
# Example: Stock Bot

<!-- Replace all placeholders in brackets with your project-specific values -->

## Stack
# Example:
# - Language/Runtime: Python 3.12
# - Framework: APScheduler + FastAPI (admin endpoint)
# - Database: PostgreSQL 16 (via asyncpg)
# - Hosting: VPS — systemd service
# - Other: Redis (rate-limit cache), yfinance, pandas
- Language/Runtime: [e.g., PHP 8.2, Node 20, Python 3.12]
- Framework: [e.g., WordPress, Next.js, FastAPI]
- Database: [e.g., MySQL 8, PostgreSQL 16, SQLite]
- Hosting: [e.g., VPS, Vercel, Railway]
- Other: [e.g., Redis, S3, Docker]

## Deploy
# Example:
# - Production: vps.example.com — systemctl restart stock-bot
# - Staging: n/a
# - Deploy command: git pull && pip install -r requirements.txt && systemctl restart stock-bot
- Production: [URL or deploy command]
- Staging: [URL or deploy command]
- Deploy command: [e.g., `git push heroku main`, `vercel --prod`]

## Conventions
# Example:
# - Naming prefix: n/a (Python uses modules for namespacing)
# - Code style: Black + ruff, line length 100
# - Branch naming: feat/, fix/, chore/
# - Commit format: Conventional Commits (feat:, fix:, chore:)
- Naming prefix: [e.g., `myproject_` for PHP functions, `mp-` for CSS classes]
- Code style: [e.g., PSR-12, ESLint Airbnb, Black]
- Branch naming: [e.g., `feat/`, `fix/`, `chore/`]
- Commit format: [e.g., Conventional Commits, imperative]

## Commands
```bash
# Development
# Example: python -m uvicorn main:app --reload
[start command]

# Tests
# Example: pytest tests/ -v
[test command]

# Build
# Example: n/a (no build step for Python)
[build command]

# Lint/format
# Example: ruff check . && black --check .
[lint command]
```

## Structure
# Example:
# stock-bot/
# ├── src/
# │   ├── scheduler.py   — APScheduler jobs
# │   ├── strategy.py    — trading logic
# │   ├── data.py        — yfinance fetching
# │   └── db.py          — PostgreSQL queries
# ├── tests/
# ├── .env               — secrets (not committed)
# ├── .env.example       — template
# └── pyproject.toml
```
[paste key directories here]
```

## Sessions & git (multi-session Claude)
<!-- Global rules live in ~/.claude/CLAUDE.md (Izolacja sesji + Git i droga na produkcje).
     Fill in only project specifics; delete lines that don't apply. -->
- Worktree init: [`bash scripts/worktree-init.sh` if project has one, else `bash ~/.claude/scripts/worktree-init.sh`]
- Branch protection: [required check name, e.g. `lint-and-test`] <!-- set up day 1! -->
- Migrations naming: `YYYYMMDDHHMM_desc` <!-- timestamps, not sequence numbers -->
- Prod hardening checklist: see `docs/produkcja.md` in claude-code-setup
  <!-- day 1: protection + auto-delete branches + CI gate; before first user:
       DB dump before migrations, smoke test + auto-rollback in deploy,
       fatal-error alert, external uptime monitor, test payment keys on staging -->

## Docs

| Source file | Documentation |
|-------------|---------------|
| [file path] | docs/[basename].md |
