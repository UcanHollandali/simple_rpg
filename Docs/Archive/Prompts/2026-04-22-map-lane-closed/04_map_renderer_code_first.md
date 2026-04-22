# Prompt 04 - Map Renderer Code-First Direction

Use this prompt pack after Prompt 03 Parts A-F are closed green and while Part G remains blocked.

This pack does not reopen Prompt 03 Part G.
This pack supersedes only the "terrain asset hookup is the immediate next wave" framing around Prompt 03 Part G. It does not clear the existing asset-approval blocker. Code-first terrain presentation takes precedence, and AI asset production is scoped down to semantic icon / prop / item / portrait surfaces.

Read first:
- `AGENTS.md`
- `Docs/DOC_PRECEDENCE.md`
- `Docs/HANDOFF.md`
- `Docs/ROADMAP.md`
- `Docs/MAP_CONTRACT.md`
- `Docs/MAP_COMPOSER_V2_ASSET_REQUIREMENTS.md`

## Goal

Formalize the code-first map renderer direction, close the asset-first blocker in a stable way, polish the live procedural map presentation so the board reads acceptably even when optional generated terrain stamps are absent or their loads return null, and scope the next AI asset wave to semantic surfaces only.

## Direction Statement

- Map Composer V2 presentation's structural truth owner is code.
- Generated art is optional polish for semantic single-object surfaces (icons, node props, items, weapons, shields, armor, belts, consumables, passives, quest items, shield attachments, enemy busts, portraits, walker frames), not for terrain transition / blending.
- Ground, trail, clearing, canopy filler, junction patch, and forest transition surfaces are procedural.
- Existing runtime-approved map textures under `Assets/UI/Map/` stay as optional polish stamps. The renderer must render acceptably when those optional stamp loads return null. If a full no-stamp screenshot lane is not available, report that validation gap instead of claiming stronger proof than the workspace supports.
- `SourceArt/Generated/new/` stays a candidate pack. No file in it is auto-approved as a runtime asset.

## Target Composition Intent

The long-term visual target for the random generated map is a three-layer readable forest pocket:

1. Center start anchor with outward branching routes
2. Procedural roads with warm lit tone against a darker forest mass, node clearings that read as local pockets rather than UI buttons, and route emphasis that guides without drowning the board
3. Semantic node identity through small prop-style icons on each node (combat, reward, key, boss, rest, merchant, blacksmith, event, hamlet, start)
4. Procedural decor variation along path edges and in canopy gaps so the board reads as a living forest rather than a static diagram

This target is produced by the existing architecture: seed-driven controlled-scatter generates a different topology per run, the procedural renderer paints the board, and semantic single-object assets carry node identity and prop decoration. It is not produced by a single authored stage illustration. No part of this pack asks for a baked full-stage art export.

A single composition reference image is pinned in the semantic icon wave plan in Part D so future asset production can match the visual language without requiring a baked terrain asset pipeline.

## Part Execution Rule

- Run one part at a time.
- Do not advance to the next part until the current part is green with validation, or explicitly blocked with `escalate first`.
- Do not combine parts into a single patch.

## Order

### 0. Preflight + Doc Sync

Before any presentation patch:
- re-read the three authority docs listed above
- confirm that the last-verified validation checkpoint in `Docs/HANDOFF.md` still matches the workspace
- do not change save shape, flow, owner meaning, or graph truth

### 1. Direction Doc Closeout

- Retarget `Docs/MAP_COMPOSER_V2_ASSET_REQUIREMENTS.md` so that ground / trail / clearing / canopy families are described as optional polish, not as Priority 1 blockers.
- Move node identity icon completion (`icon_map_combat`, `icon_map_key`, `icon_map_boss`) into Priority 1 explicitly.
- Update `Docs/HANDOFF.md` and `Docs/ROADMAP.md` so the asset-hook blocker reads as deferred rather than next-up, and so the active next step is the procedural renderer polish pass.
- Do not change any authority wording in `Docs/MAP_CONTRACT.md`, `Docs/ASSET_PIPELINE.md`, `Docs/ASSET_LICENSE_POLICY.md`, or `Docs/VISUAL_AUDIO_STYLE_GUIDE.md`.

### 2. Procedural Renderer Polish

