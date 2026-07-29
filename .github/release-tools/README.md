# Release tooling

`semantic-release` and its plugins live here instead of the root `devDependencies`.

## Why

`@semantic-release/npm` depends on the `npm` CLI package, which ships its
dependencies as `bundleDependencies`. Two of them currently carry open
advisories:

| Package | Bundled | Advisory | Fixed in |
| --- | --- | --- | --- |
| `brace-expansion` | 5.0.7 | [GHSA-mh99-v99m-4gvg](https://github.com/advisories/GHSA-mh99-v99m-4gvg) (high) | 5.0.8 |
| `tar` | 7.5.19 | [GHSA-r292-9mhp-454m](https://github.com/advisories/GHSA-r292-9mhp-454m) (moderate) | 7.5.21 |

There is no way to fix them in place:

- `overrides` do not apply to `bundleDependencies` — npm restores them from the
  tarball, so the resolved versions are unchanged.
- No `npm` release satisfying `@semantic-release/npm@13`'s `npm@^11.6.2` range
  bundles the patched versions; `npm@12.0.1` still bundles 5.0.7 and 7.5.19.
- `npm audit fix --force` downgrades to `@semantic-release/npm@12.0.2`
  (`npm@10.9.9`), which trades these 5 advisories for 19 others.

Keeping the tooling out of the root tree lets `npm audit --audit-level=high`
in `ci.yml` gate the actual project dependencies without being permanently red
on an unfixable CI-only chain.

## How it works

`release.yml` installs this directory with `npm ci --prefix
.github/release-tools`, then runs `npx --prefix .github/release-tools
semantic-release` **from the repository root**. semantic-release resolves the
released package from `process.cwd()`, so the root `package.json`,
`CHANGELOG.md` and the `@semantic-release/git` assets behave exactly as they did
when the tooling was a root `devDependency`. Plugins resolve from this
directory's `node_modules`.

Versions are pinned by `package-lock.json` here and updated by Dependabot — see
the `/.github/release-tools` entry in `.github/dependabot.yml`.

## Revisiting this

Once npm publishes an `11.x`/`12.x` release bundling `brace-expansion >= 5.0.8`
and `tar >= 7.5.21`, these packages can move back into the root
`devDependencies` and this directory can be deleted.
