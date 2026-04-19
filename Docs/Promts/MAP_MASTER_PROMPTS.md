# MAP MASTER PROMPTS

Purpose: one practical copy-paste file for the current map pass.
Audience: the user starting fresh Codex chats and wanting small, single-step prompts without jumping between many prompt docs.
Scope: current map redesign, locked theming direction, local-asset handoff, and later extraction order.

Active files for this pass:
1. `Docs/Promts/MAP_MASTER_PROMPTS.md`
2. `Docs/Promts/AI_ASSET_ROADMAP_V2.md`
3. `Docs/Promts/MAP_RUNTIME_STATE_EXTRACTION_PLAN.md`

---

## 1. The Clean Order

Use this order:

1. Prompt `1` - combined redesign + theming audit
2. Prompt `2A` - display-name helper
3. Prompt `2B` - presenter wiring
4. Prompt `3` - topology refactor
5. Prompt `4` - reconnect tuning
6. Prompt `5` - placement tuning
7. Prompt `6` - composer path-family differentiation
8. local asset production in `AI_ASSET_ROADMAP_V2.md`
9. Prompt `7` - asset hook wiring
10. Prompt `8` - variation verification + residue cleanup
11. much later, separate chat: `MAP_RUNTIME_STATE_EXTRACTION_PLAN.md`

Rule:
- one prompt per fresh chat
- stop if a prompt goes unstable
- do not start extraction before the redesign pass closes

---

## 2. Locked Theming Decision

The current map pass uses this locked decision:

- Q1 = `C`
- Q2 = `C`
- Q3 = `C`

Meaning:
- mixed tone
- only `hamlet` varies
- surface scope is map board + transition shell only

Locked display-name map:

| Stable family ID | Player-facing display name |
|---|---|
| `start` | `Waymark` |
| `combat` | `Ambush` |
| `boss` | `Warden` |
| `event` | `Trail Event` |
| `reward` | `Cache` |
| `key` | `Lockstone` |
| `rest` | `Quiet Clearing` |
| `merchant` | `Wandering Pedlar` |
| `blacksmith` | `Travelling Smith` |
| `hamlet` | `Waypost` |

Hamlet personality variants:
- `pilgrim` -> `Pilgrim's Waypost`
- `frontier` -> `Frontier Waypost`
- `trade` -> `Trader's Waypost`

Stable family ID strings do NOT change. They are save-critical.

---

## Prompt 1 - Combined Redesign + Theming Audit

```text
Combined redesign + theming audit for simple_rpg map pass. No code changes in this chat.

Read first:
- AGENTS.md
- Docs/DOC_PRECEDENCE.md
- Docs/HANDOFF.md
- Docs/MAP_CONTRACT.md
- Docs/SOURCE_OF_TRUTH.md
- Docs/CONTENT_ARCHITECTURE_SPEC.md
- Docs/VISUAL_AUDIO_STYLE_GUIDE.md

Locked theming decision:
- start -> Waymark
- combat -> Ambush
- boss -> Warden
- event -> Trail Event
- reward -> Cache
- key -> Lockstone
- rest -> Quiet Clearing
- merchant -> Wandering Pedlar
- blacksmith -> Travelling Smith
- hamlet -> Waypost
- hamlet+pilgrim -> Pilgrim's Waypost
- hamlet+frontier -> Frontier Waypost
- hamlet+trade -> Trader's Waypost

Task:
Produce a short audit report covering the following, citing file:line for every claim:
1. Current controlled-scatter topology: confirm SCATTER_NODE_COUNT and SCATTER_START_BRANCH_COUNT in Game/RuntimeState/map_runtime_state.gd.
2. Current path families rendered by the composer. Confirm the four strings: short_straight, gentle_curve, wider_curve, outward_reconnecting_arc.
3. Whether a 4-direction opening is reachable without widening the 14-node envelope or breaking SCATTER_MAX_NODE_DEGREE.
4. Whether the safer "3 main + 1 short spur" fallback is implementable if pure 4-direction refactor would be too invasive.
5. Any code path that still relies on legacy slot-factor / fallback layout; flag if present.
6. Confirm planned event node and travel-triggered roadside encounter are distinct in code; cite the distinguishing files.
7. Where Trail Event currently maps from family id event.
8. Where hamlet_personality is derived.
9. Every presenter / shell file that renders a player-facing family label and would need the display-name helper wired in.
10. Any file outside Game/UI that currently renders a family label to the player; flag as ownership risk.
11. Any gameplay file where stable family IDs like combat / hamlet are compared; list them so the theming work does NOT touch them.

Do NOT write code. Do NOT touch any file.

Final response format:
- Findings (numbered 1-11)
- Recommended topology path: full 4-direction refactor OR 3 main + 1 short spur fallback OR stay as-is
- Recommended UI files for Prompt 2
- Anything that should block Prompt 2 or Prompt 3 from starting
```