- File scope: `Game/UI/map_board_canvas.gd` and `Game/UI/map_board_style.gd` only.
- Target: procedural-first readability with optional terrain stamps treated as non-required polish.
- Tuning surface:
  - road widths, shadow widths, highlight intensity, emphasis scaling
  - atmosphere layer count and alpha
  - canopy / decor forest shape alpha scale and variation
  - clearing radius / rim / fill tuning
  - current-node marker emphasis vs node-plate readability
- Extract magic numbers from `map_board_canvas.gd` into named constants inside `map_board_style.gd` so future tuning does not require canvas edits.
- Keep all existing texture hook paths and null-safe loads intact. Do not remove optional stamp behavior; just make sure the procedural path below it is self-sufficient.

### 3. Visual Review

- Capture portrait screenshots of `scenes/map_explore.tscn` before and after Part 2.
- Compare on: road contrast/thickness, current-route dominance, node state differentiation, background blob suppression, clearing grounding, current-marker vs node-plate balance.
- If the procedural map is not acceptable without relying on optional terrain stamps, open a narrow follow-up tuning pass in the same file scope. Do not escalate into composer / route binding / runtime state.
- If the workspace does not provide a safe automated no-stamp capture lane, report that as remaining manual verification rather than faking zero-stamp proof.

### 4. Semantic Icon Completion Scope Plan

- Do not generate assets in this prompt pack.
- Produce a written scope plan for the next AI asset wave with three tiers:
  1. node identity icons first (`icon_map_combat`, `icon_map_key`, `icon_map_boss`) because they currently fall back to generic action / intent icons
  2. optional node props / landmark emphasis (rest camp, merchant stall, blacksmith anvil, boss gate marker) as later polish
  3. item / weapon / shield / armor / belt / consumable / passive / quest-item / shield-attachment / enemy bust / portrait / walker-frame extensions as separate later passes
- Asset hookup work still stays blocked by the `ASSET_PIPELINE.md` approval + manifest row contract.

## Asset Blocker Rule

- No generated asset is approved, moved, renamed, converted, imported, or hooked in this pack.
- No `SourceArt/Generated/` file is promoted into `Assets/` in this pack.
- No `UiAssetPaths` constant is added or repointed in this pack.
- Existing live runtime textures under `Assets/UI/Map/` stay as-is.
- If any existing generated asset is discovered inside runtime-facing folders without an approved manifest row, report it; do not remove it in this pack.
- The correct outcome for the asset scope plan is allowed to be a documented queue, not a hookup patch.

## Guardrails

- No save-schema shape change.
- No owner move.
- No flow state change.
- No new command family or event family.
- No scene/core boundary change.
- No graph-truth change.
- No visibility-filtering semantic change.
- No route-motion semantic change.
- No edit to `MapBoardComposerV2`, `map_board_layout_solver.gd`, `MapRouteBinding`, `map_route_layout_helper.gd`, `map_route_motion_helper.gd`, `MapRuntimeState`, `map_scatter_graph_tools.gd`, `map_runtime_graph_codec.gd`, `ui_asset_paths.gd`, or any `scenes/*.gd` file in Part 2.
- No autoload addition.
- No `AppBootstrap` public-surface widening.
- No string-based owner call reintroduction on typed-reflection-locked files.

## Validation

- `py -3 Tools/validate_architecture_guards.py`
- `py -3 Tools/validate_assets.py`
- `powershell -NoProfile -ExecutionPolicy Bypass -File Tools/run_godot_scene_isolation.ps1 -ScenePath scenes/map_explore.tscn`
- `powershell -NoProfile -ExecutionPolicy Bypass -File Tools/run_godot_full_suite.ps1`
- targeted: `Tests/test_map_board_canvas.gd` must stay green; its composition dict key contract (`visible_edges`, `visible_nodes`, `forest_shapes`, `trail_texture_path`, `clearing_decal_texture_path`, `node_plate_texture_path`, `state_semantic`, `is_current`, `is_history`, `clearing_radius`, `world_position`, `side_quest_highlight_*`) must not change.
- portrait capture via `Tools/scene_portrait_capture.gd` before/after Part 2.

## Done Criteria

