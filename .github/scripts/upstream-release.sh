#!/usr/bin/env bash
# Closes the issues of this fork whose change is now released by termun/core-ts. The issue agent never merges nor
# releases: it opens a pull request upstream, labels the issue "upstream-pr" and writes the pull request in its
# comment marker (`<!-- agent:provider upstream-pr=termun/core-ts#<n> -->`). Here, for every such issue:
#   pull request still open        -> nothing yet;
#   closed without merge           -> say so, hand the issue to a human (needs-human);
#   merged, no release after it    -> nothing yet (semantic-release runs on termun's main);
#   merged and released            -> comment with the released= marker, close as completed.
# Then the requesting project is notified (notify-consumer.sh). Needs GH_TOKEN (this fork) and CROSS_REPO_TOKEN.
set -euo pipefail

upstream="termun/core-ts"
package=$(jq -r .name package.json)
here="$(dirname "$0")"

issues=$(gh issue list --state open --label upstream-pr --json number --jq '.[].number')
for issue in $issues; do
    pr=$(gh api --paginate "repos/$GITHUB_REPOSITORY/issues/$issue/comments?per_page=100" \
        --jq ".[].body | select(startswith(\"<!-- agent:provider\")) | capture(\"upstream-pr=$upstream#(?<n>[0-9]+)\").n" |
        tail -n1)
    if [ -z "$pr" ]; then
        echo "#$issue: no upstream-pr marker."
        continue
    fi
    state=$(GH_TOKEN="$CROSS_REPO_TOKEN" gh api "repos/$upstream/pulls/$pr" --jq '{state, merged_at, html_url}')
    url=$(jq -r .html_url <<<"$state")
    merged=$(jq -r '.merged_at // ""' <<<"$state")

    if [ "$(jq -r .state <<<"$state")" = open ]; then
        echo "#$issue: $url still open."
        continue
    fi

    if [ -z "$merged" ]; then
        gh issue comment "$issue" --body "<!-- agent:provider -->
The pull request $url was closed without being merged by $upstream. A human decides what to do next."
        gh issue edit "$issue" --add-label needs-human --remove-label upstream-pr
        bash "$here/notify-consumer.sh" "$issue"
        continue
    fi

    # The first stable release published after the merge is the one that carries the change.
    tag=$(GH_TOKEN="$CROSS_REPO_TOKEN" gh api --paginate "repos/$upstream/releases?per_page=100" --jq '.[]' |
        jq -rs --arg merged "$merged" '
            map(select(.draft | not) | select(.prerelease | not) | select(.published_at >= $merged))
            | sort_by(.published_at) | first | .tag_name // ""')
    if [ -z "$tag" ]; then
        echo "#$issue: $url merged, waiting for a release."
        continue
    fi
    version="${tag#v}"

    gh issue comment "$issue" --body "<!-- agent:provider released=$package@$version -->
Released in $package $version ($url merged upstream): \`npm install $package@$version\`."
    gh issue close "$issue" --reason completed
    gh issue edit "$issue" --remove-label upstream-pr
    bash "$here/notify-consumer.sh" "$issue"
done
