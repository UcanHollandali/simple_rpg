# SIMPLE RPG - Handoff

Last updated: 2026-04-17

This file is a current-state snapshot only.
It is not a rule contract. If it conflicts with an authority doc, the authority doc wins.

## Current State

- The repo is prototype-playable. Mobile-first responsive UI work is live across `MapExplore`, `Combat`, and the non-combat overlay family.
- Temporary prototype music floor is now the calmer `proto_01` set:
  - shared non-combat loop `music_ui_hub_loop_proto_01`
  - combat loop `music_combat_loop_proto_01`
  - run-end loop `music_run_end_loop_proto_01`
  - old `temp_01` music runtime files, source masters, and live references have been removed
  - objective music QC helper now exists at `py -3 Tools/analyze_music_floor_qc.py`
- Live runtime spine:
  - `Boot -> MainMenu -> MapExplore`
  - `MapExplore -> Combat | Event | Reward | SupportInteraction | RunEnd`
  - `Combat -> Reward -> LevelUp? -> MapExplore` on non-boss wins
  - `Combat -> StageTransition -> MapExplore` on stage `1-2` boss wins
  - `Combat -> RunEnd` on final boss or defeat
  - `NodeResolve` remains implemented as legacy transition-shell code, but it is no longer on the live map-to-interaction path
- Runtime ownership remains stable:
  - `MapRuntimeState` owns realized graph truth, node state, pending node context, key/boss-gate state, support revisit state, and hamlet side-quest state
  - `RunSessionCoordinator` owns movement resolution, roadside interruption continuation, and pending screen orchestration
  - `MapBoardComposerV2` derives graph-native board positions / trails / forest shapes from runtime truth plus seed; it does not write layout back into runtime state
  - `AppBootstrap` remains a facade over flow/run/save coordination; do not widen its gameplay-facing convenience surface without explicit escalation
- Current inventory baseline:
  - `InventoryState` now uses explicit `right_hand` / `left_hand` / `armor` / `belt` equipment slots plus backpack-only carried slots
  - equipped gear no longer consumes backpack capacity
  - belts are now authored backpack-utility items through `Belts.rules.backpack_capacity_bonus`
  - passive items stay active while carried in the backpack
  - quest cargo and detached shield mods now live as backpack item families
  - attached shield mods live on shield slot state and can be attached/detached outside combat
  - left-hand slot now supports live `shield` or offhand-capable `weapon` truth
- Current progression baseline:
  - XP and threshold leveling stay live through `RunState`
  - `LevelUp` now grants `CharacterPerks`, not inventory items
  - owned perks live in `CharacterPerkState`, serialized through `RunState`
  - passive items remain backpack-carried bonuses and are no longer the progression owner
- Current combat baseline:
  - top-level actions are `Attack`, `Defend`, `Use Item`
- the old temporary mitigation action is gone
  - `Defend` generates temporary `Guard`
  - remaining guard now decays at turn end instead of clearing outright; a small rounded remainder may carry into the next turn
  - damage order is now raw damage -> armor reduction -> guard absorption -> HP loss
  - left-hand shield boosts defend guard
  - left-hand offhand weapon grants a small dual-wield attack bonus and defend penalty
  - combat-time gear swaps and backpack reorder are no longer part of the canonical player-facing loop
- Current map/runtime baseline:
  - active procedural stage profiles realize `14`-node center-start controlled-scatter graphs
  - family placement is a separate post-topology step
  - start currently exposes one early combat, one early reward, and one early support route
  - hamlet request presentation/tests are aligned to the current runtime-backed `hamlet` node family while persistence remains under the legacy `side_mission_*` save/runtime helper surface
  - hamlet nodes now expose a stage-derived personality read without widening save payload:
    - stage `1` -> `pilgrim`
    - stage `2` -> `frontier`
    - stage `3` -> `trade`
  - hamlet requests now resolve from deterministic run-seeded stage-local authored pools:
    - stage `1`: `Hunt Marked Brigand`, `Clear the Watchpath`, or `Clear the Ridge Cut`
    - stage `2`: `Deliver Supplies`, `Carry the Forge Parcel`, or `Recover the Lantern Scout`
    - stage `3`: `Rescue Missing Scout`, `Recover the Bell Scout`, `Bring Proof`, or `Bring Proof from the Barricade`
  - stage-local hamlet request and payout selection now keeps a narrow personality bias inside those authored pools instead of flat uniform resolution
  - planned map `event` nodes are player-facing `Trail Event`
  - travel-triggered `Roadside Encounter` is a movement interruption that preserves destination resolution
  - current roadside tune now allows up to `3` movement-triggered encounters per stage and some roadside templates only join the eligible pool when the current run state matches their trigger condition
  - `scenes/map_explore.gd` consumes composer world positions first and keeps only an emergency route-slot fallback