- `Docs/MAP_COMPOSER_V2_ASSET_REQUIREMENTS.md`, `Docs/HANDOFF.md`, and `Docs/ROADMAP.md` reflect the code-first direction and the deferred asset-hook blocker.
- `Game/UI/map_board_canvas.gd` and `Game/UI/map_board_style.gd` render an acceptable map with zero generated terrain assets.
- Portrait screenshots document the visual improvement.
- A written semantic icon wave plan exists and is referenced from the roadmap.
- Prompt 03 Part G is explicitly marked as deferred / superseded in the roadmap, not reopened.
- All validators pass and the full suite stays green.

## Copy/Paste Parts

### Part A - Direction Doc Closeout

```text
Apply only Prompt 04 Part A.

Scope:
- Retarget Docs/MAP_COMPOSER_V2_ASSET_REQUIREMENTS.md so ground / trail / clearing / canopy / filler / junction / forest-transition families are described as optional polish, not Priority 1 blockers.
- Move node identity icon completion (icon_map_combat, icon_map_key, icon_map_boss) into Priority 1.
- Update Docs/HANDOFF.md: record the code-first direction, mark the asset-hook step as deferred, describe the next active step as the procedural renderer polish pass.
- Update Docs/ROADMAP.md: record that Prompt 03 Part G is superseded by Prompt 04 direction; add Prompt 04 to the active queue.
- Preserve authority tone: this is a production/reference companion update, not a gameplay or technical rule change.

Do not:
- edit Docs/MAP_CONTRACT.md, Docs/ASSET_PIPELINE.md, Docs/ASSET_LICENSE_POLICY.md, or Docs/VISUAL_AUDIO_STYLE_GUIDE.md
- reopen Prompt 03 Part G
- approve, move, rename, convert, import, or hook any SourceArt/Generated asset
- add or repoint any UiAssetPaths constant
- change save shape, flow, owner meaning, or graph truth

Validation:
- verify markdown internal links resolve
- confirm Docs/HANDOFF.md still passes doc-level consistency with Docs/ROADMAP.md
- report every file touched, exact before/after paragraphs for changed doc sections

Report:
- list of files changed
- for each doc, the specific paragraphs or sections rewritten
- whether any downstream reference needs a follow-up doc update
```

### Part B - Procedural Renderer Polish

```text
Apply only Prompt 04 Part B.

Scope:
- File scope limited to Game/UI/map_board_canvas.gd and Game/UI/map_board_style.gd.
- Goal: the random generated map must render acceptably with zero generated terrain assets.

Specific tuning targets (do not treat as a rigid recipe; treat as priorities):
1. Road rendering
   - reduce road base and shadow stroke widths; keep the layered shadow + base + highlight model
   - reduce highlight alpha and value so current/active routes stay readable without overpowering the board
   - reduce contrast of history / cleared / seen routes
   - keep trail texture stamps optional; the procedural polyline must read well on its own
   - do not modify edge point arrays, layout_edges, or any composer-produced geometry
   - if roads visually punch through node centers, solve it with draw order (clearing plate / rim on top) or a canvas-local point-trim that leaves the frozen layout untouched
2. Atmosphere
   - reduce total atmosphere stack alpha so node/path readability wins over mood
   - keep dark forest wayfinder mood but lower the dominance of central spotlight / beam / guide arcs
3. Forest shapes
   - apply a canvas-local canopy alpha scale so large canopy blobs stop burying nodes and edges
   - add light procedural silhouette variation so canopy does not feel repetitive (irregular polygon or multi-blob) while keeping the circle fallback path
   - keep decor shapes subtle
4. Clearing
   - ensure every node reads a clean local pocket procedurally without requiring clearing_decal or node_plate textures
   - tune clearing radius multipliers, rim color, fill opacity for open / current / resolved / locked / boss / key states
5. Current marker vs node plate
   - current-marker emphasis should complement the node plate, not overpower it
   - keep state differentiation (reachable / current / resolved / locked / boss / key) clearly readable

Centralize tuning:
- extract magic numbers currently inline in map_board_canvas.gd (road widths, shadow widths, atmosphere radius multipliers and alphas, canopy alpha scale, clearing radius multipliers, current-marker emphasis) into named constants inside Game/UI/map_board_style.gd
- prefer named constants so future tuning does not require canvas edits

Do not:
- remove optional texture stamp behavior; keep null-safe load guards and the existing optional stamp paths intact
- change the composition dict key contract consumed by map_board_canvas.gd
- touch MapBoardComposerV2, map_board_layout_solver.gd, MapRouteBinding, map_route_layout_helper.gd, map_route_motion_helper.gd, MapRuntimeState, map_scatter_graph_tools.gd, map_runtime_graph_codec.gd, ui_asset_paths.gd, or any scenes/*.gd file
- add, rename, approve, move, or hook any asset
- add or repoint UiAssetPaths constants
- widen scope into layout, composer, route, runtime state, save, or flow
- regress test_map_board_canvas.gd

Validation:
- validate_architecture_guards
- Tests/test_map_board_canvas.gd stays green
- targeted map composer / presenter / route / canvas tests remain green
- map scene isolation on scenes/map_explore.tscn
- full suite before closing the part

Report:
- files changed with line counts
- every named constant introduced and its before/after value
- every magic number removed from canvas in favor of a style constant
- before/after visual description, including anything left unresolved
- explicit confirmation that no composer / route / runtime / asset hook was touched
```

