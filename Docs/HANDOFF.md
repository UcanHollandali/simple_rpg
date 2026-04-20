# SIMPLE RPG - Handoff

Last updated: 2026-04-20

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
  - `NodeResolve` remains implemented as legacy transition-shell code; current runtime-backed node families bypass it on the normal path, but generic fallback and legacy-compatible pending-node restore can still route into it
- Runtime ownership remains stable:
  - `MapRuntimeState` owns realized graph truth, node state, pending node context, key/boss-gate state, support revisit state, and hamlet side-quest state
  - `RunSessionCoordinator` owns movement resolution, roadside interruption continuation, and pending screen orchestration
  - `MapBoardComposerV2` derives graph-native board positions / trails / forest shapes from runtime truth plus seed; it does not write layout back into runtime state
  - `AppBootstrap` remains a facade over flow/run/save coordination; do not widen its gameplay-facing convenience surface without explicit escalation
  - pending-node save continuity is still a compatibility-sensitive split:
    - `RunSessionCoordinator` writes/restores the current save-facing `app_state` pending-node fields
    - `MapRuntimeState` remains the runtime owner that consumes/loads the effective pending-node context
  - no owner split has happened for `MapRuntimeState`; a planning-only extraction report now lives at `Docs/MAP_RUNTIME_STATE_EXTRACTION_PLAN.md`
- Current inventory baseline:
  - `InventoryState` now uses explicit `right_hand` / `left_hand` / `armor` / `belt` equipment slots plus backpack-only carried slots
  - equipped gear no longer consumes backpack capacity
  - belts are now authored backpack-utility items through `Belts.rules.backpack_capacity_bonus`
  - passive items stay active while carried in the backpack
  - `InventoryState.consumable_slots` and `InventoryState.passive_slots` now use owner-side versioned caches instead of re-scanning `inventory_slots` on every getter read
  - quest cargo and detached shield mods now live as backpack item families
  - attached shield mods live on shield slot state and can be attached/detached outside combat
  - left-hand slot now supports live `shield` or offhand-capable `weapon` truth
  - `MapExplore` and `Combat` now share the same `RunInventoryPanel` component family
  - current interaction split is mode-based instead of screen-local duplicate UI:
    - `map` mode keeps equip/unequip, reorder, and consumable use live
    - `combat` mode keeps consumable use live while gear swap and reorder stay locked
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
  - live guard feedback now exposes signed gain / absorb / decay readouts instead of only absolute values
  - damage order is now raw damage -> armor reduction -> guard absorption -> HP loss
  - left-hand shield boosts defend guard
  - left-hand offhand weapon grants a small dual-wield attack bonus and defend penalty
  - combat-time gear swaps and backpack reorder are no longer part of the canonical player-facing loop
