# W0-04 — Fix `SAVE_SCHEMA.md` pending-node ownership drift (P-01)

- mode: Fast Lane, doc-only
- scope: `Docs/SAVE_SCHEMA.md` only
- do not touch: any code, other authority docs, audit docs
- validation budget: `py -3 Tools/validate_architecture_guards.py`
- doc policy: do not move the topic; fix the ownership phrasing in place.

## Source

Patch backlog item **P-01** in `Docs/Audit/2026-04-18-patch-backlog.md`:
> Fix `SAVE_SCHEMA` pending-node ownership drift. Audit source: `RS-F1`.

The upstream finding ID is `RS-F1` in `Docs/Audit/2026-04-18-runtimestate-audit.md` — pending-node ownership is described in `SAVE_SCHEMA.md` in a way that disagrees with the actual owner.

## Task

1. Read `Docs/Audit/2026-04-18-runtimestate-audit.md` finding `RS-F1` to confirm the exact drift wording.
2. Fix the pending-node ownership section in `Docs/SAVE_SCHEMA.md` so that it names the current runtime owner (do not paraphrase ownership — mirror how `SOURCE_OF_TRUTH.md` names the owner).
3. Do not introduce a new owner. Do not shift ownership in code. Do not add a migration note unless `RS-F1` explicitly calls for one.

## Non-goals

- Do not change any save version.
- Do not change any code.
- Do not restructure `SAVE_SCHEMA.md` — this is a phrasing fix.

## Report format

- before/after quote of the section
- confirmation: `SOURCE_OF_TRUTH.md` owner name now matches the save schema sentence
- explicitly: no code changed, no version bumped
