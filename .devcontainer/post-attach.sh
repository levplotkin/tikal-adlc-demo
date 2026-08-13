#!/bin/bash
# Post-attach script for ADLC Agentic Development Environment.
# Runs when an IDE/agent attaches to the workspace.

set -e

echo "🔗 Attached to ADLC workspace"
if [ -f ".adlc/init-options.json" ]; then
    echo "📊 ADLC configured: $(jq -r '.team_ai_directives' .adlc/init-options.json 2>/dev/null)"
fi

# Show pending ADLC artifacts
for kind in cdr pdr adr; do
    if ls .adlc/drafts/$kind/*.md >/dev/null 2>&1; then
        echo "📝 Pending ${kind^^}:"
        ls .adlc/drafts/$kind/*.md 2>/dev/null | head -5 | xargs -I {} basename {} .md | sed 's/^/  - /'
    fi
done

echo ""
echo "💡 Tip: start a session and /team-boot will load team context automatically."