---

## Prompt 2A - Display-Name Helper

```text
Display-name helper step for simple_rpg's map pass. Single presentation-only code step.

Read first:
- AGENTS.md
- Docs/DOC_PRECEDENCE.md
- Docs/HANDOFF.md
- Docs/MAP_CONTRACT.md
- Docs/SOURCE_OF_TRUTH.md
- Docs/CONTENT_ARCHITECTURE_SPEC.md
- Docs/VISUAL_AUDIO_STYLE_GUIDE.md

Locked display-name map:
- start -> Waymark
- combat -> Ambush
- boss -> Warden
- event -> Trail Event
- reward -> Cache
- key -> Lockstone
- rest -> Quiet Clearing
- merchant -> Wandering Pedlar
- blacksmith -> Travelling Smith
- hamlet -> Waypost
- hamlet+pilgrim -> Pilgrim's Waypost
- hamlet+frontier -> Frontier Waypost
- hamlet+trade -> Trader's Waypost

Task:
1. Add a new presentation-only helper under Game/UI that maps family_id plus optional hamlet_personality to the locked player-facing names above.
2. Do NOT wire presenters in this chat.

Hard rules:
- Game/UI only
- no save-shape change
- no new autoload
- no gameplay logic using display strings
- no change to any stable family ID string
- no change to MapRuntimeState or ContentDefinitions

Validation:
- py -3 Tools/validate_architecture_guards.py
- py -3 Tools/validate_content.py
- py -3 Tools/validate_assets.py
- powershell -NoProfile -ExecutionPolicy Bypass -File Tools/run_godot_full_suite.ps1
- if map scene, presenter, or composer changed materially: powershell -NoProfile -ExecutionPolicy Bypass -File Tools/run_godot_scene_isolation.ps1 -ScenePath scenes/map_explore.tscn

Final response format:
- What changed (files + 1-line reason each)
- What did not change
- Validation results
- Whether it is safe to continue to Prompt 2B

Stop at the end of this prompt.
```

---

## Prompt 2B - Presenter Wiring

```text
Presenter wiring step for simple_rpg's map pass. Single presentation-only code step.

Read first:
- AGENTS.md
- Docs/DOC_PRECEDENCE.md
- Docs/HANDOFF.md
- Docs/MAP_CONTRACT.md
- Docs/SOURCE_OF_TRUTH.md
- Docs/CONTENT_ARCHITECTURE_SPEC.md
- Docs/VISUAL_AUDIO_STYLE_GUIDE.md

Task:
1. Use the display-name helper added in Prompt 2A.
2. Wire it into every Game/UI presenter or shell file identified by Prompt 1 that currently shows family labels to the player.
3. Keep the surface scope limited to map board + transition shell only. Do NOT change combat titles in this chat.

Hard rules:
- Game/UI only
- no save-shape change
- no new autoload
- no gameplay logic using display strings
- no change to any stable family ID string
- no change to MapRuntimeState or ContentDefinitions

Validation:
- py -3 Tools/validate_architecture_guards.py
- py -3 Tools/validate_content.py
- py -3 Tools/validate_assets.py
- powershell -NoProfile -ExecutionPolicy Bypass -File Tools/run_godot_full_suite.ps1
- if map scene, presenter, or composer changed materially: powershell -NoProfile -ExecutionPolicy Bypass -File Tools/run_godot_scene_isolation.ps1 -ScenePath scenes/map_explore.tscn

Final response format:
- What changed (files + 1-line reason each)
- What did not change
- Validation results
- Whether it is safe to continue to Prompt 3

Stop at the end of this prompt.
```

