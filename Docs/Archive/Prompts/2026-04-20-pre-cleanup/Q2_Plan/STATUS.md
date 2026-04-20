# Q2 Plan — Unified Prompt Status

Last regenerated: 2026-04-20 (after rollback verification on branch `codex/roadside-map-refresh-fixes`, head `352e7af`).

## Purpose

This file is the single place where every Codex prompt living under `Docs/Promts/` has a measured status:

- `applied` — the prompt's deliverable is visible in the repo today.
- `partial` — some but not all of the deliverable is visible; the remainder is still open.
- `open` — no evidence in the repo; the work has not been run or was rolled back.
- `retired` — the prompt is obsolete, duplicated by another prompt, or superseded by a Q2 plan decision.

When Codex finishes a prompt, flip its row here. When a row flips to `applied`, mark the row green and move on to the next `open` row in the **Execution order** table below.

Status is measured — every row below was checked against live repo evidence (file presence, line counts, grep hits). Kesin bilgi olarak not edilmeye çalışıldı; belirsiz kalanlar `partial` olarak işaretlendi.

---

## Big Picture

Three prompt files live in `Docs/Promts/` root plus one asset roadmap. They are layered:

1. `CODEX_V2_MASTER_PROMPTS.md` — follow-up cleanup pass (Prompts `0.1`, `1.x`, `2.x`, `3.x`, `5.x`). Mostly overlaps with Q2 Plan W0/W1/W2.
2. `CODEX_V2_BIG_FILE_MASTER_PROMPTS.md` — extraction pass for four hotspot files (MBC, INV, RSC, MRB). None landed.
3. `MAP_MASTER_PROMPTS.md` — map redesign + theming + topology + path-family pass (Prompts `1`…`8`). Most landed; assets not wired.
4. `AI_ASSET_ROADMAP_V2.md` — human asset production guide, not a Codex prompt.

Q2 Plan (`Docs/Promts/Q2_Plan/`) is the refreshed, rollback-aware version of the V2 pass, wired to `Docs/ROADMAP_2026Q2.md` and closed decisions `D-041..D-046`. V1 and Q2 rows below are cross-referenced so one run of Codex closes both.

---

## CODEX_V2_MASTER_PROMPTS.md status

Source: `Docs/Promts/CODEX_V2_MASTER_PROMPTS.md`.

| V1 ID | Topic | Status | Evidence | Q2 equivalent | Next action |
|---|---|---|---|---|---|
| `0.1` | A6 maintainability audit artifact | open | `Docs/Audit/2026-04-18-maintainability-audit.md` missing | `w0_01` | run `w0_01` |
| `1.1` | SAVE_SCHEMA pending-node ownership fix | partial | `SAVE_SCHEMA.md:193` mentions pending node but ownership wording unverified against `RS-F1` | `w0_04` | run `w0_04` |
| `1.2` | COMMAND_EVENT_CATALOG drift (`turn_phase_resolved`, `BossPhaseChanged`) | open | zero catalog hits; 6 + 9 code hits | `w0_05` | run `w0_05` |
| `1.6` | Architecture guard expansion (catalog-drift + stale-wrapper rules) | open | validator has zero `catalog` / `stale_wrapper` tokens | `w1_04` | run `w1_04` after `w0_05` |
| `1.3` | Inventory display-name/family helper extraction | partial | `Game/UI/map_display_name_helper.gd` exists; map/event/menu presenters already wired; the V1 prompt asked for an **inventory**-family helper across `event_presenter.gd` and `reward_presenter.gd` — reward side still duplicates | `w1_02` | run `w1_02` — reword as "finish the presenter coverage with a small follow-up helper or extend `map_display_name_helper` to reward" |
| `1.4` | Texture loader consolidation | open | no shared helper found in `inventory_card_factory.gd` / `map_board_canvas.gd` / `scene_layout_helper.gd` | `w1_03` | run `w1_03` |
| `2.4` | Inventory panel post-render traversal hotspots | open | 26 traversal hits in `scenes/combat.gd` + `scenes/map_explore.gd` | `w2_05` | run `w2_05` |
| `2.3` | Scene theme/layout consolidation remainder | partial | 10 scenes already import `scene_layout_helper`/`temp_screen_theme`; 11 drifted functions from `SCN-F3`/`UI-F4`/`UI-F5` need individual confirmation | `w2_04` | run `w2_04` |
| `2.5` | Portrait density/theme/accessibility floor central home | open | no `Game/UI/portrait_*` / `density_*` file found; literals still scattered | `w2_06` | run `w2_06` |
| `2.1` | Narrow scene → AppBootstrap dependency | applied (so far) | zero `AppBootstrap.` callsites in `scenes/` | `w2_02` | re-check only if a new scene appears; otherwise retire |
| `2.2` | Application invalid-state/error handling standardization | open | no shared idiom landed across the five application files | `w2_03` | run `w2_03` |
| `2.6` | SceneRouter overlay contract hardening | partial | `scene_router.gd` already has `OVERLAY_OPEN_METHODS` / `OVERLAY_CLOSE_METHODS` dictionaries — halfway typed; the scene-side string callers are the remaining drift | `w2_07` | run `w2_07` |
| `3.1` | `map_board_composer_v2.gd` extraction preflight (report-only) | open | no preflight report exists; file still at 1251 lines | n/a (see big-file) | run V1 `3.1` as a fresh read-only report OR skip to big-file `MBC-0` |
| `3.2` | `inventory_actions.gd` + `support_interaction_state.gd` deep audit (report-only) | open | no deep audit file exists; `inventory_actions.gd` at 1087 (cap), `support_interaction_state.gd` at 976 (cap) | n/a (see big-file) | run V1 `3.2` as a fresh read-only report OR skip to big-file `INV-0` |
| `1.5` | Stale wrapper / dead alias cleanup | open | `game_flow_manager.gd:66 transition_to` and `save_service.gd:40 is_supported_save_state_now` still exist | `w1_01` | run `w1_01` |
| `5.1` | Compact UI accessibility polish | open | no evidence of a recent polish pass | `w4_01` | run `w4_01` |
| `5.2` | Tooling hygiene pass | open | no evidence of a recent pass | `w4_02` | run `w4_02` |

