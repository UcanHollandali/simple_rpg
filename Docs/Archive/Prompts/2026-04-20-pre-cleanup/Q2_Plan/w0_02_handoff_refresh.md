# W0-02 — Refresh `Docs/HANDOFF.md`

- mode: Fast Lane, doc-only
- scope: `Docs/HANDOFF.md` only
- do not touch: any code, any other doc, any audit file
- validation budget: `py -3 Tools/validate_architecture_guards.py`
- doc policy: HANDOFF is rolling current-state; rewrite stale parts, do not append.

## Current drift to fix

1. `Last updated: 2026-04-18` → update to today's date.
2. The bullet near line 188 that says `there is still no Docs/Audit/ folder and no RuntimeState owner audit beyond the current report-only Docs/MAP_RUNTIME_STATE_EXTRACTION_PLAN.md` is false now: `Docs/Audit/` exists with six 2026-04-18 files (after W0-01 lands, seven). Rewrite the bullet to reflect reality — point to `Docs/Audit/` and the `Docs/Audit/2026-04-18-patch-backlog.md` as the current audit snapshot.
3. The validator hotspot list in `HANDOFF` should also mention (one line) that `HOTSPOT_FILE_LINE_LIMITS` in `Tools/validate_architecture_guards.py` now covers 14 files including `combat_flow.gd`, `inventory_actions.gd`, `inventory_state.gd`, `support_interaction_state.gd`, `combat_presenter.gd`, `inventory_presenter.gd`, `safe_menu_overlay.gd`. Do not list all 14; one sentence is enough.
4. Leave every other section of `HANDOFF.md` alone. This is a touch-up, not a rewrite.

## Non-goals

- Do not change authority meaning.
- Do not restate rules that already live in authority docs.
- Do not add new sections.

## Report format

- listed changes with line anchors
- explicitly: no code changed, no authority doc changed
