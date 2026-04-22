# SIMPLE RPG - Handoff

Last updated: 2026-04-22

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
  - late-route scatter tuning now adds a deterministic downward bias so progressed pockets use more of the lower portrait board instead of collapsing into mostly upper / lateral lanes
  - live board follow now clamps to visible-content bounds so visible roads and clearings stay inside the padded route frame instead of clipping out during progression-only focus drift
  - visible-route continuity now restores missing connector edges only from the frozen `layout_edges` set when clamp/focus interactions would otherwise split the visible cluster; discovery still does not regenerate geometry from the visible subset
  - the Prompt 05 layout pass kept save shape, flow, owner meaning, graph truth, and visibility-filtering semantics unchanged while staying inside the composer / route binding lane
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
  - `MapExplore` overlay choreography now routes through `Game/UI/map_overlay_director.gd` plus the shared `OverlayFlowContract` / `MapOverlayContract` state/name surface
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
    - future runtime-facing adoption remains scoped to the Prompt 04 semantic wave direction: missing/weak node icons first, then optional semantic props / item / portrait surfaces if later approved
    - terrain-transition, path-filler, canopy, fog, clutter, and ruin-scatter families stay candidate/source-only and are not the next runtime-adoption lane
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
- legacy audit and prompt material has been consolidated under `Docs/Archive/`; the active continuation queue now lives in `Docs/ROADMAP.md` plus the remaining active prompt pack under `Docs/Promts/`
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
    - `scenes/combat.gd` is now `1142` lines
    - `scenes/map_explore.gd` is now `930` lines
  - the frozen-layout map pass is now live and test-backed:
    - `MapRouteBinding` preserves graph-stable `world_positions`, `layout_edges`, and `forest_shapes`
    - `MapBoardComposerV2` now filters visible edges from the frozen full edge layout instead of regenerating them from the visible subset
  - `save_service.gd` is now split:
    - `Game/Infrastructure/save_service.gd` keeps schema-8 write, dispatch, and validation (`660` lines)
    - `Game/Infrastructure/save_service_legacy_loader.gd` carries schema `1/2/5/6/7` compat checks
  - `map_runtime_state.gd` still remains a large high-risk owner file (`2279` lines / `146` functions), but its first owner-preserving extraction pass now routes pure scatter adjacency/depth/path/connectivity helpers through `Game/RuntimeState/map_scatter_graph_tools.gd` while pending-node, key/boss-gate, reset lifecycle, and save-codec logic stay local to the owner
- `map_board_composer_v2.gd` now measures `928` lines after the Prompt 05 scatter / continuity follow-up; `Game/UI/map_board_layout_solver.gd` carries layout placement/collision/crossing helpers while `MapBoardComposerV2` stays the caller-facing derived-layout owner and the frozen full-layout baseline stays unchanged
  - `inventory_actions.gd` now measures `230` lines after its first application-local extraction pass; `Game/Application/inventory_item_mutation_helper.gd` carries item-mutation helpers while `InventoryActions` stays the caller-facing mutation surface and save/runtime ownership stays unchanged
  - `run_session_coordinator.gd` now measures `751` lines after its first application-local extraction pass; `Game/Application/run_session_state_helper.gd` carries state/setup utility helpers while pending-node compat mirror handling, direct-entry routing, and save/restore assumptions stay with `RunSessionCoordinator`
- `map_route_binding.gd` now measures `855` lines after the Prompt 05 closeout follow-up; `Game/UI/map_route_layout_helper.gd` and `Game/UI/map_route_motion_helper.gd` carry emergency-layout and route-motion math while `MapRouteBinding` stays the caller-facing board/route binding owner and the frozen-layout plus widened-footprint behavior stays unchanged
- Current save baseline:
  - `save_schema_version = 8`
  - `content_version = prototype_content_v7`
  - save truth remains centered on `RunState`, `MapRuntimeState`, `InventoryState`, and the pending choice owners through `SaveRuntimeBridge`

## Last Verified Validation Checkpoint