---

## Prompt 3 - Topology Refactor

```text
Topology refactor step for simple_rpg's map pass. Single code-touching step.

Read first:
- AGENTS.md
- Docs/DOC_PRECEDENCE.md
- Docs/HANDOFF.md
- Docs/MAP_CONTRACT.md
- Docs/SOURCE_OF_TRUTH.md
- Docs/CONTENT_ARCHITECTURE_SPEC.md
- Docs/VISUAL_AUDIO_STYLE_GUIDE.md

Task:
Using the recommendation that came out of Prompt 1, apply exactly ONE of the following:
- A) full 4-direction opening refactor
- B) safer 3 main + 1 short spur fallback
Pick exactly one. State which one at the top of the response. If Prompt 1 recommended stay as-is, stop and report instead of editing code.

Hard rules:
- this chat touches only the topology step
- no save-shape change
- no owner move out of MapRuntimeState
- stable family IDs do not change
- current 14-node envelope stays
- planned map event stays distinct from travel-triggered roadside encounter
- do not revive legacy slot-factor / fallback layout as a first-class system
- if anything goes unstable, stop and report

Validation:
- py -3 Tools/validate_architecture_guards.py
- py -3 Tools/validate_content.py
- py -3 Tools/validate_assets.py
- powershell -NoProfile -ExecutionPolicy Bypass -File Tools/run_godot_full_suite.ps1
- powershell -NoProfile -ExecutionPolicy Bypass -File Tools/run_godot_scene_isolation.ps1 -ScenePath scenes/map_explore.tscn

Final response format:
- Path chosen
- What changed (files + 1-line reason each)
- What did not change
- Validation results
- Whether it is safe to continue to Prompt 4

Stop at the end of this prompt.
```

---

## Prompt 4 - Reconnect Tuning

```text
Reconnect tuning step for simple_rpg's map pass. Single code-touching step.

Read first:
- AGENTS.md
- Docs/DOC_PRECEDENCE.md
- Docs/HANDOFF.md
- Docs/MAP_CONTRACT.md
- Docs/SOURCE_OF_TRUTH.md
- Docs/CONTENT_ARCHITECTURE_SPEC.md
- Docs/VISUAL_AUDIO_STYLE_GUIDE.md

Task:
Tune late cross-branch reconnect generation so each run shows at least one visible outer reconnect, without breaking degree or connectivity invariants.
Touch only the reconnect / arc generation block in Game/RuntimeState/map_runtime_state.gd and the minimum needed composer / validator bridge for it to render.

Hard rules:
- no save-shape change
- no owner move out of MapRuntimeState
- stable family IDs do not change
- 14-node envelope stays
- keep the reconnect-count change minimal
- no placement logic changes in this chat
- no composer path-family changes in this chat
- if any step becomes unstable, stop and report

Validation:
- py -3 Tools/validate_architecture_guards.py
- py -3 Tools/validate_content.py
- py -3 Tools/validate_assets.py
- powershell -NoProfile -ExecutionPolicy Bypass -File Tools/run_godot_full_suite.ps1
- powershell -NoProfile -ExecutionPolicy Bypass -File Tools/run_godot_scene_isolation.ps1 -ScenePath scenes/map_explore.tscn

Final response format:
- What changed
- What did not change
- Validation results
- Whether it is safe to continue to Prompt 5

Stop at the end of this prompt.
```

---

## Prompt 5 - Placement Tuning

