# SIMPLE RPG - Handoff

Last updated: 2026-04-15

This file is a current-state snapshot only.
It is not a rule contract. If it conflicts with an authority doc, the authority doc wins.

## Current State

- The repo is prototype-playable with a mobile-first responsive UI overhaul applied across all main gameplay scenes. Content validation and architecture guards pass.
- UI overlay system is now live: non-combat node interactions (event, reward, support_interaction, level_up) render as popup overlays on top of `MapExplore` instead of full-screen scene transitions. The map, HUD, and inventory remain visible behind the semi-transparent overlay.
- Combat scene uses a height-budget layout system that constrains enemy/player cards, buttons, and secondary scroll to fit within viewport height. Empty status section auto-collapses. Button and card heights are reduced and responsive.
- All overlay scenes (event, reward, support_interaction, level_up) detect overlay mode via `top_level` flag and skip opaque backdrop styling when used as overlays.
- `TempScreenTheme` now includes a `compute_overlay_margins()` utility for consistent popup margin calculation.
- Combat encounters now skip `NodeResolve` bridge screen and transition directly from `MapExplore` to `Combat`, eliminating the intermediate "THREAT READ" screen.
- Current live runtime spine is now:
- `Boot -> MainMenu -> RunSetup -> MapExplore`
- `MapExplore -> Combat | Event (via NodeResolve) | Reward (via NodeResolve) | SupportInteraction`
- `Combat -> Reward -> LevelUp? -> MapExplore` (non-boss)
- `Combat -> StageTransition -> MapExplore` on stages `1-2` (boss)
- `Combat -> RunEnd` on stage `3` (final boss)
- defeat `Combat -> RunEnd -> MainMenu`
- Current `MapExplore` board truth is still composer-driven presentation over runtime map truth:
- `MapRuntimeState` owns realized graph truth, node state, current node, key/boss-gate truth, pending node context, support-node revisit state, and now side-mission contract state
- `MapBoardComposerV2` still derives world positions / edges / forest shapes from runtime snapshots plus seed; it does not write board layout data back into runtime state
- Current procedural stage baseline is now denser:
- active stage templates realize `14` nodes total
- runtime generation is now profile-driven controlled scatter keyed by the `procedural_stage_*` ids rather than authored scaffold adjacency
- runtime family placement is now a separate post-graph controlled assignment step rather than being baked into graph construction
- each stage currently guarantees `1` `side_mission` node in addition to the existing combat / event / reward / support / key / boss floor
- start currently exposes one early combat route, one early reward route, and one early support route
- opening support and late support currently share the same explicit branch
- the technical `event` node family is now rendered to the player as `Roadside Encounter`
- Current side-mission truth is live:
- one dedicated `side_mission` node opens `SupportInteraction`
- accepting the contract chooses one eligible combat node and one enemy definition through the run RNG stream, reveals that target node, and highlights it on the map board
- defeating that marked target completes the contract but still flows through the normal combat reward / level-up cadence
- returning to the original contract node after completion offers `2` random reward choices drawn from the authored side-mission pool
- claiming one reward adds the chosen weapon or armor into the shared carried inventory bag
- claimed side-mission nodes fall back to normal traversal-only revisit behavior
- Current shared inventory truth remains the bag model:
- base capacity `5`
- equipped belt bonus `+2`
- carried `weapon`, `armor`, `belt`, `consumable`, and `passive` families all live in the same runtime owner and save payload
- Current blacksmith truth is the shared-gear upgrade lane:
- one visit may temper a chosen carried weapon (`+1` attack), reinforce a chosen carried armor (`+1` defense), or repair the active weapon
- Current support-node and combat-node flow is now direct:
- `rest`, `merchant`, `blacksmith`, `side_mission` enter `SupportInteraction` straight from `MapExplore`
- `combat` and `boss` nodes now enter `Combat` straight from `MapExplore`
- they no longer show the separate `NodeResolve` bridge screen or its extra open-sfx layer first
- Current rest truth remains the trade-off version:
- one rest grants `+8 HP`
- that same rest spends `4` hunger
- Current save baseline is:
- `save_schema_version = 5`
- `content_version = prototype_content_v4`
- side-mission persistence now lives in `MapRuntimeState` save payload through `side_mission_node_states`
- shared inventory save truth still centers on `inventory_slots`, `inventory_next_slot_id`, and active equipped weapon / armor / belt slot ids

## Direct Validation

- Passed: `python3 Tools/validate_content.py`
- Passed: `python3 Tools/validate_architecture_guards.py`
- Godot test suite and smoke tests not rerun in this UI pass (no runtime logic changed). Rerun before claiming full regression coverage.

## Open Risks

- Overlay popup system is wired but not yet runtime-tested in Godot. The overlay open/close functions follow the proven event overlay pattern, but actual Godot playtest verification is needed.
- Combat height-budget layout is calculated correctly by formula but needs visual verification across the target resolutions in Godot editor or device.
- Overlay scenes skip backdrop styling when `top_level == true`; if any scene is instantiated as top_level for another reason, it would also skip backdrop styling.
- Side-mission reward pool remains intentionally small (`2` new weapons, `2` new armors).
- Windows playtest export was not rerun in this pass.

## Next Step

1. Run the Godot test suite and smoke tests to confirm no runtime regressions from the UI changes.
2. Visual playtest the overlay system in Godot: open a support/reward/level_up node from the map and verify the map stays visible behind the overlay.
3. Visual playtest combat at different viewport sizes (1080x2400, 720x1280, 1366x768) to verify the height budget prevents overflow.
4. If the next pass touches flow state or scene routing, verify that the `_sync_overlays_with_flow_state()` function in map_explore.gd correctly opens/closes overlays for all supported flow states.