### Part C - Visual Review

```text
Apply only Prompt 04 Part C.

Scope:
- Use the existing portrait screenshot tooling (Tools/scene_portrait_capture.gd via the repo's Godot runner) to capture before/after images of scenes/map_explore.tscn at the documented portrait target.
- Capture at minimum:
  - stage start with only start + initial adjacency revealed
  - a mid-progression state with some resolved nodes
  - a late state with key / boss visible
- Review the captures against these checkpoints:
  1. roads readable but not dominant
  2. current route clear without drowning the rest of the board
  3. node states distinguishable (reachable / current / resolved / locked / boss / key / combat)
  4. atmosphere supports the route instead of competing with it
  5. clearings read as local pockets, not UI buttons
  6. current-marker does not overpower its own node plate
  7. map looks acceptable with zero generated terrain assets

If a checkpoint fails:
- open a narrow follow-up tuning pass, staying inside Game/UI/map_board_canvas.gd and Game/UI/map_board_style.gd only
- do not widen scope into composer / route / runtime / save / flow
- do not escalate into asset production

Do not:
- approve any SourceArt/Generated asset
- hook any new texture
- modify test baseline expectations to paper over visual regressions

Validation:
- produce screenshots under Tools/_captures/ or the repo's standard capture lane
- report a checklist with pass/fail per checkpoint
- re-run validate_architecture_guards, targeted map tests, map scene isolation, and the full suite if any code was touched during this part

Report:
- list of captured files and scenes
- pass/fail per checkpoint with 1-2 line reasoning
- list of any follow-up tuning applied and the before/after constant values
- explicit confirmation that scope did not leave map_board_canvas.gd and map_board_style.gd
```

### Part D - Semantic Icon Wave Scope Plan