```text
Placement tuning step for simple_rpg's map pass. Single code-touching step.

Read first:
- AGENTS.md
- Docs/DOC_PRECEDENCE.md
- Docs/HANDOFF.md
- Docs/MAP_CONTRACT.md
- Docs/SOURCE_OF_TRUTH.md
- Docs/CONTENT_ARCHITECTURE_SPEC.md
- Docs/VISUAL_AUDIO_STYLE_GUIDE.md

Task:
Adjust family placement against the new topology so the stage guarantee floor still holds:
- 1 start
- 6 combat
- 1 event
- 1 reward
- 1 hamlet
- 2 support
- 1 key
- 1 boss
Touch only role-reservation, family-assignment, or scoring code. Do NOT touch reconnect generation or composer path rendering.

Hard rules:
- no save-shape change
- no owner move
- stable family IDs do not change
- current 14-node envelope stays
- do not loosen the guarantee floor to make placement easier
- planned event stays distinct from roadside encounter
- if any step becomes unstable, stop and report

Validation:
- py -3 Tools/validate_architecture_guards.py
- py -3 Tools/validate_content.py
- py -3 Tools/validate_assets.py
- powershell -NoProfile -ExecutionPolicy Bypass -File Tools/run_godot_full_suite.ps1
- powershell -NoProfile -ExecutionPolicy Bypass -File Tools/run_godot_scene_isolation.ps1 -ScenePath scenes/map_explore.tscn

Final response format:
- What changed
- What did not change
- Validation results
- Whether it is safe to continue to Prompt 6

Stop at the end of this prompt.
```

---

## Prompt 6 - Composer Path-Family Differentiation

```text
Composer path-family differentiation step for simple_rpg's map pass. Single code-touching step.

Read first:
- AGENTS.md
- Docs/DOC_PRECEDENCE.md
- Docs/HANDOFF.md
- Docs/MAP_CONTRACT.md
- Docs/SOURCE_OF_TRUTH.md
- Docs/CONTENT_ARCHITECTURE_SPEC.md
- Docs/VISUAL_AUDIO_STYLE_GUIDE.md
- Docs/MAP_COMPOSER_V2_DESIGN.md

Task:
Strengthen visible differentiation between the four existing path families rendered by the composer:
- short_straight
- gentle_curve
- wider_curve
- outward_reconnecting_arc
Change only composer-side path-family selection, weighting, or asset mapping so each family is more visually distinct without changing runtime ownership or save shape.

Hard rules:
- no save-shape change
- no owner move
- map truth stays in MapRuntimeState
- stable family IDs do not change
- no new path-family string in this chat
- no gameplay logic change
- if any step becomes unstable, stop and report

Validation:
- py -3 Tools/validate_architecture_guards.py
- py -3 Tools/validate_content.py
- py -3 Tools/validate_assets.py
- powershell -NoProfile -ExecutionPolicy Bypass -File Tools/run_godot_full_suite.ps1
- powershell -NoProfile -ExecutionPolicy Bypass -File Tools/run_godot_scene_isolation.ps1 -ScenePath scenes/map_explore.tscn

Final response format:
- What changed
- What did not change
- Validation results
- Whether it is safe to pause code work here and switch to local asset production

Stop at the end of this prompt.
```

---

## 3. Then Do Local Assets

After Prompt 6 is green:

1. open `Docs/Promts/AI_ASSET_ROADMAP_V2.md`
2. generate assets locally, not in Codex
3. prioritize:
   - `ground`
   - `prop`
   - `landmark`
4. choose final filenames yourself
5. then come back to Codex with the filenames and run Prompt 7

Local generation folder:
- `SourceArt/Generated/Map`

Cleaned / edited masters:
- `SourceArt/Edited`

Runtime export target folders:
- `Assets/UI/Map/Ground`
- `Assets/UI/Map/Props`
- `Assets/UI/Map/Landmarks`

If these folders do not exist yet, create them manually while exporting or let Prompt 7 create them before the final copy.

---

## Prompt 7 - Asset Hook Wiring

Before pasting, replace every `<FILENAME>` placeholder below with real filenames you exported.

If you have a large batch, run Prompt 7 in small groups by family instead of wiring everything at once.

