#!/usr/bin/env bash
# Sends a repository_dispatch "upstream-issue" to the project that opened an issue (the upstream-request marker in
# its body, skill standard:upstream-issue), so its upstream-sync.yml reads the answer. That workflow decides by itself
# whether there is anything new, so an extra notice costs nothing. Usage: notify-consumer.sh <issue number>.
# Needs GH_TOKEN (reads the issue) and CROSS_REPO_TOKEN (writes to the project).
set -euo pipefail

issue="${1:?issue number missing}"
consumer=$(gh issue view "$issue" --json body --jq .body |
    grep -oE '<!-- upstream-request consumer=[A-Za-z0-9_.-]+/[A-Za-z0-9_.-]+ ' | head -n1 |
    sed -E 's/.*consumer=([^ ]+) /\1/' || true)
if [ -z "$consumer" ] || [ -z "${CROSS_REPO_TOKEN:-}" ]; then
    echo "No project to notify."
    exit 0
fi
GH_TOKEN="$CROSS_REPO_TOKEN" gh api "repos/$consumer/dispatches" -f event_type=upstream-issue \
    -f "client_payload[repo]=$GITHUB_REPOSITORY" -F "client_payload[issue]=$issue"
echo "Notified $consumer."