## CODEX_V2_BIG_FILE_MASTER_PROMPTS.md status

Source: `Docs/Promts/CODEX_V2_BIG_FILE_MASTER_PROMPTS.md`. Preflight reports (`*-0`) are report-only; split prompts (`*-1..*-4`) are extraction steps.

| V1 ID | Topic | Status | Evidence | Next action |
|---|---|---|---|---|
| `MBC-0` | `map_board_composer_v2` extraction preflight | open | no preflight artifact; file 1251 lines | run `MBC-0` (report-only) |
| `MBC-1` | Trail Geometry Helper extraction | open | no `Game/UI/trail_geometry_*` file | blocked by `MBC-0` |
| `MBC-2` | Node Placement Helper extraction | open | no placement helper file | blocked by `MBC-1` |
| `MBC-3` | Canopy / Forest Composition extraction | open | no canopy composition helper | blocked by `MBC-2` |
| `MBC-4` | Fallback Layout extraction (optional) | open | — | blocked by `MBC-3` |
| `INV-0` | `inventory_actions` extraction preflight | open | no preflight artifact; file 1087 lines (AT cap) | run `INV-0` (report-only) |
| `INV-1` | Equip / Unequip command family extraction | open | no split detected | blocked by `INV-0` |
| `INV-2` | Reorder / Swap command family extraction | open | — | blocked by `INV-1` |
| `INV-3` | Use / Consume command family extraction | open | — | blocked by `INV-2` |
| `INV-4` | Grant / Reward routing extraction (optional) | open | — | optional; after `INV-3` |
| `RSC-0` | `run_session_coordinator` extraction preflight | open | no preflight artifact; file 1016 lines | run `RSC-0` (report-only) |
| `RSC-1` | Movement Resolution extraction | open | no split detected | blocked by `RSC-0` |
| `RSC-2` | Roadside Interruption Continuation extraction | open | — (recent 04-20 commit touched roadside but did not split) | blocked by `RSC-1` |
| `RSC-3` | Pending Screen Orchestration extraction | open | — | blocked by `RSC-2` |
| `MRB-0` | `map_route_binding` extraction preflight | open | no preflight artifact; file 1060 lines (at cap) | run `MRB-0` (report-only) |
| `MRB-1` | Route Button Binding extraction | open | — | blocked by `MRB-0` |
| `MRB-2` | Marker State Binding extraction | open | — | blocked by `MRB-1` |
| `MRB-3` | Hover/Tooltip Binding extraction (optional) | open | — | optional; after `MRB-2` |
| `CMB-OPT` | `scenes/combat.gd` card-child traversal hotspot | open | traversal hits present | same work as Q2 `w2_05`; prefer `w2_05` first then re-check |
| `MEP-OPT` | `scenes/map_explore.gd` card-child traversal hotspot | open | traversal hits present | same as above |

## MAP_MASTER_PROMPTS.md status

Source: `Docs/Promts/MAP_MASTER_PROMPTS.md`.