These commands were re-run through the latest Prompt 04 no-stamp verification follow-up and Prompt 05 closeout follow-up; this is the freshest headless proof for the checked-out workspace:

- Passed: `py -3 Tools/validate_architecture_guards.py`
- Passed: `powershell -NoProfile -ExecutionPolicy Bypass -File Tools/run_godot_full_suite.ps1` (`51` test)
- Passed earlier in the latest map-pass closeout lane: targeted map tests, including `test_map_board_composer_v2.gd`, `test_map_explore_presenter.gd`, `test_map_board_canvas.gd`, and `test_button_tour.gd`
- Passed earlier in the latest map-pass closeout lane: `powershell -NoProfile -ExecutionPolicy Bypass -File Tools/run_godot_scene_isolation.ps1 -ScenePath scenes/map_explore.tscn`
- Passed earlier in the latest renderer lane: `py -3 Tools/validate_assets.py`
- Not re-run in the latest map-pass closeout because scope stayed outside content truth: `py -3 Tools/validate_content.py`
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
- Asset adoption remains intentionally blocked until both of these are true:
  - approved runtime filenames and truthful manifest rows exist for the intended asset families
  - manual map playtest confirms the frozen-layout baseline is visually stable on portrait progression states
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

1. The active future-queue is the UI overhaul wave: Prompts 06, 06.5, 07, 08, 09, 10, 10.5, 11, 11.5, 12, 12.5 tracked in `Docs/ROADMAP.md` and checked in under `Docs/Promts/`. Run them sequentially per `Docs/ROADMAP.md` Continuation Launch Order, one part per Codex message, and do not start the next pack until the current one is closed.
   - checked-in prompt files currently exist under `Docs/Promts/` for `06`, `01` (Prompt `06.5`), `07`, `08`, `09`, `10`, `10.5`, `11`, `02` (Prompt `11.5`), `03` (Prompt `12`), and `12.5`
   - Prompt 06 is the next active step; it produces `Docs/UI_INFORMATION_ARCHITECTURE_AUDIT.md` as a reference-only audit and grounds the Prompt 07-12 scope in repo truth (no gameplay logic, save schema, or asset hookup change).
   - Prompt 06.5 produces `Docs/UI_MICROCOPY_AUDIT.md` and assigns text-quality rewrite hand-offs to Prompts 07-11 (docs-only).
   - Prompts 07-09 carry the per-screen UI hierarchy work (inventory drawer, event choice cards, combat hierarchy) using existing truth only.
   - Prompt 10 lands cross-screen readability guardrails (font / icon / touch-target / contrast).
   - Prompt 10.5 adds the only save-aware piece in the wave: a frozen 8-hint `FirstRunHintController` that fires once per save (no tutorial mode, no rotating tips).
   - Prompt 11 centralizes shared UI tokens after the hierarchy and readability wins land (cleanup-only, no rename).
   - Prompt 11.5 implements the empty-state, loading/transition-state, and error/failure-state rewrites from the microcopy audit (presentation-only).
   - Prompt 12 produces `Docs/SEMANTIC_ICON_READINESS_CHECKLIST.md` as a runtime-readiness / asset-contract checkpoint; it does not unblock asset hookup by itself.
   - Prompt 12.5 closes the wave with `Docs/UI_ACCESSIBILITY_AND_MOBILE_AUDIT.md` and a prioritized narrow follow-up queue (docs-only).
2. The map lane (Prompt 04 / Prompt 05) does not block the UI overhaul wave. Prompt 04 and Prompt 05 are closed green on this workspace; reopen them only if a future portrait capture or manual playtest shows fresh drift inside the same owner lanes.
3. Keep the asset-hook step deferred. The terrain-asset hookup framing from the archived Prompt 03 Part G is superseded by Prompt 04 direction; future asset wave work is scoped to the semantic icon / prop / item / portrait surfaces planned in Prompt 04 Part D and tracked toward runtime-contract readiness in Prompt 12.
4. Manual portrait map playtest stays the final visual signoff lane before any future runtime asset hookup.
5. After the full UI overhaul wave (Prompt 06 through 12.5) closes, the next broader roadmap phase is Phase D (`Playtest and Telemetry`).

