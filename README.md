# claude-code-setup

My Claude Code configuration: subagents, hooks, skills and a per-project wiki. I use it every day across client projects, on Windows and macOS.

The main idea is cost and quality control. An expensive model plans and reviews, cheaper models do the reading and the typing, and hooks remind the session when it breaks its own rules.

> Instructions and docs are in Polish, because that's the language I work in. Agent definitions are mostly in English.

## What's inside

**Subagents** (`agents/`)

| Tier | Model | Agents |
|---|---|---|
| Recon | haiku | `scout` (reads the repo and returns `file:line — fact` instead of whole files), `test-runner`, `git-workflow`, `doc-maintainer`, `health-checker`, `dependency-auditor`, `project-detector` |
| Implementation | sonnet | `implementer` (writes code from a plan and returns done / not done / assumptions / verify), `code-reviewer`, `security-auditor`, `debug-assistant` |
| Project type | sonnet | `nextjs-helper`, `python-helper`, `wp-researcher`, `css-builder`, `crate-explorer`, `parity-tracker` |
| Board | sonnet | four agents that judge whether a project is worth doing: sceptic, realist, analyst, strategist |

**Hooks** (`scripts/`, registered in `settings.json`)

- `read-gate.sh`: after the third new file read in one task, reminds the session to delegate recon to `scout`.
- `write-gate.sh`: on the second file edited, reminds about the plan → implement → review loop.
- `agent-routing.sh`: logs which agent ran on which model and blocks Explore agents on the expensive model.
- `guard-destructive.sh`: blocks commands that kill the user's browser or wipe data.
- `guard-untrusted-repo.sh`: scans a GitHub repo with SkillSpector before it gets cloned or installed.
- `browser-gate.sh`: blocks browser MCP tools, so all browser work goes through one dedicated, headless Chrome profile (`chrome-claude.sh`).
- `answer-gate.sh`: when the user asks how code works, reminds the session to cite `file:line` it actually read.
- `doc-check.sh`: checks that edited source files have matching `docs/<file>.md`.
- `prune-worktree-sessions.sh`, `worktree-init.sh`: keep parallel sessions in separate git worktrees.

**Skills in this repo** (`skills/`)

| Skill | What it does |
|---|---|
| `polszczyzna` | Careful Polish for client-facing text: punctuation, typography („”, –), inflection, English calques, email etiquette. Comes with a self-check list and reference files. |
| `llm-wiki` | A per-project `wiki/` in the spirit of Karpathy's "LLM wiki": the agent reads it at the start of a session and updates it at the end, so knowledge builds up instead of being rediscovered. Browsable in Obsidian. |
| `explain-diff` | Explains your own diff in plain language: one-sentence summary, flow diagram, before/after per file, glossary and risks. |
| `video-claude` | Making videos in code with Remotion: brand assets, scenes as components, spring animation synced to audio, and a self-critique loop that watches the render. |

**Third-party skills I use** (listed in `skills.txt`, installed from their authors' repos, not copied here; `install.sh` tells you which ones you're missing)

| Area | Skills |
|---|---|
| Writing | `humanizer` (Claude Code plugin), `no-ai-slop` ([petergyang/no-ai-slop](https://github.com/petergyang/no-ai-slop)) |
| Browser and tooling | `browser-harness` ([browser-use/browser-harness](https://github.com/browser-use/browser-harness)), `find-skills` ([vercel-labs/skills](https://github.com/vercel-labs/skills)) |
| Frontend and design | `web-design-guidelines` ([vercel-labs/agent-skills](https://github.com/vercel-labs/agent-skills)), `vercel-react-best-practices` ([vercel-labs/agent-skills](https://github.com/vercel-labs/agent-skills)), `nextjs16-skills` ([gocallum/nextjs16-agent-skills](https://github.com/gocallum/nextjs16-agent-skills)), `authjs-skills` ([gocallum/nextjs16-agent-skills](https://github.com/gocallum/nextjs16-agent-skills)), `awwwards-animations` ([devmartinese/awwwards-animations-skill](https://github.com/devmartinese/awwwards-animations-skill)), `gsap-master` ([su69ar/rdnax-gsap-master](https://github.com/su69ar/rdnax-gsap-master)), `threejs` ([mrgoonie/claudekit-skills](https://github.com/mrgoonie/claudekit-skills)), `accessibility-a11y` ([mindrally/skills](https://github.com/mindrally/skills)), `performance` ([addyosmani/web-quality-skills](https://github.com/addyosmani/web-quality-skills)) |
| Databases | `postgres-drizzle` ([ccheney/robust-skills](https://github.com/ccheney/robust-skills)), `drizzle-orm` ([constructive-io/constructive-skills](https://github.com/constructive-io/constructive-skills)), `mysql` ([planetscale/database-skills](https://github.com/planetscale/database-skills)) |
| PHP and WordPress | `php-pro` ([jeffallan/claude-skills](https://github.com/jeffallan/claude-skills)), `php-best-practices` ([asyrafhussin/agent-skills](https://github.com/asyrafhussin/agent-skills)), `phpunit-best-practices` ([pentiminax/phpunit-best-practices](https://github.com/pentiminax/phpunit-best-practices)), `woocommerce` ([mindrally/skills](https://github.com/mindrally/skills)), `wordpress-security-validation` ([bobmatnyc/claude-mpm-skills](https://github.com/bobmatnyc/claude-mpm-skills)) |
| Python | `python-performance-optimization` ([wshobson/agents](https://github.com/wshobson/agents)) |
| Security | `security-review` ([getsentry/skills](https://github.com/getsentry/skills)) |
| SEO | `seo` ([addyosmani/web-quality-skills](https://github.com/addyosmani/web-quality-skills)), `seo-audit` ([seo-skills/seo-audit-skill](https://github.com/seo-skills/seo-audit-skill)), `ecommerce-seo-audit` ([affilino/ecommerce-seo-audit-skill](https://github.com/affilino/ecommerce-seo-audit-skill)) |
| Payments | `stripe` ([mindrally/skills](https://github.com/mindrally/skills)), `upgrade-stripe` ([stripe/ai](https://github.com/stripe/ai)) |

**Templates:** `project-template/` (project `CLAUDE.md` and settings) and `wiki-template/`.

## Install

```bash
git clone https://github.com/Ciepiel7/claude-code-setup.git ~/claude-code-setup
cd ~/claude-code-setup
bash install.sh --check     # see what would change in ~/.claude
bash install.sh             # universal agents, hooks, skills
bash install.sh --type=python   # or nextjs, wordpress, rust
```

`install.sh` skips files you already have unless you pass `--update`, and merges `settings.json` without dropping your own keys. `CLAUDE.global.md` becomes `~/.claude/CLAUDE.md`, so read it first: it contains my working rules and you'll want to change some of them.

Other options: `--init-project`, `--list`, `--diff`, `--validate`, `--health`. Run `bash install.sh --help`.

## License

MIT