| V1 ID | Topic | Status | Evidence | Next action |
|---|---|---|---|---|
| `1` | Combined redesign + theming audit | open (artifact missing) | Archive has plan/queue drafts; no fresh audit artifact under `Docs/` root or `Docs/Audit/` | run `Prompt 1` (report-only) unless you explicitly want to skip to already-locked decisions |
| `2A` | Display-name helper file | applied | `Game/UI/map_display_name_helper.gd` exists with the locked `Waymark / Ambush / Warden / Trail Event / Cache / Lockstone / Quiet Clearing / Wandering Pedlar / Travelling Smith / Waypost` map | — |
| `2B` | Presenter wiring | applied | `event_presenter.gd`, `main_menu_presenter.gd`, `map_explore_presenter.gd`, `transition_shell_presenter.gd` all call the helper | — |
| `3` | Topology refactor | applied | `map_runtime_graph_codec.gd` exists; `MapRuntimeState` uses it for realized-graph save payload and node-state payload | — (if you want a second-opinion audit, run `Prompt 3` in report-only mode) |
| `4` | Reconnect tuning | partial | topology refactor landed but no explicit `reconnect_param` surface found; behavior may already be tuned inline | run `Prompt 4` (audit, not rewrite) to verify if tuning is still needed |
| `5` | Placement tuning | partial | placement-related functions exist in composer, no explicit tuning knob surface found | run `Prompt 5` after `Prompt 4` |
| `6` | Composer path-family differentiation | applied | `map_board_composer_v2.gd` has `path_family`, `trail_texture_path_for_family`, `PATH_FAMILY_GENTLE_CURVE`, `PATH_FAMILY_SHORT_STRAIGHT` | — |
| `7` | Asset hook wiring | open | no `asset_hook` / `forest_fill_variant` / `path_variant_asset` hooks in UI; assets not wired beyond composer path textures | blocked on `AI_ASSET_ROADMAP_V2.md` asset production; run after approved filenames exist |
| `8` | Variation verification + residue cleanup | open | no variation verification artifact | blocked by `Prompt 7` |

## AI_ASSET_ROADMAP_V2.md status

Source: `Docs/Promts/AI_ASSET_ROADMAP_V2.md` (human guide, not a Codex prompt).

| Topic | Status | Evidence |
|---|---|---|
| AssetManifest plumbing | applied | `AssetManifest/asset_manifest.csv` (97 rows) plus 11 translation columns |
| Raw SourceArt pool | applied | `SourceArt/Edited/` contains bg masters (map/combat/menu/choice v002..v007) |
| Approved asset tree | partial | `Assets/UI/Map/Canopy`, `Assets/UI/Map/Clearings` exist; map path variants not yet populated |
| Forest fill language | open | no scene-side `forest_fill_*` consumer found; tied to `MAP_MASTER_PROMPTS.md` `Prompt 7` |
| FLUX/SDXL prompt templates | n/a | human-only content |

---

## Execution order (merged, one list to follow)

Follow this top-to-bottom. Each row either points to a Q2 prompt (`Docs/Promts/Q2_Plan/*.md`) or to a V1 prompt still living in the V1 files. Skip rows already `applied`.

**Pre-check between every run:** `git status --short` must be clean, or the dirty files must be inside the scope of the next prompt. If not, stop and commit first.