## Continuation Status

- Archived closed green: `Docs/Archive/Prompts/2026-04-21-phase-a-closed/01_foundation_fastlane.md`
  - scope completed: doc/guard sanity pass and authority wording closeout
- Archived closed green: `Docs/Archive/Prompts/2026-04-21-phase-a-closed/02_guarded_cleanup.md`
  - scope completed: `NodeResolve` contract hardening, pending-node boundary isolation, bootstrap/scene shell cleanup, shared inventory-panel layout owner, and overlay contract hardening
- Archived: `Docs/Archive/Prompts/2026-04-21-phase-a-closed/03_extraction_and_next_wave.md`
  - scope completed: `Part A-F` landed the extraction wave across `MapRuntimeState`, `map_board_composer_v2`, `inventory_actions`, `run_session_coordinator`, and `map_route_binding` without changing save shape or owner meaning
  - `Part G` (asset-hook wiring) is superseded by Prompt 04 code-first direction; the terrain-asset hookup framing is no longer the next active step and is not part of the active queue
- Archived measured closeout: `Docs/Archive/Prompts/2026-04-22-map-lane-closed/04_map_renderer_code_first.md`
  - direction: code-first procedural map renderer; AI asset wave scoped to semantic single-object surfaces only
  - `Part A-E` are complete on this workspace
  - measured result: direction docs landed, procedural renderer polish landed, the renderer review lane passed checkpoints `1-6`, semantic icon-wave planning now lives in `Docs/ASSET_WAVE_SEMANTIC_SCOPE.md`, and the fresh no-stamp verification lane passed checkpoint `7` with [stage_start](../export/portrait_review/prompt04_no_stamp_after_20260422_074912/stage_start_1080x1920.png), [mid_progression](../export/portrait_review/prompt04_no_stamp_after_20260422_074912/mid_progression_1080x1920.png), [late_progression](../export/portrait_review/prompt04_no_stamp_after_20260422_074912/late_progression_1080x1920.png), and [report](../export/portrait_review/prompt04_no_stamp_after_20260422_074912/prompt04_no_stamp_report.json)
  - status: closed green on the current workspace
- Archived measured closeout: `Docs/Archive/Prompts/2026-04-22-map-lane-closed/05_map_layout_regression_fix.md`
  - direction: fix or explicitly disprove lower-board underuse, over-lateral clustering, clipped/disappearing route segments, and fragmented visible cluster inside the composer / route binding lane
  - `Part A-F` are complete on this workspace
  - measured result: the final green lane [stage_start](../export/portrait_review/prompt05_followup_after_20260422_074840/stage_start_1080x1920.png), [mid_progression](../export/portrait_review/prompt05_followup_after_20260422_074840/mid_progression_1080x1920.png), [late_progression](../export/portrait_review/prompt05_followup_after_20260422_074840/late_progression_1080x1920.png), and [report](../export/portrait_review/prompt05_followup_after_20260422_074840/prompt05_part_e_report.json) clear lower-board underuse, over-lateral clustering, clipped/disappearing route segments, and fragmented visible cluster while preserving the frozen-layout signature across progression states
  - status: closed green on the current workspace
