---
name: handle-issue
description: What applies in the BlorisL/termun-core-ts fork to the issue agent (workflow .github/workflows/issue-agent.yml, shared skill standard:issue-agent) — branching from termun/core-ts main, the checks to run (npm run style:dry, npm test, npm run build, npm run build:test), the coding rules in .skills/typescript/, the Conventional Commits PR title that semantic-release upstream turns into the version, opening the pull request to termun/core-ts instead of merging and releasing, the upstream-pr label and marker, and upstream-release.yml that closes the issue once termun has released. Use when working as the agent on an issue of the fork, when changing issue-agent.yml or upstream-release.yml, and before closing an issue as completed.
---

# A core-ts issue, from analysis to the upstream pull request

This skill adds to the shared `issue-agent` skill (copied on the runner to `.agent-standard/skills/issue-agent/`)
what applies only here. The coding rules are in `.skills/typescript/` (read them before writing code) and are
enforced by `eslint.config.mjs`.

**This repo is a fork.** `BlorisL/termun-core-ts` holds the issues and the agent; the library lives in `termun/core-ts`,
which merges and releases `@termun/core` on npm. So steps 5 and 6 of `issue-agent` (merge, release) are replaced by
the pull request upstream below: the agent never merges, never releases, never pushes to `main` of either repo.

## Templates

Issues follow `.github/ISSUE_TEMPLATE/`: `bug_report.md` and `feature_request.md`. Requests from our projects are
checked against those headings before they are opened; a hand-written issue may lack them, and then what is missing
to decide (version, use case, reproduction) is asked.

## Branch

The workflow adds the remote `upstream` (termun/core-ts) and fetches its `main`. The branch starts from there, not
from the fork's `main` (which also carries the fork-only workflows, which must not end up in the pull request):

```bash
git checkout -b issue/<n>-<slug> upstream/main
```

## Checks

`npm ci` is already done by the workflow (on the fork's `main`: after switching branch, run `npm ci` again if
`package-lock.json` differs). The same checks as `ci.yml` and the pull request template, all green:

```bash
npm run style:dry
npm test
npm run build
npm run build:test
```

A failing check is fixed at its root, never skipped or loosened. The pre-commit hook (lint-staged) also runs on the
runner; a rejected commit is fixed, never committed with `--no-verify`.

## The pull request upstream

semantic-release on termun decides the version from the commit messages (`.releaserc`): `feat` gives a minor,
`fix`, `perf`, `refactor` a patch, a `BREAKING CHANGE` a major (only with the yes on the issue). With a squash merge
the commit on `main` is the PR title, so **the PR title is the release**: `feat(menu): add ...` or
`fix(input): ...`, never a free-form title.

```bash
git push origin issue/<n>-<slug>
GH_TOKEN="$CROSS_REPO_TOKEN" gh pr create -R termun/core-ts --base main --head BlorisL:issue/<n>-<slug> \
    --title "feat(...): ..." --body-file <file>
```

The body follows `.github/pull_request_template.md`, with the checks ticked and the link to the fork issue as a full
URL (`https://github.com/BlorisL/termun-core-ts/issues/<n>`): a `Closes #<n>` would point at a termun issue with that
number.

Then, on the fork issue:

1. a comment starting with `<!-- agent:provider upstream-pr=termun/core-ts#<pr number> -->` that says what changes,
   the pull request link, and a usage example that replaces the workaround described in the issue;
2. `gh issue edit <n> --add-label upstream-pr`; the issue stays **open**.

Review comments on the upstream pull request are not events of this repo: a maintainer who wants the agent to act
on them writes it in the fork issue, and the agent pushes the fix to the same branch.

## After the merge

`.github/workflows/upstream-release.yml` runs every 6 hours (and by hand). For every open issue with `upstream-pr`
it reads the pull request: merged and followed by a termun release, it comments
`<!-- agent:provider released=@termun/core@X.Y.Z -->`, closes the issue as completed and notifies the requesting
project; closed without merge, it hands the issue to a human with `needs-human`. The agent does none of this itself.
