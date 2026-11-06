# Skills & Guidelines

This project uses AI-assisted development. All coding guidelines are stored in `.skills/` organized by language:

```
.skills/
  typescript/
    code-style.md      — Control flow patterns, braces, return statements
    conventions.md     — TypeScript-specific conventions (no-any, explicit returns, imports)
```

**For any AI tool used in this project:**
1. Read the relevant `.skills/<language>/` files before generating code
2. Ensure all suggestions comply with the rules defined there
3. The ESLint configuration (`eslint.config.mjs`) enforces these rules

**Supported tools:**
- **Copilot**: reads `.github/copilot-instructions.md` (thin wrapper pointing to `.skills/`)
- **Cursor**: can use `.cursorrules` (if configured) or read `.skills/` directly
- **Claude / other AI**: read the relevant `.skills/<language>/` files directly

## Issue agent

This fork (`BlorisL/termun-core-ts`) holds the issues of the projects that use `@termun/core`. Every opened issue and
every new comment by a maintainer starts a Claude agent (`.github/workflows/issue-agent.yml`) that analyses the
request, implements it until the checks pass and opens a pull request to `termun/core-ts`;
`.github/workflows/upstream-release.yml` closes the issue once termun has released it. The procedure is
`.claude/skills/handle-issue/SKILL.md`.