```text
Asset hook wiring step for simple_rpg's map pass. Single code-touching step.

Read first:
- AGENTS.md
- Docs/DOC_PRECEDENCE.md
- Docs/HANDOFF.md
- Docs/MAP_CONTRACT.md
- Docs/SOURCE_OF_TRUTH.md
- Docs/ASSET_PIPELINE.md
- Docs/ASSET_LICENSE_POLICY.md

Approved asset filenames:
- <FILENAME e.g. Assets/UI/Map/Ground/ui_map_v2_ground_forest_floor_a.png>
- <FILENAME e.g. Assets/UI/Map/Props/ui_map_v2_prop_root_cluster_a.png>
- <FILENAME e.g. Assets/UI/Map/Landmarks/ui_map_v2_landmark_waystone_a.png>

Task:
1. Create any missing runtime subfolders under Assets/UI/Map needed by the filenames above.
2. Wire each approved filename into the appropriate runtime-facing map asset hook.
3. Verify the board renders with the new ground, prop, and landmark families.
4. Update or add manifest rows in AssetManifest/asset_manifest.csv with correct provenance.

Hard rules:
- no asset generation in this chat
- no save-shape change
- no new owner surface
- no extraction
- no change to MapRuntimeState ownership
- no change to stable family IDs

Validation:
- py -3 Tools/validate_architecture_guards.py
- py -3 Tools/validate_content.py
- py -3 Tools/validate_assets.py
- powershell -NoProfile -ExecutionPolicy Bypass -File Tools/run_godot_full_suite.ps1
- powershell -NoProfile -ExecutionPolicy Bypass -File Tools/run_godot_scene_isolation.ps1 -ScenePath scenes/map_explore.tscn

Final response format:
- Files changed
- New subfolders created
- Manifest rows added or changed
- Validation results
- Whether the board reads as ground + props + landmarks together

Stop at the end of this prompt.
```

---

## Prompt 8 - Variation Verification + Residue Cleanup

```text
Closeout step for simple_rpg's map pass. Single code-touching step.

Read first:
- AGENTS.md
- Docs/DOC_PRECEDENCE.md
- Docs/HANDOFF.md
- Docs/MAP_CONTRACT.md
- Docs/SOURCE_OF_TRUTH.md

Task:
1. Verify per-run visual variation across 3 different seeds. If any seed still produces a flat same-looking board, report it and stop.
2. Clean residue from the redesign, theming, and asset-hook passes: dead code, unused constants, obsolete comments.
3. Sync truthful docs only if needed: HANDOFF.md and MAP_CONTRACT.md if topology or counts actually changed.

Do NOT start extraction in this chat.

Hard rules:
- no save-shape change
- no owner move
- no new autoload
- doc edits are truthful-only

Validation:
- py -3 Tools/validate_architecture_guards.py
- py -3 Tools/validate_content.py
- py -3 Tools/validate_assets.py
- powershell -NoProfile -ExecutionPolicy Bypass -File Tools/run_godot_full_suite.ps1

Final response format:
- Per-seed variation findings
- Residue fixes
- Doc edits
- Validation results
- Whether extraction is still worth running now

Stop at the end of this prompt.
```

---

## 4. Extraction Is A Separate Later Job

Only if the map pass is complete and the hotspot file still needs slimming:

1. open `Docs/Promts/MAP_RUNTIME_STATE_EXTRACTION_PLAN.md`
2. re-measure `map_runtime_state.gd` line count and function count first
3. use the extraction plan in a separate chat
4. do not mix extraction with redesign or asset-hook work

---

## 5. The Only File Order You Need

Use files in this order:

1. `MAP_MASTER_PROMPTS.md` for Prompts 1, 2A, 2B, 3, 4, 5, 6
2. `AI_ASSET_ROADMAP_V2.md` for local asset production
3. `MAP_MASTER_PROMPTS.md` again for Prompts 7 -> 8
4. `MAP_RUNTIME_STATE_EXTRACTION_PLAN.md` much later if still needed

That is the whole active structure.
