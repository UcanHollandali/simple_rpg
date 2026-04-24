# Prompt Packs

`Docs/Promts/` is the live execution-pack folder for the current active wave only.

Current state:
- the active prompt wave is the reset `01-18` map-system continuation pack
- `Prompt 01` is closed as the current-truth/target-lock pass
- `Prompt 02` is closed as a baseline failure-naming pass, not as structural green
- `Prompt 03` is next
- the previous `43-62` map-system-replacement pack is archived as superseded mid-wave history under `Docs/Archive/Prompts/2026-04-23-superseded-map-wave-reset/`
- `Prompt 07` is the render-model core payload pass
- `Prompt 08` is the render-model masks/slots payload pass
- `Prompt 09` is the path-surface canvas/default-lane pass
- `Prompt 13` is map scene shell and adjacent-UI read
- `Prompt 14` is asset-socket readiness only, not an asset spike
- `Prompt 16` is a provisional candidate asset dressing smoke and runs only after Prompt 15 says structure and sockets are ready for it
- `Prompt 17-18` are the cleanup/final-hygiene tail and run only after Prompt 15/16 says cleanup/hygiene is safe
- candidate art remains closed by default and must not be used as structural proof in this wave
- map identity target is center-local start with seed/profile-varied north/south/east/west outward route emphasis, not an edge-entry ladder
- use `Docs/ROADMAP.md` for active queue order and open/closed state
- use `Docs/HANDOFF.md` for current-state snapshot only
- do not treat this folder as an authority surface
- if active prompt numbers collide with archived historical prompt numbers, the active `Docs/Promts/` filename wins and archived packs must be named as archived history

Global stop rules:
- if screenshot/readback truth is structurally short, do not claim green
- candidate art is never structural proof
- save-shape, flow-state, or source-of-truth drift requires `escalate first`
- default-lane switches require evidence; test green alone is not enough

Upstream failure routing:
- if Prompt 03 cannot lock the sector contract, stay in Prompt 03 or run a narrow Prompt 02 evidence recheck if fresh baseline evidence is missing
- if Prompt 04 cannot expose owner-safe graph metadata, do not proceed to Prompt 05 placement until runtime ownership/read truth is resolved
- if Prompt 05 placement fails because topology metadata is missing, return to Prompt 04; if placement fails only in UI anchor math, stay in Prompt 05
- if Prompt 06 corridor routing fails because anchors are unstable, return to Prompt 05; if graph adjacency is the root cause, return to Prompt 04
- if Prompt 07 or Prompt 08 cannot build derived render-model payloads without inventing truth, return to the earliest runtime/placement/corridor prompt that owns the missing input
- if Prompt 09 cannot make path surfaces the default lane, keep the legacy lane labeled `fallback` and return to Prompt 07/08 only if payload shape is the root blocker
- if Prompt 10-14 fail visual review, name the earliest owner-level cause instead of widening locally: traversal to Prompt 09/10, pockets to Prompt 11, terrain to Prompt 12, scene shell to Prompt 13, sockets to Prompt 14
- Prompt 15 must choose `stop for structural continuation` if the earliest cause is still upstream; Prompt 16-18 must not patch around structural failure with assets or cleanup

Working rules for this folder:
- keep only live prompts here
- do not restore archived prompt packs into the active folder
- do not stack `.5` interstitial prompts by default
- if the active wave becomes stale or contradictory, rewrite the active sequence and sync `Docs/HANDOFF.md` plus `Docs/ROADMAP.md` instead of layering another numbering fragment
- `Docs/Promts/Next/` may hold inactive future-lane stubs, but nothing under `Next/` is part of the live queue until `Docs/ROADMAP.md` explicitly promotes it

Active prompt order:
Current cursor: `03_hidden_sector_grammar_contract_recheck.md` is next.

1. `01_current_truth_reset_and_target_lock.md`
2. `02_baseline_reproduction_and_failure_naming.md`
3. `03_hidden_sector_grammar_contract_recheck.md`
4. `04_runtime_topology_and_hunger_route_shape.md`
5. `05_slot_anchor_placement_foundation.md`
6. `06_local_adjacency_and_corridor_routing.md`
7. `07_render_model_core_payload.md`
8. `08_render_model_masks_slots_payload.md`
9. `09_path_surface_canvas_and_default_lane.md`
10. `10_walker_traversal_and_exploration_feel.md`
11. `11_landmark_pockets_as_places.md`
12. `12_terrain_canopy_negative_space.md`
13. `13_map_scene_shell_and_adjacent_ui_read.md`
14. `14_asset_socket_readiness_gate.md`
15. `15_integrated_structural_closeout_and_cleanup_gate.md`
16. `16_candidate_asset_dressing_smoke.md`
17. `17_map_legacy_cleanup_dead_code_retirement.md`
18. `18_map_final_hygiene_closeout.md`

Inactive future stubs:
- `Next/production_art_wave_stub.md` exists only as a placeholder for a later production-art lane after Prompt 18 chooses that lane; it is not active queue truth
