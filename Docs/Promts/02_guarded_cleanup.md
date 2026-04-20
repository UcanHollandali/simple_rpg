# Prompt 02 - Guarded Cleanup

Use this prompt pack after `01_foundation_fastlane.md` is green.

Read first:
- `AGENTS.md`
- `Docs/DOC_PRECEDENCE.md`
- `Docs/HANDOFF.md`
- `Docs/ROADMAP.md`
- the closest authority doc for each touched slice

## Goal

Clear the remaining flow/application/scene drift without changing save shape, pending-node ownership, or gameplay authority boundaries.

## Current Facts This Prompt Owns

- `NodeResolve` still exists as a live legacy transition shell; its live generic fallback is an explicit legacy-compat path for now, and behavior-changing removal needs a dedicated flow audit.
- canonical pending-node owner is already decided: `MapRuntimeState`.
- the current `app_state.pending_node_id` / `app_state.pending_node_type` lane is a compatibility mirror for save/restore orchestration; guarded cleanup may document or isolate it, but must not widen or re-own it.
- `AppBootstrap` public-surface growth and new `/root/AppBootstrap` lookup spread are now validator-locked; guarded cleanup may reduce existing dependency edges but must not widen them.
- low-risk typed-reflection cleanup already landed in `map_explore_presenter`, `map_route_binding`, `support_interaction_presenter`, `support_interaction.gd`, `scene_router`, and `combat_resolver`; do not spend this prompt redoing already-closed reflection cleanup.
- Application invalid-state handling is still inconsistent across the main orchestration files.
- Scene theme/layout/audio duplication is reduced but not fully finished.
- Shared inventory-panel traversal hotspots still remain in `scenes/combat.gd` and `scenes/map_explore.gd`.
- Portrait density/theme/accessibility constants are still fragmented across the UI layer.
- `SceneRouter` already has overlay dictionaries, but scene-side overlay contract hardening is still unfinished.

## Order

1. Align the `NodeResolve` contract:
   - keep `NodeResolve` as a transition shell only
   - make the remaining live generic fallback explicit in docs/tests/guards instead of treating it as invisible
   - do not remove or change the live generic fallback behavior in this prompt pack; that is a separate explicit flow-audit decision
   - update the closest authority docs in the same patch
2. Standardize application invalid-state/error handling:
   - converge on one existing idiom
   - keep behavior identical on both happy and error paths
3. Keep the pending-node boundary explicit:
   - treat `MapRuntimeState` as the only owner of pending-node truth
   - treat `app_state.pending_node_id` / `app_state.pending_node_type` as compatibility mirrors only
   - if cleanup would change save shape, restore behavior, or owner meaning, stop and escalate first
4. Narrow bootstrap-surface drift where safe:
   - reduce raw lookup/helper duplication only when ownership stays unchanged
   - prefer typed existing surfaces over string-based reflection when the owner is already known
   - do not add new `AppBootstrap` public methods
   - do not treat `AppBootstrap` as the owner of pending-node, save, or map truth
5. Finish remaining scene shell cleanup:
   - route duplicate theme/layout/audio work through existing helpers
   - keep composition-only intent
6. Remove inventory-panel traversal hotspots:
   - prefer cached handles or a single outer traversal
   - do not widen runtime state to do this
7. Centralize portrait density/theme/accessibility constants:
   - one owner under `Game/UI/`
   - no value changes unless explicitly justified
8. Harden the overlay contract:
   - keep names stable
   - remove scene-side string choreography in favor of one typed/constant surface
9. Optional closeout:
   - compact UI accessibility polish if evidence shows a gap
   - tooling hygiene if the guarded work is already green

## Dead-Surface Rule

- If a surface is provably unused in live runtime/tests/content/assets/docs, delete it instead of keeping compatibility ballast around.
- If a surface still has live runtime, restore, validator, or test use, keep it and treat cleanup as behavior-sensitive.
- Do not remove live compat paths just because they look old; remove only dead residue, or stop and escalate when live behavior would change.

## Guardrails

- No save-schema shape change.
- No pending-node owner move.
- No widening or re-ownership of the pending-node compatibility mirror.
- No removal or behavior change of the live `NodeResolve` generic fallback without explicit escalate-first approval.
- No ownership move.
- No new gameplay autoload.
- No new command family or event family.
- No new `AppBootstrap` convenience method or lookup spread.
- Do not reintroduce string-based reflection where the owner is already typed and stable.
- Do not grow hotspot files past their guard caps.

## Validation

- `py -3 Tools/validate_architecture_guards.py`
- targeted Godot tests for flow, phase loops, scene slices, and inventory interactions as applicable
- `powershell -NoProfile -ExecutionPolicy Bypass -File Tools/run_godot_scene_isolation.ps1 -ScenePath scenes/map_explore.tscn`
- `powershell -NoProfile -ExecutionPolicy Bypass -File Tools/run_godot_scene_isolation.ps1 -ScenePath scenes/combat.tscn`
- `powershell -NoProfile -ExecutionPolicy Bypass -File Tools/run_godot_smoke.ps1` when boot/router wiring changes
- `powershell -NoProfile -ExecutionPolicy Bypass -File Tools/run_godot_full_suite.ps1`

## Done Criteria

- `NodeResolve` docs and code agree on its current live transition-shell/fallback role, or the pass stops with an explicit escalation item before behavior is changed.
- Guarded application/scene/UI drift is reduced without save or ownership churn.
- `AppBootstrap` dependency edges are not widened.
- Scene isolation, targeted tests, and full suite are green.
- The repo is ready for the extraction wave.
