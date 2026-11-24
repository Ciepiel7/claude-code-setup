// statusline: Model | Ctx Used | Cost | Projekt | Session
const fs = require('fs');
const path = require('path');
const { execSync } = require('child_process');

let d = {};
try { d = JSON.parse(fs.readFileSync(0, 'utf8')); } catch (e) {}

const c = (n, s) => `\x1b[${n}m${s}\x1b[0m`;

// ctx: ostatni assistant z usage w transkrypcie
let pct = '?';
try {
  const lines = fs.readFileSync(d.transcript_path, 'utf8').trim().split('\n');
  for (let i = lines.length - 1; i >= 0; i--) {
    const u = JSON.parse(lines[i])?.message?.usage;
    if (!u) continue;
    const used = (u.input_tokens || 0) + (u.cache_read_input_tokens || 0) + (u.cache_creation_input_tokens || 0);
    const limit = /\[1m\]|-1m/.test(d.model?.id || '') ? 1000000 : 200000;
    pct = (used / limit * 100).toFixed(1) + '%';
    break;
  }
} catch (e) {}

// projekt: zawsze glowne repo, nigdy nazwa worktree (git-common-dir wskazuje .git maina)
const dir = d.workspace?.project_dir || d.cwd || process.cwd();
let proj = path.basename(dir);
try {
  const g = execSync('git rev-parse --path-format=absolute --git-common-dir', {
    cwd: dir, encoding: 'utf8', stdio: ['ignore', 'pipe', 'ignore'],
  }).trim();
  if (g) proj = path.basename(path.dirname(g));
} catch (e) {}

const min = Math.floor((d.cost?.total_duration_ms || 0) / 60000);
const dur = min >= 60 ? `${Math.floor(min / 60)}hr ${min % 60}m` : `${min}m`;
const cost = '$' + (d.cost?.total_cost_usd || 0).toFixed(2);
const sep = c(90, ' | ');

process.stdout.write(
  c(36, 'Model: ' + (d.model?.display_name || '?')) + sep +
  c(90, 'Ctx Used: ' + pct) + sep +
  c(35, 'Cost: ' + cost) + sep +
  c(32, 'Projekt: ' + proj) + sep +
  c(33, 'Session: ' + dur)
);