- Current acquisition/content baseline:
  - rewards, authored events, and hamlet payouts now support narrow `grant_item` routing through `InventoryActions`
  - merchant stock now widens across consumable / weapon / shield / armor / belt / passive-item lanes without changing save or flow ownership, and live support openings now pick from deterministic run-seeded stage-local stock pools
  - live merchant breadth now spans `9` authored stock definitions across the three stage-local pools, including the new scout / forgegear / convoy variants
  - current merchant stage tuning is now tutorial/prep at stage `1`, build-opening at stage `2`, and stronger niche gear at stage `3`
  - ordinary rewards now use narrow stage gating and combat-enemy tone bias for `Field Provisions` / `Quick Refit` / `Scavenger's Find` windows without widening reward grammar or flow
  - shield attachments now stay concentrated in hamlet contract payout lanes instead of routine ordinary-reward traffic
  - first authored pack is live for new weapons, shields, belts, passive items, shield attachments, consumables, roadside/event finds, hamlet request rewards, alternate merchant stocks, and additional hamlet request definitions
  - the live event pool now carries `15` authored `Trail Event` templates, including `Watchfire Ruin Cache`, `Weathered Signal Tree`, `Woodsmoke Bunkhouse`, and `Woundvine Altar`
  - the roadside pool now carries `13` authored movement-interruption templates under the existing `EventTemplates + roadside tag` slice, including `Suspicious Merchant`, `Old Road Sign`, `Broken Bridge Crossing`, and `Silent Grave Mound`
  - planned event and roadside template selection now keeps deterministic run-seeded variation instead of surfacing the exact same template subset every run
  - non-boss enemy selection now keeps authored stage pools but applies a deterministic run-seeded stage offset so repeated runs do not always surface the same minor-enemy order
  - the live enemy pool now includes `Cutpurse Duelist`, `Thornwood Warder`, `Gatebreaker Brute`, `Carrion Runner`, and `Ashen Sapper`
  - stage boss breadth now covers all three stages through `Tollhouse Captain`, `Chain Herald`, and `Briar Sovereign`
  - stale pre-defend enemy authored copy has been scrubbed from active combat content
  - the pre-playtest balance pass has now tightened generic gold pressure and late-run attrition:
    - merchant price bands are slightly higher across all three stages, with the biggest increases on stage `2-3` gear
    - generic combat/reward-node gold rolls are slightly lower
    - active stage `2-3` enemy HP and the three live stage-boss HP floors are slightly higher
- Current UI baseline:
  - `event`, `reward`, `support_interaction`, and `level_up` render as overlays above `MapExplore`
  - `stage_transition` and `run_end` use the same run-status shell language but remain standalone screens
  - `combat` uses a height-budget layout plus the shared run-status/formatting foundation
  - resolution/fullscreen controls are no longer exposed in the live main menu or safe-menu overlay; current AppBootstrap window-preview lane has also dropped the old unused display getter residue and remains internal startup-only placeholder glue
  - map route travel now follows composed edge geometry, delays board catch-up slightly on departure, and adds restrained stride/arrival polish
  - the prototype map asset kit is now live on the board surface: trail decals, clearing decals, state plates, canopy clumps, the dedicated `Trail Event` icon, and the refreshed side-mission icon all render through presentation-only hooks with procedural fallback still in place
  - combat feedback now resolves on phase beats, keeps same-target feedback from overwriting itself, and gives action-hint / intent / button feedback a narrow motion pass
  - high-visibility runtime asset polish is now live on the current prototype slice:
    - refreshed map-node icon family for `start`, `rest`, `merchant`, `blacksmith`, `trail event`, `hamlet`, `combat`, and `reward`
    - refreshed route-board backdrop shell with stronger compass / guide-lane depth
    - refreshed walker idle / stride frames for clearer traversal readability at portrait targets
  - explicit mechanic and equipment icon lanes are now live for `Defend`, `shield`, `armor`, `belt`, `passive item`, `quest cargo`, and `shield mod`; those surfaces no longer reuse the old generic action, `settings`, `reward`, or `confirm` icons
- Current cleanup/audit baseline:
  - the remaining historical removed-action text in the repo is now limited to historical decision-log rows, deprecation notes, and a regression test assertion
  - the old pre-migration balance-analysis lane has been removed; use current contracts, targeted tests, and live playtests for balance claims
  - a reference-only current content inventory now lives at `Docs/CONTENT_BALANCE_TRACKER.md` so future balance passes do not have to reconstruct the full item/enemy/event surface from scattered contracts
- Current save baseline:
  - `save_schema_version = 8`
  - `content_version = prototype_content_v7`
  - save truth remains centered on `RunState`, `MapRuntimeState`, `InventoryState`, and the pending choice owners through `SaveRuntimeBridge`

## Last Verified Validation Checkpoint

These commands were last verified against the then-current checked-out repo snapshot.
Re-run them after new dirty-worktree changes before treating them as live proof for the current local state.

