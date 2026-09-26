# Upstream SketchyBar docs (local mirror)

Verbatim markdown copies of the official documentation site
<https://felixkratz.github.io/SketchyBar/>, kept locally so pages can be read and
searched without re-fetching the website.

This is the *upstream* documentation. For how **this fork** is built, installed
and run on macOS, see [`../SETUP.md`](../SETUP.md).

## Provenance

The docs site is a Docusaurus build of the `documentation` branch of
[`FelixKratz/SketchyBar`](https://github.com/FelixKratz/SketchyBar) — not of
`master`. The files below were taken from that branch, unmodified.

| | |
| --- | --- |
| Source branch | `documentation` |
| Commit | `6ed777608bc981937a929126abe4d5fffcf74c52` |
| Branch commit date | 2025-11-02 |
| Fetched | 2026-09-25 |
| Files | 13 (952 lines, ~80 KB) |

Because it is the `documentation` branch, the content tracks the docs site, not
the released source tree. `setup.md` therefore describes the upstream
`brew install sketchybar` workflow, which this fork deliberately does not use.

## Contents

Navigation slugs come from each file's `id:` frontmatter; all links below were
verified as HTTP 200.

| File | Online page |
| --- | --- |
| `setup.md` | <https://felixkratz.github.io/SketchyBar/setup> |
| `features.md` | <https://felixkratz.github.io/SketchyBar/features> |
| `Credits.md` | <https://felixkratz.github.io/SketchyBar/credits> |
| `config/Bar.md` | <https://felixkratz.github.io/SketchyBar/config/bar> |
| `config/Items.md` | <https://felixkratz.github.io/SketchyBar/config/items> |
| `config/Components.md` | <https://felixkratz.github.io/SketchyBar/config/components> |
| `config/Types.md` | <https://felixkratz.github.io/SketchyBar/config/types> |
| `config/Events.md` | <https://felixkratz.github.io/SketchyBar/config/events> |
| `config/Animations.md` | <https://felixkratz.github.io/SketchyBar/config/animations> |
| `config/Popup.md` | <https://felixkratz.github.io/SketchyBar/config/popups> |
| `config/Querying.md` | <https://felixkratz.github.io/SketchyBar/config/querying> |
| `config/Reload.md` | <https://felixkratz.github.io/SketchyBar/config/reloading> |
| `config/Tricks.md` | <https://felixkratz.github.io/SketchyBar/config/tricks> |

Note the two files whose name differs from their slug: `Popup.md` → `popups`,
`Reload.md` → `reloading`.

## Known artifact

`config/Tricks.md` is the only MDX file in the set. Line 6 is
`import SketchExample from "../../src/pages/picker.js"` and line 71 renders
`<SketchExample />` — a live Docusaurus component that has no meaning outside
the site. Harmless to read or grep; it just will not render as a document.
Everything else is plain markdown (frontmatter plus GitHub-flavoured markdown).

## Refreshing

Re-pull the whole set from the `documentation` branch:

```bash
tmp=$(mktemp -d) &&
curl -sL "https://codeload.github.com/FelixKratz/SketchyBar/tar.gz/refs/heads/documentation" |
  tar xz -C "$tmp" --strip-components=1 "SketchyBar-documentation/docs" &&
cp -R "$tmp/docs/." docs/upstream/ &&
rm -rf "$tmp"
```

Then update the commit / date table above:

```bash
curl -s "https://api.github.com/repos/FelixKratz/SketchyBar/branches/documentation" |
  python3 -c "import json,sys; c=json.load(sys.stdin)['commit']; print(c['sha'], c['commit']['committer']['date'])"
```

## Git

`docs/` is untracked in this fork (it holds the fork-local `SETUP.md` as well).
Treat this mirror as local reference material — it is not intended to be
committed.