- Active future-queue (sequential, one part per Codex message; no pack starts before the previous one closes):
  - `Docs/Promts/06_ui_information_architecture_audit.md`
    - active, ready
    - goal: produce reference-only `Docs/UI_INFORMATION_ARCHITECTURE_AUDIT.md` covering current UI hierarchy across `MapExplore`, `Combat`, the overlay family, and the run-status shells using repo truth
    - hard guardrails: docs-only; no gameplay logic, save/schema, asset hookup, flow, or ownership change
  - `Docs/Promts/06_5_microcopy_audit.md` (Prompt `06.5`)
    - queued after 06
    - goal: produce reference-only `Docs/UI_MICROCOPY_AUDIT.md` of every player-facing text surface (tooltips, disabled reasons, button labels, empty / error / one-shot strings); assigns rewrite hand-offs to Prompts 07-11
    - hard guardrails: docs-only; no code change in this pack
  - `Docs/Promts/07_inventory_equipment_drawer.md`
    - queued after 06.5
    - goal: improve inventory drawer hierarchy and equip/use clarity using existing truth only
    - preferred owners: `Game/UI/run_inventory_panel.gd`, `Game/UI/inventory_panel_layout.gd`, `Game/UI/inventory_tooltip_controller.gd`
  - `Docs/Promts/08_event_modal_choice_cards.md`
    - queued after 07
    - goal: improve event modal choice card readability and decision clarity using existing truth only
    - preferred owners: `Game/UI/event_presenter.gd`, `scenes/event.gd` (composition-only)
    - overlay note: keep the modal a pure consumer of `OverlayFlowContract` / `MapOverlayContract`; no new overlay state
  - `Docs/Promts/09_combat_hierarchy.md`
    - queued after 08
    - goal: improve combat action clarity and screen hierarchy using existing truth only; no combat math, intent logic, or item-effect change
    - preferred owners: `Game/UI/combat_scene_ui.gd`, `Game/UI/combat_presenter.gd`, `Game/UI/run_status_presenter.gd`, `Game/UI/combat_scene_shell.gd`, `Game/UI/combat_feedback_lane.gd`, `Game/UI/action_hint_controller.gd`
  - `Docs/Promts/10_font_icon_readability_guardrails.md`
    - queued after 09
    - goal: cross-screen readability guardrails for font sizing, icon legibility, and contrast at portrait targets; no gameplay/UI flow change
    - preferred owners: `Game/UI/temp_screen_theme.gd` (no rename), `Game/UI/scene_layout_helper.gd`, `Game/UI/inventory_panel_layout.gd`
  - `Docs/Promts/10_5_first_run_hints.md`
    - queued after 10
    - goal: add a small save-aware `FirstRunHintController` that shows a frozen 8-hint set once per save (defend, dual-purpose left-hand, hamlet personality, roadside encounter, key-required route, belt capacity, low hunger)
    - hard guardrails: this is the only pack in the 06-12 wave that may add an additive-optional save field; no tutorial mode, no rotating tips system; combat / map / event input is never blocked by a hint
  - `Docs/Promts/11_ui_theme_token_cleanup.md`
    - queued after 10.5
    - goal: centralize shared UI color/spacing/typography/component-state tokens after hierarchy and readability wins land; cleanup-only, no behavior change
    - hard guardrails: no file rename (including `temp_screen_theme.gd`)
  - `Docs/Promts/11_5_empty_error_states.md` (Prompt `11.5`)
    - queued after 11
    - goal: implement empty-state, loading/transition-state, and error/failure-state rewrites from `Docs/UI_MICROCOPY_AUDIT.md` so blank surfaces and failure paths feel intentional and consistent
    - hard guardrails: presentation-only; no failure semantics or save change
  - `Docs/Promts/12_semantic_icon_readiness.md` (Prompt `12`)
    - queued after 11.5; also gated on Prompt 04 Part D (already landed)
    - goal: produce reference-only `Docs/SEMANTIC_ICON_READINESS_CHECKLIST.md` as a runtime-readiness / asset-contract checkpoint
    - hard guardrails: no asset generation, no asset approval, no `UiAssetPaths` change, no runtime hook implementation; this pack does not unblock asset hookup by itself
  - `Docs/Promts/12_5_accessibility_mobile_audit.md`
    - queued after 12 (final pack in the UI overhaul wave)
    - goal: produce reference-only `Docs/UI_ACCESSIBILITY_AND_MOBILE_AUDIT.md` covering color contrast, color-only signaling, text scaling, motion/flash safety, focus visibility, portrait safe-area, plus mobile interaction conflicts (tap vs swipe vs drag, accidental-tap zones, touch target overlap), and emit a prioritized narrow follow-up queue
    - hard guardrails: docs-only; no code change in this pack
