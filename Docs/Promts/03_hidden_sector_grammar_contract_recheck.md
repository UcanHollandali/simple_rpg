# Prompt 03 - Hidden Sector Grammar Contract Recheck

Use this prompt after Prompt 02 names the baseline honestly.
This pack locks the invisible sector grammar before runtime/UI implementation continues.

Checked-in filename note:
- this pack lives at `Docs/Promts/03_hidden_sector_grammar_contract_recheck.md`

Read first:
- `AGENTS.md`
- `Docs/DOC_PRECEDENCE.md`
- `Docs/HANDOFF.md`
- `Docs/ROADMAP.md`
- `Docs/MAP_CONTRACT.md`
- `Docs/MAP_COMPOSER_V2_DESIGN.md`
- Prompt 02 output

Archive handling:
- do not open archived prompts by default for this pass
- if a current-doc contradiction specifically requires archived context, open archive files explicitly and treat them as historical evidence only
- archived Prompt `47` / `47.5` wording must not override `Docs/MAP_CONTRACT.md`, `Docs/SOURCE_OF_TRUTH.md`, current code, or fresh captures

## Prompt 02 Correction Gate

Prompt 01 and Prompt 02 may already have been executed before the center-outward identity wording was tightened.
Do not rerun Prompt 02 only because its report mentions `lower-entry`, `lower/center-local entry`, or `upward exploration pressure`.

Apply this correction before Part A:
- Prompt 02 validation/capture evidence remains valid if it named the visible failures honestly.
- `lower-entry/upward exploration pressure` is stale target wording, not the active map goal.
- Restate that blocker as: `center-local start + north/south/east/west outward route read is not yet proven`.
- Keep all other Prompt 02 failures as live baseline evidence:
  - dark blob / abstract filler
  - stroke/decal road read
  - icon/plate-first nodes
  - weak place/pocket identity
  - weak hunger route-pressure
  - dashboard/framed-board feel
- If Prompt 02 lacks fresh screenshots or validation entirely, stop and run a narrow Prompt 02 recheck before continuing.

Preflight:
- touched owner layer: `Docs/MAP_CONTRACT.md + Docs/MAP_COMPOSER_V2_DESIGN.md only if wording drift exists`
- authority doc: `Docs/MAP_CONTRACT.md`
- impact: `runtime truth unchanged / save shape unchanged / asset-provenance unchanged`
- minimum validation set: `validate_architecture_guards + docs/path truth check + git diff --check`

## Goal

Make the invisible sector grammar implementation-ready without turning sectors into visible UI.
The contract must support:
- center-local start identity with seed/profile-varied outward route emphasis
- directional exploration pressure without a fixed upward ladder or edge-entry default
- readable north/south/east/west board direction
- north/south/east/west branch identity
- risk/safety route contrast
- local branch pockets and short reconnects
- full-board structural use, including north/south/east/west counterweight areas around the center-local opening

## Required Outcomes

- sector grammar remains hidden and non-gameplay-facing
- sectors define role, occupancy, anchor budget, and allowed corridor exits
- start anchor target remains center-local by default; deterministic orientation/emphasis profiles vary outward route shape rather than moving the start to an edge
- branch risk/safety semantics are directionally readable but not hardcoded as text labels
- structural metrics cover sector occupancy, first-choice spread, same-corridor conflict, orientation variance, and full-board usage
- no implementation is required unless docs are stale

## Hard Guardrails

- docs-only unless stale wording must be fixed
- no runtime generation change
- no UI drawing change
- no save/flow/source-of-truth change
- no candidate art

## Validation

- `py -3 Tools/validate_architecture_guards.py`
- docs/path truth consistency check
- `git diff --check`

## Done Criteria

- sector grammar is decision-complete for Prompt 04 and Prompt 05
- no contradiction with current owner boundaries
- archived prompt wording is not treated as authority

## Copy/Paste Parts

### Part A - Contract Audit

Apply only Prompt 03 Part A.

Scope:
- compare current sector contract against the target feel from Prompt 01 and failures from Prompt 02

Do not:
- patch runtime/UI code

Validation:
- Prompt 03 validation stack

Report:
- confirmed / inferred / unknown
- whether the Prompt 02 Correction Gate was applied cleanly or a narrow Prompt 02 recheck is required
- exact contract gaps, if any
- exact wording changes needed, if any

### Part B - Contract Patch

Apply only Prompt 03 Part B.

Scope:
- land only the narrow contract wording needed for implementation safety

Do not:
- add new gameplay owner or save shape

Validation:
- Prompt 03 validation stack

Report:
- files changed
- exact grammar/metric wording landed
- exact next implementation prompt now unblocked

### Part C - Recheck

Apply only Prompt 03 Part C.

Scope:
- verify the contract can guide runtime topology and UI placement without extra decisions

Do not:
- overfit sectors into a visible grid

Validation:
- Prompt 03 validation stack

Report:
- findings first
- whether Prompt 04 can start
- remaining deferred sector questions, if any
