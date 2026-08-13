#!/bin/bash
# =============================================================================
# setup-adlc.sh — idempotent ADLC provisioning for a Coder workspace.
#
# Installs Tikal's agentic SDLC stack (adlc-skills-cli + adlc-team-skills) and
# wires event hooks + slash commands for every event-capable coding agent.
#
# Resolution order for the skills source (fallback chain):
#   1. Mounted/git-cloned submodule:  <repo>/adlc-team-skills  (tikal-adlc-demo style)
#   2. Sibling checkout:              $HOME/adlc-team-skills
#   3. GitHub shorthand:              tikalk/adlc-team-skills (network install)
#
# Safe to re-run: adlc-skills-cli add/upgrade are idempotent and marker-based.
# =============================================================================

set -euo pipefail

# ── Environment (overridable) ─────────────────────────────────────────────
PROJECT_DIR="${PROJECT_DIR:-$HOME}"
WORKSPACE_REPO="${WORKSPACE_REPO:-$HOME}"
ADLC_TEAM_SKILLS_REPO="${ADLC_TEAM_SKILLS_REPO:-tikalk/adlc-team-skills}"
ADLC_SKILLS_CLI_PIN="${ADLC_SKILLS_CLI_PIN:-0.8.0}"
TEAM_DIRECTIVES_REPO="${TEAM_DIRECTIVES_REPO:-https://github.com/tikalk/agentic-sdlc-team-ai-directives}"
EVENT_CAPABLE_AGENTS="${EVENT_CAPABLE_AGENTS:-opencode claude-code cursor github-copilot codex gemini-cli qwen-code devin tabnine-cli}"

# ── Helpers ────────────────────────────────────────────────────────────────
log()  { printf '\n\xE2\x96\xB8 %s\n' "$*"; }
say()  { printf '    %s\n' "$*"; }
warn() { printf '    \xE2\x9A\xA0 %s\n' "$*"; }

have() { command -v "$1" >/dev/null 2>&1; }

# ── 1. Ensure adlc-skills-cli ──────────────────────────────────────────────
log "Ensuring adlc-skills-cli"
if have adlc-skills-cli; then
    say "adlc-skills-cli already installed: $(adlc-skills-cli --version 2>/dev/null || echo latest)"
elif [ -n "$ADLC_SKILLS_CLI_PIN" ] && npm view "adlc-skills-cli@$ADLC_SKILLS_CLI_PIN" version >/dev/null 2>&1; then
    npm install -g "adlc-skills-cli@$ADLC_SKILLS_CLI_PIN"
else
    npm install -g adlc-skills-cli
fi

# ── 2. Resolve the adlc-team-skills source (submodule → sibling → GitHub) ──
log "Resolving adlc-team-skills source"
SKILLS_SOURCE=""
for candidate in \
    "$WORKSPACE_REPO/adlc-team-skills" \
    "$HOME/adlc-team-skills" \
    "$PROJECT_DIR/adlc-team-skills"; do
    if [ -d "$candidate/skills" ]; then
        SKILLS_SOURCE="$candidate"
        break
    fi
done
if [ -z "$SKILLS_SOURCE" ]; then
    SKILLS_SOURCE="$ADLC_TEAM_SKILLS_REPO"
    say "no local checkout found — will install from $SKILLS_SOURCE"
else
    say "using local checkout: $SKILLS_SOURCE"
fi

# ── 3. Run the install per agent (events for all 9 event-capable) ─────────
log "Installing ADLC skills + commands + events for agents"
cd "$PROJECT_DIR"

for agent in $EVENT_CAPABLE_AGENTS; do
    if adlc-skills-cli add "$SKILLS_SOURCE" -a "$agent" --yes >/tmp/adlc-add-"$agent".log 2>&1; then
        say "[$agent] skills + slash commands installed"
    else
        # Retry without events (e.g. agent hook file already user-managed).
        if adlc-skills-cli add "$SKILLS_SOURCE" -a "$agent" --no-events --yes >/tmp/adlc-add-"$agent"-noevents.log 2>&1; then
            warn "[$agent] installed, events skipped"
        else
            warn "[$agent] install FAILED — see /tmp/adlc-add-$agent*.log"
        fi
    fi
done

# ── 4. Team AI directives / init-options (agentic-container pattern) ───────
log "Wiring team AI directives"
INIT_OPTIONS="$PROJECT_DIR/.adlc/init-options.json"
mkdir -p "$PROJECT_DIR/.adlc"

if [ ! -d "$PROJECT_DIR/.team-ai-directives" ]; then
    git clone --depth 1 "$TEAM_DIRECTIVES_REPO" "$PROJECT_DIR/.team-ai-directives" 2>/dev/null \
        && say "cloned team directives -> .team-ai-directives" \
        || warn "could not clone team directives (offline?) — continuing"
fi

DIRECTIVES_PATH="$PROJECT_DIR/.team-ai-directives"
if [ -f "$DIRECTIVES_PATH/AGENTS.md" ] || [ -d "$DIRECTIVES_PATH/context_modules" ]; then
    cat > "$INIT_OPTIONS" <<EOF
{
  "team_ai_directives": "$DIRECTIVES_PATH",
  "skills_source": "$SKILLS_SOURCE",
  "installed_at": "$(date -u +%Y-%m-%dT%H:%M:%SZ)",
  "agents": [$(printf '"%s",' $EVENT_CAPABLE_AGENTS | sed 's/,$//')]
}
EOF
    say "wrote $INIT_OPTIONS"
fi

# ── 5. Status summary ──────────────────────────────────────────────────────
log "ADLC status"
if [ -f "$PROJECT_DIR/.events.json" ]; then
    say "event manifest: $PROJECT_DIR/.events.json"
fi
if [ -f "$PROJECT_DIR/.agents/dispatcher.mjs" ]; then
    say "dispatcher: .agents/dispatcher.mjs"
fi
for agent in $EVENT_CAPABLE_AGENTS; do
    case "$agent" in
        opencode)         cfg="$PROJECT_DIR/.opencode/plugin/adlc-skills-events.ts" ;;
        claude-code)      cfg="$PROJECT_DIR/.claude/settings.json" ;;
        cursor)           cfg="$PROJECT_DIR/.cursor/hooks.json" ;;
        github-copilot)   cfg="$PROJECT_DIR/.github/hooks/adlc-skills.json" ;;
        codex)            cfg="$PROJECT_DIR/.codex/config.toml" ;;
        gemini-cli)       cfg="$PROJECT_DIR/.gemini/settings.json" ;;
        qwen-code)        cfg="$PROJECT_DIR/.qwen/settings.json" ;;
        devin)            cfg="$PROJECT_DIR/.devin/hooks.v1.json" ;;
        tabnine-cli)      cfg="$PROJECT_DIR/.tabnine/agent/settings.json" ;;
    esac
    [ -f "$cfg" ] && say "[$agent] event config: $cfg"
done

log "ADLC provisioning complete."
say "Run '/team-boot' in any agent to load team context, or start a mission with '/mission-brief'."