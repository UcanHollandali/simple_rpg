# W0-06 — Remove the duplicate `MAP_RUNTIME_STATE_EXTRACTION_PLAN.md` under `Docs/Promts/`

- mode: Fast Lane, doc-only
- scope: delete `Docs/Promts/MAP_RUNTIME_STATE_EXTRACTION_PLAN.md`; confirm `Docs/MAP_RUNTIME_STATE_EXTRACTION_PLAN.md` is unchanged
- do not touch: any code, any other doc
- validation budget: `py -3 Tools/validate_architecture_guards.py`; grep the repo for the old path to confirm no in-repo link breaks
- doc policy: the extraction plan is authoritative under `Docs/` root, not under `Docs/Promts/`.

## Current state

Both paths exist with the same file name:
- `Docs/MAP_RUNTIME_STATE_EXTRACTION_PLAN.md`
- `Docs/Promts/MAP_RUNTIME_STATE_EXTRACTION_PLAN.md`

This duplicates authority for an extraction plan that is referenced by `Docs/Audit/2026-04-18-patch-backlog.md` item E-1.

## Task

1. Diff the two files to confirm the `Docs/Promts/` copy is the stale one (the `Docs/` root copy is the one cited by the patch backlog and `HANDOFF.md`).
2. If they differ in substance, surface the diff in your report and stop — do not delete.
3. If they are substantively identical, delete `Docs/Promts/MAP_RUNTIME_STATE_EXTRACTION_PLAN.md`.
4. Grep the repo for any remaining links to the deleted path and update them to point to the `Docs/` root copy.

## Non-goals

- Do not touch the content of the authoritative extraction plan.
- Do not promote the file elsewhere.
- Do not change any code.

## Report format

- diff summary
- deletion decision and path
- grep result for the old path: `0 remaining references`
- explicitly: no code changed