- Locked continuation decisions:
  - canonical pending-node owner: `MapRuntimeState`
  - `app_state.pending_node_id` / `app_state.pending_node_type` remain compatibility mirrors for save/restore orchestration; they are not a second owner
  - the live `NodeResolve` generic fallback stays until an explicit flow audit approves behavior-changing removal
  - existing `/root/AppBootstrap` usage may shrink only when owner meaning and live flow behavior stay unchanged
  - Map Composer V2 presentation's structural truth owner is code; ground / trail / clearing / canopy / filler / junction / forest-transition surfaces stay procedural; existing optional terrain stamps under `Assets/UI/Map/` stay as polish only
- Explicit escalation items before owner/flow cleanup:
  - changing the pending-node save lane beyond the current compatibility mirror
  - changing or removing the live `NodeResolve` generic fallback behavior
  - narrowing the existing `/root/AppBootstrap` dependency surface if ownership or flow meaning would change
  - any move that would promote terrain-blending art into runtime, hook unapproved `SourceArt/Generated/` files, or repoint `UiAssetPaths` constants without the `ASSET_PIPELINE.md` approval + manifest row contract

## New Chat Start Order

Use this exact continuation order in a fresh chat:

1. `AGENTS.md`
2. `Docs/DOC_PRECEDENCE.md`
3. `Docs/HANDOFF.md`
4. `Docs/ROADMAP.md`
5. `Docs/Promts/06_ui_information_architecture_audit.md` (active next pack)
6. queued behind 06, in order: `Docs/Promts/06_5_microcopy_audit.md` (Prompt `06.5`), `Docs/Promts/07_inventory_equipment_drawer.md`, `Docs/Promts/08_event_modal_choice_cards.md`, `Docs/Promts/09_combat_hierarchy.md`, `Docs/Promts/10_font_icon_readability_guardrails.md`, `Docs/Promts/10_5_first_run_hints.md`, `Docs/Promts/11_ui_theme_token_cleanup.md`, `Docs/Promts/11_5_empty_error_states.md` (Prompt `11.5`), `Docs/Promts/12_semantic_icon_readiness.md` (Prompt `12`), `Docs/Promts/12_5_accessibility_mobile_audit.md`

Prompt progression rule:

- Prompt 01, Prompt 02, and Prompt 03 are already archived under `Docs/Archive/Prompts/2026-04-21-phase-a-closed/`. Do not reopen them.
- Prompt 03 Part G (asset-hook wiring) is superseded by Prompt 04 direction. The asset-hook step stays deferred behind the `ASSET_PIPELINE.md` approval + manifest row contract.
- Prompt 04 Part A-E and Prompt 05 Part A-F are already complete and closed green on this workspace. Reopen either pack only if a future portrait capture or manual playtest shows fresh drift inside the same owner lanes.
- The current active queue is the UI overhaul wave: Prompts 06, 06.5, 07, 08, 09, 10, 10.5, 11, 11.5, 12, 12.5. Run them sequentially, one Part per Codex message, and do not start the next pack until the current one is closed. Do not run any of these packs in parallel.
- Prompt 06, 06.5, 12, and 12.5 are docs-only audit packs; they must not introduce code, gameplay, save, asset, or flow changes.
- Prompts 07-09 and 11.5 are per-screen / per-state presentation work using existing runtime truth only; no combat math, intent logic, item effect, save shape, or flow change.
- Prompts 10 and 11 are cross-screen readability guardrails and shared-token cleanup; no behavior change disguised as cleanup; no file rename.
- Prompt 10.5 is the only pack in the wave that may add an additive-optional save field (the persisted shown-hint set). It must not introduce a tutorial mode or a rotating tips system, and no hint may block input.
- Prompt 12 is a runtime-readiness / asset-contract checkpoint and produces `Docs/SEMANTIC_ICON_READINESS_CHECKLIST.md`; it does not generate, approve, or hook any asset and does not unblock asset hookup by itself.
- After the full UI overhaul wave (Prompt 06 through 12.5) closes, the next broader roadmap phase is Phase D (`Playtest and Telemetry`).

