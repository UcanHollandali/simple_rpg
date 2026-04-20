# W0-01 — Recreate `Docs/Audit/2026-04-18-maintainability-audit.md`

- mode: Fast Lane, doc-only
- scope: create `Docs/Audit/2026-04-18-maintainability-audit.md` and nothing else
- do not touch: any code, any other doc, the patch-backlog file, the roadmap
- validation budget: `py -3 Tools/validate_architecture_guards.py`
- doc policy: reconstruct from the already-captured `MAINT-F1..MAINT-F9` references in `Docs/Audit/2026-04-18-patch-backlog.md`. Do not invent new findings.

## Goal

The patch backlog header at `Docs/Audit/2026-04-18-patch-backlog.md` says:
> `Docs/Audit/2026-04-18-maintainability-audit.md` is not present in the repo. The A6 findings below are reconstructed from the current-session maintainability scan notes, not from a checked-in audit artifact.

That makes every reference to `MAINT-F*` in the backlog dangling. B-1 asks to fix this.

## Task

1. Create `Docs/Audit/2026-04-18-maintainability-audit.md`.
2. Use the same structure and tone as the other five sibling files (`2026-04-18-application-audit.md`, `2026-04-18-architecture-audit.md`, `2026-04-18-runtimestate-audit.md`, `2026-04-18-scene-audit.md`, `2026-04-18-ui-audit.md`).
3. For each finding, use the exact ID `MAINT-F1` … `MAINT-F9` and pull the finding text from every place in `Docs/Audit/2026-04-18-patch-backlog.md` where that ID is cited (it appears in backlog items P-03, P-04, P-05, P-06, E-1, and others).
4. Keep the report-only tone. No action plan, no owner assignments — just the nine findings and a short one-paragraph method note at the top saying this was reconstructed on 2026-04-20 from the patch-backlog references.
5. Add a line at the top: `Status: reconstructed 2026-04-20 from backlog citations; not a fresh scan.`

## Non-goals

- Do not edit the patch backlog.
- Do not create new finding IDs.
- Do not change any code.

## Report format

- listed changes
- explicitly: no code changed
- the MAINT-F IDs now resolve
- `HANDOFF.md` still needs its "no Docs/Audit folder" line fixed (that is W0-02, not this item)