| # | Use prompt | Why this order |
|---|---|---|
| 1 | `Q2_Plan/w0_01_recreate_maintainability_audit.md` | fills `META-1 / B-1`; every later prompt references `MAINT-F*` |
| 2 | `Q2_Plan/w0_02_handoff_refresh.md` | removes the "no Docs/Audit folder" lie from HANDOFF |
| 3 | `Q2_Plan/w0_03_decision_log_q2_entries.md` | needs to land before W1-05..W1-09 apply the decisions |
| 4 | `Q2_Plan/w0_04_save_schema_pending_node_drift.md` | Fast-lane doc patch, independent |
| 5 | `Q2_Plan/w0_05_catalog_drift_register.md` | must land before `w1_04` validator guard |
| 6 | `Q2_Plan/w0_06_extraction_plan_duplicate_cleanup.md` | must land before `w3_01` extraction |
| 7 | `Q2_Plan/w1_01_prune_stale_wrappers.md` | closes V1 `1.5` |
| 8 | `Q2_Plan/w1_02_inventory_display_helper_extraction.md` | closes V1 `1.3` remainder (reward/event duplicate) |
| 9 | `Q2_Plan/w1_03_texture_loader_consolidation.md` | closes V1 `1.4` |
| 10 | `Q2_Plan/w1_04_validator_guard_expansion.md` | closes V1 `1.6`; relies on step 5 |
| 11 | `Q2_Plan/w1_05_hamlet_phase_split_note.md` | applies D-043 |
| 12 | `Q2_Plan/w1_06_inventory_cached_getter_exception_note.md` | applies D-044 |
| 13 | `Q2_Plan/w1_07_zz_prefix_convention_note.md` | applies D-045 |
| 14 | `Q2_Plan/w1_08_runstate_compat_freeze_note.md` | applies D-042 |
| 15 | `Q2_Plan/w1_09_gate_warden_retire.md` | applies D-046 |
| 16 | `Q2_Plan/w2_01_node_resolve_contract_alignment.md` | closes V1 B-2 / D-041 |
| 17 | `Q2_Plan/w2_02_app_bootstrap_raw_getter_narrowing.md` | keeps `AppBootstrap` clean; already applied — run only as verifier |
| 18 | `Q2_Plan/w2_03_application_error_handling_standardization.md` | closes V1 `2.2` |
| 19 | `Q2_Plan/w2_04_scene_theme_layout_finish.md` | closes V1 `2.3` remainder |
| 20 | `Q2_Plan/w2_05_inventory_panel_traversal_hotspots.md` | closes V1 `2.4`; also subsumes big-file `CMB-OPT` / `MEP-OPT` |
| 21 | `Q2_Plan/w2_06_portrait_density_constants.md` | closes V1 `2.5` |
| 22 | `Q2_Plan/w2_07_scene_router_overlay_hardening.md` | closes V1 `2.6` (half already landed) |
| 23 | `CODEX_V2_BIG_FILE_MASTER_PROMPTS.md` → `MBC-0` | start big-file extraction ONLY after W0..W2 are green; report-only first |
| 24 | `CODEX_V2_BIG_FILE_MASTER_PROMPTS.md` → `INV-0` | preflight |
| 25 | `CODEX_V2_BIG_FILE_MASTER_PROMPTS.md` → `RSC-0` | preflight |
| 26 | `CODEX_V2_BIG_FILE_MASTER_PROMPTS.md` → `MRB-0` | preflight |
| 27 | `CODEX_V2_BIG_FILE_MASTER_PROMPTS.md` → `MBC-1..MBC-3` | extraction steps, one at a time |
| 28 | `CODEX_V2_BIG_FILE_MASTER_PROMPTS.md` → `INV-1..INV-3` | extraction steps |
| 29 | `CODEX_V2_BIG_FILE_MASTER_PROMPTS.md` → `RSC-1..RSC-3` | extraction steps |
| 30 | `CODEX_V2_BIG_FILE_MASTER_PROMPTS.md` → `MRB-1..MRB-2` | extraction steps |
| 31 | `Q2_Plan/w3_01_map_runtime_state_extraction.md` | the big one; escalate-first |
| 32 | `MAP_MASTER_PROMPTS.md` → `Prompt 4` | reconnect tuning audit |
| 33 | `MAP_MASTER_PROMPTS.md` → `Prompt 5` | placement tuning audit |
| 34 | `MAP_MASTER_PROMPTS.md` → `Prompt 7` | asset hook wiring (only after approved asset filenames exist) |
| 35 | `MAP_MASTER_PROMPTS.md` → `Prompt 8` | variation verification + residue cleanup |
| 36 | `Q2_Plan/w4_01_accessibility_polish.md` | optional polish |
| 37 | `Q2_Plan/w4_02_tooling_hygiene.md` | optional polish |

Retirable prompts (do not run; they are superseded):
- V1 `2.1` — already applied (no `scenes/*.gd` calls `AppBootstrap.` directly).
- V1 `0.1` — superseded by `Q2_Plan/w0_01`; the Q2 prompt has the same scope with clearer constraints.
- V1 `3.1`, V1 `3.2` — superseded by the big-file preflights (`MBC-0`, `INV-0` + an equivalent for `support_interaction_state`; SIS isn't in big-file but the same report style works).
- V1 MAP `Prompt 1` — optional; `2A`, `2B`, `3`, `6` already landed so a fresh audit is nice-to-have, not required.

## Retire-from-repo checklist

After every row in the execution order above is `applied`, these files can safely move to `Docs/Promts/Archive/`:
- `Docs/Promts/CODEX_V2_MASTER_PROMPTS.md` — fully subsumed by `Q2_Plan/w0..w4`.
- `Docs/Promts/MAP_MASTER_PROMPTS.md` — keep only until `Prompt 7` and `Prompt 8` are done; then archive.
- `Docs/Promts/CODEX_V2_BIG_FILE_MASTER_PROMPTS.md` — keep until the full `MBC/INV/RSC/MRB` chains close.
- `Docs/Promts/AI_ASSET_ROADMAP_V2.md` — keep as a human-facing production guide; not a Codex prompt.

Do not delete the Archive subfolder; it is the history.

## How to mark progress

1. Run a prompt in Codex.
2. When it returns green, flip the row here from `open` / `partial` to `applied` with a one-line evidence note (file path or grep).
3. Move on to the next `open` row.
4. When a whole block (W0, W1, W2, etc.) is applied, also strike the matching line in `Docs/ROADMAP_2026Q2.md`.
