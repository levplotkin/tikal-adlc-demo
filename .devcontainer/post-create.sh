#!/bin/bash
# Post-create script for ADLC Agentic Development Environment.
# Runs once after the devcontainer image is built inside the Coder workspace.

set -e

echo "🔧 Running post-create setup for ADLC Agentic Development..."
echo "Working dir: $(pwd)"

# setup-adlc.sh is baked into the image at /usr/local/bin.
# It resolves the skills source as: repo submodule → $HOME checkout → GitHub.
if command -v setup-adlc.sh >/dev/null 2>&1; then
    PROJECT_DIR="$(pwd)" setup-adlc.sh
else
    echo "⚠️  setup-adlc.sh not found in image; falling back to inline configure"
    mkdir -p .adlc/drafts/{cdr,pdr,adr,evals}
    mkdir -p context_modules/{constitution,personas,rules/{style-guides,framework,security,testing,devops,data},examples,skills}
    touch CDR.md
fi

echo "✅ Post-create setup complete!"
echo ""
echo "🎯 Next steps:"
echo "  1. Run 'team-boot' to bootstrap your session"
echo "  2. Run 'team-discover' to see available context"
echo "  3. Start a mission with 'mission-brief \"your feature\"'"