```text
Apply only Prompt 04 Part D.

Scope:
- Produce a written scope plan document for the next AI asset wave, scoped to semantic single-object surfaces only.
- Save the plan as Docs/ASSET_WAVE_SEMANTIC_SCOPE.md (reference-only, production-authority companion to ASSET_BACKLOG.md).
- The plan must open with a Composition Reference section that describes the target visual language so future AI asset production has a single pinned aesthetic target:
  - warm lit earthen paths radiating from a center start anchor
  - small lantern / prop-based landmark on the center node
  - semantic node identity carried by prop-style icons, not flat UI glyphs (chest for reward, key chest for key, sword altar for boss, lantern shrine for start, question-mark box for event, small camp for rest, stall for merchant, anvil for blacksmith, settlement marker for hamlet, combat token for combat)
  - dense forest canopy framing the pocket, not overtaking it
  - procedural decor (rocks, stumps, lanterns, small bushes) scattered along path edges and in canopy gaps
  - mobile portrait-readable small-screen contrast
  - no baked full-stage art; no single authored board image; no terrain transition pipeline
- Explicitly state in the Composition Reference section that this visual language is reached through the existing architecture:
  - seed-driven controlled-scatter produces a different topology per run
  - procedural code draws roads, clearings, atmosphere, canopy massing, and decor variation
  - semantic single-object art carries node identity and optional prop decoration
- The plan must cover three tiers:
  Tier 1 - Node identity icon completion:
    - icon_map_combat (currently falls back to icon_attack)
    - icon_map_key (currently falls back to icon_confirm)
    - icon_map_boss (currently falls back to icon_enemy_intent_heavy)
  Tier 2 - Optional node props and landmark emphasis:
    - rest camp prop (matches the small camp composition read)
    - merchant stall prop
    - blacksmith anvil prop
    - boss gate marker / sword altar prop
    - optional key shrine prop
    - optional start lantern shrine prop
    - optional event question box prop
    - optional reward chest prop
  Tier 3 - Item and character extensions, grouped by family:
    - weapons, shields, armor, belts
    - consumables, passives, quest items
    - shield attachments
    - enemy busts, enemy tokens
    - player bust, NPC portraits
    - walker frame extensions
- Each tier must list:
  - expected runtime filename pattern under Assets/Icons/ or Assets/UI/Map/ or Assets/Enemies/ as appropriate
  - whether the current repo already ships a generic fallback (and which fallback), so approval clearly replaces a weaker identity
  - whether runtime hookup would require a UiAssetPaths change
  - approval gate: ASSET_PIPELINE.md manifest row + license/provenance requirement
- The plan must also include a Non-Goals section that explicitly rules out:
  - baked full-stage terrain art
  - single authored board images
  - ground / trail strip / clearing underlay / filler / junction / transition art
  - any art whose correctness depends on neighboring art blending
- Cross-reference Docs/ASSET_BACKLOG.md and Docs/VISUAL_AUDIO_STYLE_GUIDE.md without duplicating authority wording.
- Do not generate any art assets in this part.
- Do not approve, move, rename, convert, import, or hook any existing generated file.

Do not:
- promote this new doc above reference-only authority
- override ASSET_PIPELINE.md or ASSET_LICENSE_POLICY.md
- modify MAP_CONTRACT.md
- embed a binary reference image inside the repo; if a reference image is available, link or describe it in the doc rather than committing the image into Docs/

Validation:
- verify markdown internal links resolve
- confirm the new doc is listed as reference-only in Docs/DOC_PRECEDENCE.md under "Context and History" if added there, or otherwise declared clearly as production/reference companion inside its own Status section

Report:
- the final doc path
- a summary of the three tiers
- the Composition Reference section summary
- the Non-Goals section summary
- which runtime filenames would touch UiAssetPaths
- explicit confirmation that no asset was produced, approved, or hooked
- explicit confirmation that no baked full-stage art path was introduced
```

### Part E - Closeout And Handoff Refresh

```text
Apply only Prompt 04 Part E.

Scope:
- Update Docs/HANDOFF.md to reflect:
  - Prompt 04 Parts A-D outcomes
  - the new current step (playtest / telemetry preparation or whatever the next phase entry is per ROADMAP.md)
  - the asset-hook step remains blocked and is now scoped to semantic icon wave planning, not terrain-transition asset production
- Update Docs/ROADMAP.md to:
  - mark Prompt 04 closed (if Parts A-D are green) or explicitly mark the open part
  - keep Phase D (Playtest / Telemetry) as the next active phase if all parts closed green
  - explicitly mark Prompt 03 Part G as superseded by Prompt 04 direction
- Leave Docs/MAP_CONTRACT.md, Docs/ASSET_PIPELINE.md, Docs/ASSET_LICENSE_POLICY.md, and Docs/VISUAL_AUDIO_STYLE_GUIDE.md unchanged.

Do not:
- reopen Prompt 03
- declare asset wave unblocked unless ASSET_PIPELINE.md and ASSET_LICENSE_POLICY.md gates are explicitly satisfied

Validation:
- verify all internal doc links resolve
- run validate_architecture_guards
- run the full suite once to confirm no repo drift during doc updates

Report:
- files changed
- roadmap state before/after
- any follow-up work explicitly deferred to later phases
```

## Success Condition

- The project visibly runs on the code-first direction.
- The random generated map reads acceptably with zero generated terrain assets.
- Docs, roadmap, and handoff tell the same story as the live repo state.
- The next AI asset effort is scoped to semantic icon / prop / item / portrait work, not terrain transition art.
- Hotspot files, save shape, flow, and graph truth remain unchanged.
