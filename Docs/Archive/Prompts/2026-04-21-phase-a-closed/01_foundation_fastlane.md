# Prompt 01 - Foundation Fast Lane

Use this prompt pack for the current `Phase A - Stabilization / Cleanup Closeout` pass.

Read first:
- `AGENTS.md`
- `Docs/DOC_PRECEDENCE.md`
- `Docs/HANDOFF.md`
- `Docs/ROADMAP.md`

## Goal

Close any remaining doc, guard, and authority-wording drift. If the current workspace is already clean, mark Prompt 01 green quickly and move to Prompt 02 instead of inventing filler work.

Continuation handoff rule:

- When Prompt 01 closes green, the next step is immediately `Docs/Promts/02_guarded_cleanup.md`.
- Do not reopen Prompt 01 for filler cleanup once the active docs and guards are already aligned.

## Current Facts This Prompt Owns

- the retired stage-1 boss surface is already validator-locked and should stay gone from live repo paths/content/tests/assets.
- command/event catalog drift is already closed for `turn_phase_resolved` and `BossPhaseChanged`.
- active markdown internal links already resolve.
- `README.md` and `Docs/TECH_BASELINE.md` already route `Docs/` through `Docs/DOC_PRECEDENCE.md` instead of presenting the whole folder as one flat authority surface.
- `scenes/` currently have zero direct `AppBootstrap.` member callsites; `AppBootstrap` public-surface growth and new `/root/AppBootstrap` lookup spread are already guard-locked, but narrowing existing uses is not part of this fast-lane prompt.
- canonical pending-node owner is already decided: `MapRuntimeState`.
- the current `app_state.pending_node_id` / `app_state.pending_node_type` lane is a compatibility mirror for save/restore orchestration, not a second owner.
- typed-owner reflection regressions are already guard-locked on:
  - `Game/UI/map_explore_presenter.gd`
  - `Game/UI/map_route_binding.gd`
  - `Game/UI/support_interaction_presenter.gd`
  - `scenes/support_interaction.gd`
  - `Game/Infrastructure/scene_router.gd`
  - `Game/Core/combat_resolver.gd`

## Order

1. Run the short sanity scan first:
   - re-check `HANDOFF.md`, `Docs/ROADMAP.md`, `Docs/TECH_BASELINE.md`, and `README.md` against the current measured workspace truth
   - re-check active markdown internal links
   - if the active docs and guards are already aligned, stop early, report Prompt 01 green, and move to Prompt 02
2. Align the active docs with current repo truth only where drift still exists:
   - refresh `HANDOFF.md`, `Docs/ROADMAP.md`, `Docs/TECH_BASELINE.md`, and `Docs/MAP_RUNTIME_STATE_EXTRACTION_PLAN.md` when their measurements or guard wording drift
   - keep `Docs/ROADMAP.md` as the only active roadmap/index
   - keep `Docs/MAP_RUNTIME_STATE_EXTRACTION_PLAN.md` authoritative only under `Docs/`
3. Codify the existing cleanup decisions in their owner docs:
   - `RunState` compatibility surface stays frozen
   - hamlet phase-split stays documented as intentional
   - `InventoryState` cached getter write-through stays a named exception
   - `zz_*` event-template IDs stay documented as intentional stable IDs
4. Finish the remaining fast-lane code/doc cleanup only if drift still exists:
   - patch the pending-node wording drift in `SAVE_SCHEMA.md` only if docs still misstate the locked owner-plus-compatibility-mirror split
   - keep `COMMAND_EVENT_CATALOG.md` aligned when new implemented signals/events land
   - keep `TECH_BASELINE.md`, `ARCHITECTURE.md`, and `TEST_STRATEGY.md` aligned with the real validator guard scope
   - keep active docs free of stale queue/history references
   - preserve the stale-wrapper removals and dead-alias cleanup already landed
   - preserve the shared inventory display-name helper path already landed
   - preserve the shared texture-loading path already landed
   - keep the architecture guard covering catalog drift, stale-wrapper regression, and the current typed-owner reflection regression locks
5. Keep the guard-locked retired surfaces closed:
   - do not reintroduce the old stage-1 retired boss definition/content/tests/asset rows outside explicit history docs
   - do not widen `AppBootstrap` with new public methods
   - do not add new `/root/AppBootstrap` lookup spread
   - keep stale queue/history references out of the active set
6. Apply the dead-surface rule:
   - if a surface is provably unused in live code/tests/content/assets/docs, delete it instead of parking it in the active set
   - if a surface still has live runtime, restore, validator, or test use, keep it and only document/guard it truthfully
   - do not keep dead compatibility ballast in active docs or code "just in case"

## Guardrails

- No save-schema shape change.
- No pending-node owner move.
- No `NodeResolve` behavior change.
- No new flow state.
- No new command family or event family.
- No new `RunState` compatibility accessor.
- No new `AppBootstrap` convenience method.
- No gameplay truth moves into UI.

## Validation

- `py -3 Tools/validate_architecture_guards.py`
- `py -3 Tools/validate_content.py` when content or manifest changes
- targeted Godot tests for the touched slice
- `powershell -NoProfile -ExecutionPolicy Bypass -File Tools/run_godot_full_suite.ps1` before closing the pass

## Done Criteria

- The active continuation queue / prompt surface remains limited to:
  - `Docs/ROADMAP.md`
  - `Docs/Promts/01_foundation_fastlane.md`
  - `Docs/Promts/02_guarded_cleanup.md`
  - `Docs/Promts/03_extraction_and_next_wave.md`
- Authority docs still come from `Docs/DOC_PRECEDENCE.md`; this prompt does not redefine the authority set.
- The active docs agree on the current hotspot measurements and explicit escalation items.
- The retired stage-1 boss surface stays gone from live repo surfaces.
- Catalog drift stays closed.
- Active markdown links and authority-routing wording stay clean.
- Fast-lane validator and full suite are green.