- Current map/runtime baseline:
  - active procedural stage profiles realize `14`-node center-start controlled-scatter graphs
  - family placement is a separate post-topology step
  - start currently exposes one early combat, one early reward, and one early support route
  - stage start now freezes the full derived board layout for a stable graph signature:
    - `world_positions`
    - frozen `layout_edges`
    - `forest_shapes`
  - discovery now widens `visible_nodes` / `visible_edges` by filtering that frozen layout instead of regenerating route geometry from the visible subset
  - the current board footprint tuning now uses more of the available portrait route-grid surface while keeping the same runtime owner boundary and save shape
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
  - `Game/UI/scene_layout_helper.gd` and `Game/UI/scene_audio_players.gd` now centralize shared scene shell/audio duplication for the current `11` live scene scripts:
    - `main`
    - `main_menu`
    - `map_explore`
    - `combat`
    - `event`
    - `reward`
    - `level_up`
    - `support_interaction`
    - `stage_transition`
    - `run_end`
    - `node_resolve`
  - `event`, `reward`, `support_interaction`, and `level_up` render as overlays above `MapExplore`
  - `stage_transition` and `run_end` use the same run-status shell language but remain standalone screens
  - `combat` uses a height-budget layout plus the shared run-status/formatting foundation
  - `MapExplore` overlay choreography now routes through `Game/UI/map_overlay_director.gd`
  - map route button/marker binding now routes through `Game/UI/map_route_binding.gd`
  - shared inventory tooltip behavior now routes through `Game/UI/inventory_tooltip_controller.gd`
  - combat presentation extraction now routes through:
    - `Game/UI/combat_scene_shell.gd`
    - `Game/UI/combat_feedback_lane.gd`
    - `Game/UI/action_hint_controller.gd`
  - `MapExplore` and `Combat` now share the same inventory/equipment panel family through `Game/UI/run_inventory_panel.gd`
  - current combat inventory rendering uses `combat_compact` density so it stays visually aligned with the map inventory family while preserving combat interaction rules
  - `StageTransition` now surfaces the incoming stage number, stage personality (`pilgrim` / `frontier` / `trade`), and the explicit objective line (`Find the key, then defeat the boss.`)
  - hunger threshold warning toast is now live on both `MapExplore` and `Combat`
  - resolution/fullscreen controls are no longer exposed in the live main menu or safe-menu overlay; current AppBootstrap window-preview lane has also dropped the old unused display getter residue and remains internal startup-only placeholder glue
  - map route travel now follows composed edge geometry, delays board catch-up slightly on departure, and adds restrained stride/arrival polish
  - the board no longer recomposes path geometry from visibility changes alone; graph-stable route geometry now stays fixed while discovery only changes the visible subset
  - the prototype map asset kit is now live on the board surface: trail decals, clearing decals, state plates, canopy clumps, the dedicated `Trail Event` icon, and the refreshed side-mission icon all render through presentation-only hooks with procedural fallback still in place
  - `SourceArt/Generated/new` has now been reviewed as a candidate prototype kit for the later map asset-wave:
    - it is a candidate/source pack, not an authority doc set
    - the pack now uses normalized source-master subfolders plus a short local `README.md`
    - the operational prompt reference kept in-place is `asset_prompts.md`
    - redundant source-planning markdowns now live under `SourceArt/Archive/2026-04-20-map_prototype_pack/docs/`
    - its first intended runtime-adoption families are missing/weak node icons plus path filler, canopy, clutter, fog, and ruin-scatter support
  - combat feedback now resolves on phase beats, keeps same-target feedback from overwriting itself, and gives action-hint / intent / button feedback a narrow motion pass
  - combat defend SFX path now uses the renamed `sfx_defend_01.ogg`; stale `sfx_brace` live references are gone
  - high-visibility runtime asset polish is now live on the current prototype slice:
    - refreshed map-node icon family for `start`, `rest`, `merchant`, `blacksmith`, `trail event`, `hamlet`, `combat`, and `reward`
    - refreshed route-board backdrop shell with stronger compass / guide-lane depth
    - refreshed walker idle / stride frames for clearer traversal readability at portrait targets
  - explicit mechanic and equipment icon lanes are now live for `Defend`, `shield`, `armor`, `belt`, `passive item`, `quest cargo`, and `shield mod`; those surfaces no longer reuse the old generic action, `settings`, `reward`, or `confirm` icons
- Current cleanup/audit baseline:
  - the remaining historical removed-action text in the repo is now limited to historical decision-log rows, deprecation notes, and a regression test assertion
  - the old pre-migration balance-analysis lane has been removed; use current contracts, targeted tests, and live playtests for balance claims
  - a reference-only current content inventory now lives at `Docs/CONTENT_BALANCE_TRACKER.md` so future balance passes do not have to reconstruct the full item/enemy/event surface from scattered contracts
  - legacy audit and prompt material has been consolidated under `Docs/Archive/`; the active continuation queue now lives in `Docs/ROADMAP.md` plus the three active prompt packs under `Docs/Promts/`
  - live entry docs now keep authority routing explicit: `README.md` and `Docs/TECH_BASELINE.md` no longer describe the whole `Docs/` tree as one flat authority surface
  - `Game/Application/game_flow_manager.gd` no longer keeps the old deprecated `dispatch()` surface
  - `Game/Infrastructure/playtest_logger.gd` is now live for debug / `--playtest-log` local session capture
  - the `get_node_or_null()` hot path in `combat.gd` was reduced sharply through scene-cache extraction; the old `118` refresh-heavy lookups are no longer live, though raw file grep still finds a small set of local card-shell lookups
  - typed-owner reflection cleanup now stays guard-locked on the current low-risk slices:
    - `Game/UI/map_explore_presenter.gd`
    - `Game/UI/map_route_binding.gd`
    - `Game/UI/support_interaction_presenter.gd`
    - `scenes/support_interaction.gd`
    - `Game/Infrastructure/scene_router.gd`
    - `Game/Core/combat_resolver.gd`
  - recent extraction passes significantly reduced the two largest scene hotspots:
    - `scenes/combat.gd` is now `1184` lines
    - `scenes/map_explore.gd` is now `1000` lines
  - the frozen-layout map pass is now live and test-backed:
    - `MapRouteBinding` preserves graph-stable `world_positions`, `layout_edges`, and `forest_shapes`
    - `MapBoardComposerV2` now filters visible edges from the frozen full edge layout instead of regenerating them from the visible subset
  - `save_service.gd` is now split:
    - `Game/Infrastructure/save_service.gd` keeps schema-8 write, dispatch, and validation (`660` lines)
    - `Game/Infrastructure/save_service_legacy_loader.gd` carries schema `1/2/5/6/7` compat checks
  - `map_runtime_state.gd` still remains a large high-risk owner file (`2395` lines / `147` functions), but there is now a report-only extraction plan instead of live owner-changing cleanup
