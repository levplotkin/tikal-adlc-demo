#!/bin/bash
# Post-start script for ADLC Agentic Development Environment.
# Runs on every container start.

set -e

echo "🚀 Starting ADLC Agentic Development Environment..."

WORKSPACE_DIR="${PWD:-$HOME}"

# Re-run ADLC provisioning idempotently (fast when already installed).
if command -v setup-adlc.sh >/dev/null 2>&1; then
    PROJECT_DIR="$WORKSPACE_DIR" setup-adlc.sh >/dev/null 2>&1 || true
fi

# Display status
echo ""
echo "📊 Environment Status:"
echo "  Workspace: ${WORKSPACE_DIR}"
echo "  Python: $(python3 --version 2>/dev/null || echo 'not available')"
echo "  Node: $(node --version 2>/dev/null || echo 'not available')"
echo "  ADLC CLI: $(command -v adlc-skills-cli &> /dev/null && echo 'installed' || echo 'not installed')"
echo ""

echo "🎯 Available ADLC Commands:"
echo "  /team-boot          - Bootstrap session with team context"
echo "  /team-discover      - Discover relevant context"
echo "  /mission-brief      - Start a new mission"
echo "  /product-specify    - Create product requirements"
echo "  /architect-specify  - Create architecture decisions"
echo "  /evals-init         - Initialize evaluations"
echo "  /levelup-specify    - Extract learnings as CDRs"
echo ""

# The session_start event hook (wired by setup-adlc.sh) injects team context
# automatically when an agent session starts; no manual run is needed here.

echo "✅ Environment ready!"