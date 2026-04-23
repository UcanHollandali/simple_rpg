# Archive Usage

`Docs/Archive/` is historical material, not active authority.

What stays here now:
- dated architecture reviews that still have historical value
- closed-green prompt-pack batches such as `Docs/Archive/Prompts/2026-04-23-closed-green-prompt-packs/`
- archive contents are intentionally sparse right now; if a dated review is archived later, read it as historical context only, not current repo truth

What was intentionally removed on `2026-04-12`:
- prompt dumps
- frozen checklists
- stale bridge/history ballast that duplicated active docs

Working rule:
- do not read this folder by default
- do not use it as fallback authority if active docs already answer the question
- open it only for explicit dated-review lookup

Search rule:
- root `.ignore` excludes `Docs/Archive/` from normal local search
- if archive context is genuinely needed, search it explicitly by path