- Current save baseline:
  - `save_schema_version = 8`
  - `content_version = prototype_content_v7`
  - save truth remains centered on `RunState`, `MapRuntimeState`, `InventoryState`, and the pending choice owners through `SaveRuntimeBridge`

## Last Verified Validation Checkpoint

These commands were re-run on the current frozen-layout pass and are the freshest headless proof for the checked-out workspace:

- Passed: `py -3 Tools/validate_architecture_guards.py`
- Passed: `powershell -NoProfile -ExecutionPolicy Bypass -File Tools/run_godot_tests.ps1 test_map_board_composer_v2.gd`
- Passed: `powershell -NoProfile -ExecutionPolicy Bypass -File Tools/run_godot_tests.ps1 test_map_board_canvas.gd`
- Passed: `powershell -NoProfile -ExecutionPolicy Bypass -File Tools/run_godot_tests.ps1 test_map_explore_presenter.gd`
- Passed: `powershell -NoProfile -ExecutionPolicy Bypass -File Tools/run_godot_scene_isolation.ps1 -ScenePath scenes/map_explore.tscn`
- Passed: `powershell -NoProfile -ExecutionPolicy Bypass -File Tools/run_godot_full_suite.ps1`
- Not re-run in this pass because scope stayed inside map presentation/docs: `Tools/run_godot_smoke.ps1`, `py -3 Tools/validate_content.py`, `py -3 Tools/validate_assets.py`
- Current repo truth: there is still no dedicated image-diff regression harness; portrait screenshot capture exists, but final visual judgment remains human review.

## Open Risks

- Manual Godot visual verification is still needed for map readability, overlay feel, and combat height-budget behavior on portrait targets, but the repo now has a repeatable portrait screenshot capture lane for the key playtest scenes.
- Manual Godot listening/playtest is still needed for the new prototype music floor. Objective QC now covers loop-boundary continuity and high-frequency load, but fatigue, mix balance, and transition feel still need human ears.
- Motion/camera/combat polish is validated headlessly, but final feel signoff still depends on live Godot playtests for short-route vs long-route travel, roadside interruption continuation, defend/guard readability, low-HP recovery, and portrait viewport behavior.
- The shared `RunInventoryPanel` family is now live across map and combat, but human playtests are still needed for:
  - compact combat density feel
  - map/combat visual family consistency
  - hover/click readability on portrait targets
- `NodeResolve` is still present as legacy code. Do not remove it without an explicit flow audit.
- The live generic `NodeResolve` fallback and legacy-compatible pending-node restore still exist. Behavior-changing cleanup there is not fast-lane work.
- Pending-node continuity still crosses `RunSessionCoordinator` save orchestration and `MapRuntimeState` runtime ownership. Do not move that boundary without an explicit save audit.
- `ContentDefinitions/EventTemplates/` still contains `10` `zz_*.json` alphabetical-hack files; stable-ID cleanup has not been approved yet.
- Shield/offhand content is no longer a one-item lane; the current content pack now includes `5` shield definitions and `3` offhand-capable weapons, but live combat semantics over that wider authored surface are still intentionally narrow and still need manual feel checks.
- `AppBootstrap` and several other hotspot files remain large; extraction-first guardrails are now in place, but no owner-changing cleanup happened in the latest passes.
- The frozen-layout baseline is live, but manual playtest is still needed for reconnect feel, widened footprint comfort, and overall board readability on portrait targets.
- `AppBootstrap` public-surface growth and new `/root/AppBootstrap` lookup spread are now validator-locked, but the existing dependency surface is still live and belongs to guarded cleanup only.
- the current architecture guard now blocks silent line-count growth on the current extraction-first hotspot files, including:
  - `map_runtime_state.gd`
  - `combat.gd`
  - `map_explore.gd`
  - `map_board_composer_v2.gd`
  - `save_service.gd`
  - `save_service_legacy_loader.gd`
  - `inventory_state.gd`
  - `inventory_actions.gd`
  - `map_route_binding.gd`