- Passed: `py -3 Tools/validate_content.py`
- Passed: `py -3 Tools/validate_assets.py`
- Passed: `py -3 Tools/validate_architecture_guards.py`
- Passed: `py -3 Tools/analyze_music_floor_qc.py`
- Passed: `powershell -NoProfile -ExecutionPolicy Bypass -File Tools/run_godot_full_suite.ps1`
- Passed: `powershell -NoProfile -ExecutionPolicy Bypass -File Tools/run_godot_smoke.ps1`
- Passed: `powershell -NoProfile -ExecutionPolicy Bypass -File Tools/run_godot_scene_isolation.ps1 -ScenePath scenes/main_menu.tscn`
- Passed: `powershell -NoProfile -ExecutionPolicy Bypass -File Tools/run_godot_scene_isolation.ps1 -ScenePath scenes/map_explore.tscn`
- Passed: `powershell -NoProfile -ExecutionPolicy Bypass -File Tools/run_godot_scene_isolation.ps1 -ScenePath scenes/combat.tscn`
- Passed: `powershell -NoProfile -ExecutionPolicy Bypass -File Tools/run_godot_scene_isolation.ps1 -ScenePath scenes/support_interaction.tscn`
- Passed: `powershell -NoProfile -ExecutionPolicy Bypass -File Tools/run_godot_scene_isolation.ps1 -ScenePath scenes/run_end.tscn`
- Passed: `powershell -NoProfile -ExecutionPolicy Bypass -File Tools/export_windows_playtest.ps1`
  - current machine now has the matching Godot `4.6.2` Windows export templates installed for local export/playtest runs
- Passed: `powershell -NoProfile -ExecutionPolicy Bypass -File Tools/run_portrait_review_capture.ps1`
  - current portrait-review capture lane writes screenshot sets under `export/portrait_review/`
  - default capture set now focuses on the always-meaningful playtest scenes (`main_menu`, `map_explore`, `combat`, `run_end`) instead of state-empty overlay shells
- Current repo truth: there is no dedicated image-diff regression harness yet; visual verification still needs human review, but portrait screenshot capture is no longer ad hoc.

## Open Risks

- Manual Godot visual verification is still needed for map readability, overlay feel, and combat height-budget behavior on portrait targets, but the repo now has a repeatable portrait screenshot capture lane for the key playtest scenes.
- Manual Godot listening/playtest is still needed for the new prototype music floor. Objective QC now covers loop-boundary continuity and high-frequency load, but fatigue, mix balance, and transition feel still need human ears.
- Motion/camera/combat polish is validated headlessly, but final feel signoff still depends on live Godot playtests for short-route vs long-route travel, roadside interruption continuation, defend/guard readability, low-HP recovery, and portrait viewport behavior.
- `NodeResolve` is still present as legacy code. Do not remove it without an explicit flow audit.
- Shield/offhand content is no longer a one-item lane; the current content pack now includes `5` shield definitions and `3` offhand-capable weapons, but live combat semantics over that wider authored surface are still intentionally narrow and still need manual feel checks.
- `AppBootstrap` and several other hotspot files remain large; extraction-first guardrails are now in place, but no owner-changing cleanup happened in the latest passes.
- the current architecture guard now also blocks silent line-count growth on the current extraction-first hotspot files (`map_runtime_state.gd`, `combat.gd`, `map_explore.gd`, `map_board_composer_v2.gd`, `inventory_actions.gd`, `save_service.gd`, `run_session_coordinator.gd`, `inventory_state.gd`, `support_interaction_state.gd`, `combat_presenter.gd`, `safe_menu_overlay.gd`, `combat_flow.gd`, `inventory_presenter.gd`) so future work has to extract or explicitly escalate instead of widening them by drift
- Windows export playtests no longer require a preinstalled local template copy if the machine can reach the official Godot `4.6.2` export-template archive during export helper setup.
  - fully offline machines still need a local matching template copy
- Current validated headless snapshot no longer leaves known shutdown-only `ObjectDB instances leaked at exit` / `resources still in use at exit` warnings in `_godot_profile/logs` after the explicit full-suite lane.
  - the runner now clears stale local logs before each pass and treats generic `SCRIPT ERROR:` rows as hidden failures
  - if future teardown/resource noise reappears, treat it as test-lane cleanup work first, not automatic gameplay/runtime drift

## Next Step

1. Manual playtest the map/combat polish pass:
   - listen to menu/map/combat/run-end transitions for fatigue and loop feel
   - verify short-route vs long-route map travel rhythm and board follow
   - visual playtest the map board and overlay screens at portrait targets (`1080x2400`, `1080x1920`, `720x1280`)
   - visual playtest a roadside interruption into a normal destination and confirm the destination still resolves after the roadside flow closes
   - visual playtest defend/guard turns, low-HP recovery turns, and action-hint hover timing in combat
2. If another machine needs local Windows export/playtest runs, allow `Tools/export_windows_playtest.ps1` to fetch the official `4.6.2` export templates or install the matching templates locally first for offline use.
3. If future headless teardown/resource warnings reappear, inspect the current `_godot_profile/logs/` snapshot first before assuming runtime drift.