Copy/paste start message for a new chat:

```text
AGENTS.md, Docs/DOC_PRECEDENCE.md, Docs/HANDOFF.md ve Docs/ROADMAP.md oku.
Sonra Docs/Promts/06_ui_information_architecture_audit.md prompt paketini oku ama uygulamaya baslama.

UI overhaul dalgasi suanda kuyrukta (siraya sadik kal):
06 -> 06.5 -> 07 -> 08 -> 09 -> 10 -> 10.5 -> 11 -> 11.5 -> 12 -> 12.5

Calisma kurallari:
- her Codex mesajinda yalnizca tek bir Part calistir
- bu paketleri paralel calistirma; siralama ROADMAP'teki Continuation Launch Order'a sadik kalmali
- bir paket "closed green" olmadan bir sonraki pakete gecme

Pack-bazli kisitlar:
- 06 reference-only audit (UI_INFORMATION_ARCHITECTURE_AUDIT.md uretir); gameplay, save/schema, asset hookup, flow degisikligi yok
- 06.5 reference-only audit (UI_MICROCOPY_AUDIT.md uretir); kod degisikligi yok
- 07-09 var olan runtime truth'u kullanarak per-screen UI hierarchy duzeltir; combat math, enemy intent logic, item effect veya save shape degistirme
- 10 cross-screen readability guardrail; temp_screen_theme.gd rename yok
- 10.5 dalganin tek save-aware paketi: additive-optional shown-hint alani. Tutorial mode ekleme; rotating tips ekleme; hint asla input bloklamaz; donmus 8-hint set disinda hint ekleme
- 11 shared UI token cleanup; cleanup wording'i altinda davranis degisikligi gizleme; dosya rename yok
- 11.5 empty / loading / error state pass; presentation-only; failure semantics degistirme
- 12 runtime-readiness / asset-contract checkpoint (SEMANTIC_ICON_READINESS_CHECKLIST.md uretir); asset uretmez, onaylamaz, hook etmez; UiAssetPaths repoint etmez
- 12.5 erisilebilirlik + mobil interaction audit (UI_ACCESSIBILITY_AND_MOBILE_AUDIT.md uretir); kod degisikligi yok; sadece prioritized narrow follow-up queue
- her pakette Existing-Truth Rule gecerli: yeni gameplay prediction logic ekleme; gerekiyorsa NEEDS_FUTURE_LOGIC_SUPPORT olarak isaretle

Map layout notu:
- 04 Part A-E ve 05 Part A-F uygulanmis durumda ve bu workspace'te closed green
- yeniden acilacaksa yalnizca yeni measured drift uzerinden dar composer / route-binding / renderer follow-up scope'unda ac
- UI overhaul sirasi bu follow-up'a baglanmaz; map ve UI lane'leri ayri ilerler

Asset kurali:
- Prompt 03 Part G implement edilmeyecek; superseded by Prompt 04 direction
- terrain blending / ground / trail / clearing / canopy uretimi yok
- SourceArt/Generated/ icindeki hicbir dosya runtime icin onayli sayilmaz
- UiAssetPaths sabitlerine yeni bir asset eklenmez veya repoint edilmez
- semantik icon hookup'i Prompt 12 readiness checklist'i tek basina actigi anlamina gelmez; ASSET_PIPELINE.md onayi + manifest row contract gerekir

Verilmis kararlari yeniden tartisma:
- canonical pending-node owner = MapRuntimeState
- app_state.pending_node_id / app_state.pending_node_type = compatibility mirror only, ikinci owner degil
- live NodeResolve generic fallback stays unless explicit flow audit approves removal
- existing /root/AppBootstrap usage may shrink only if owner meaning and live flow behavior stay unchanged
- Map Composer V2 presentation'in structural truth owner'i kod; terrain stamps optional polish

Cleanup kurali:
- provably dead surface ise sil
- live runtime/restore/test/validator use varsa koru
- aktif sette "belki lazim olur" ballast tutma
```