- Windows export playtests no longer require a preinstalled local template copy if the machine can reach the official Godot `4.6.2` export-template archive during export helper setup.
  - fully offline machines still need a local matching template copy
- Current validated headless snapshot no longer leaves known shutdown-only `ObjectDB instances leaked at exit` / `resources still in use at exit` warnings in `_godot_profile/logs` after the explicit full-suite lane.
  - the runner now clears stale local logs before each pass and treats generic `SCRIPT ERROR:` rows as hidden failures
  - if future teardown/resource noise reappears, treat it as test-lane cleanup work first, not automatic gameplay/runtime drift

## Next Step

1. Close `Docs/Promts/01_foundation_fastlane.md` by keeping `HANDOFF.md`, `ROADMAP.md`, `TECH_BASELINE.md`, and `MAP_RUNTIME_STATE_EXTRACTION_PLAN.md` aligned to the current measurements, guard-backed retired surfaces, and explicit escalation items.
   - treat Prompt 01 as a short closeout-only sanity pass; if the active docs/guards are already aligned, do not invent filler cleanup
2. After the foundation closeout is green, run `Docs/Promts/02_guarded_cleanup.md` to clear the remaining flow/application/scene drift without changing pending-node ownership, save shape, or live `NodeResolve` behavior.
3. Start `Docs/Promts/03_extraction_and_next_wave.md` only after the guarded pass is green; keep `MapRuntimeState` and the big-file chain owner-preserving, and treat pending-node / key-boss-gate / save-codec drift as escalate-first.
   - Prompt 03 now also owns the remaining map next-wave follow-up:
     - reconnect tuning re-check
     - widened-footprint follow-up
     - candidate asset-wave hookup from `SourceArt/Generated/new`
     - variation/residue cleanup
4. Keep manual map/combat/shared-inventory playtests as the human verification lane between the guarded cleanup and the later playtest/telemetry phase.

## Continuation Status

- Ready now: `Docs/Promts/01_foundation_fastlane.md`
  - scope: doc/guard sanity pass only; if it comes up clean, close it and move directly to Prompt 02
- Not ready yet: `Docs/Promts/02_guarded_cleanup.md`
  - blocked by Prompt 01 closeout
- Not ready yet: `Docs/Promts/03_extraction_and_next_wave.md`
  - blocked by Prompt 02 guarded cleanup
- Locked continuation decisions:
  - canonical pending-node owner: `MapRuntimeState`
  - `app_state.pending_node_id` / `app_state.pending_node_type` remain compatibility mirrors for save/restore orchestration; they are not a second owner
  - the live `NodeResolve` generic fallback stays until an explicit flow audit approves behavior-changing removal
  - existing `/root/AppBootstrap` usage may shrink only when owner meaning and live flow behavior stay unchanged
- Explicit escalation items before owner/flow cleanup:
  - changing the pending-node save lane beyond the current compatibility mirror
  - changing or removing the live `NodeResolve` generic fallback behavior
  - narrowing the existing `/root/AppBootstrap` dependency surface if ownership or flow meaning would change

## New Chat Start Order

Use this exact continuation order in a fresh chat:

1. `AGENTS.md`
2. `Docs/DOC_PRECEDENCE.md`
3. `Docs/HANDOFF.md`
4. `Docs/ROADMAP.md`
5. `Docs/Promts/01_foundation_fastlane.md`

Prompt progression rule:

- Start only with Prompt 01.
- If Prompt 01 finds no real fast-lane drift, close it quickly and move directly to Prompt 02.
- Do not start Prompt 03 before Prompt 02 is green.

Copy/paste start message for a new chat:

```text
AGENTS.md, Docs/DOC_PRECEDENCE.md, Docs/HANDOFF.md ve Docs/ROADMAP.md oku.
Sonra yalnız Docs/Promts/01_foundation_fastlane.md promptunu uygula.
Fast-lane dışına taşıyorsa dur ve "escalate first" de.

Verilmiş kararları yeniden tartışma:
- canonical pending-node owner = MapRuntimeState
- app_state.pending_node_id / app_state.pending_node_type = compatibility mirror only, ikinci owner değil
- live NodeResolve generic fallback stays unless explicit flow audit approves removal
- existing /root/AppBootstrap usage may shrink only if owner meaning and live flow behavior stay unchanged

Cleanup kuralı:
- provably dead surface ise sil
- live runtime/restore/test/validator use varsa koru
- aktif sette "belki lazım olur" ballast tutma
```