# MAP VISUAL OWNERSHIP Audit and Runtime Test Report

Last updated: 2026-04-23 (Prompt 13 audit baseline retained; archived visual-rule sync preserved as historical reference)

This is a reference-only audit.
It does not approve assets, hook assets, change gameplay logic, change save shape, or reopen terrain hookup.
It remains a historical ownership/evidence report, not an authority doc and not a queue surface.

## Archived Visual-Rule Sync (Historical)

This report still matters as ownership/evidence history, but it is no longer sufficient by itself to describe the active wave target.

Historical stronger map target from the now-archived Prompt `43-62` wave:

- road network first
- landmark pockets second
- full board usage
- small-world traversal feel
- candidate asset spike only after structure is green

The archived sync used checked-in repo captures for this reference pass.
The earlier audit fallback was not needed because a checked-in reference set exists.
No extra user-provided reference images were used in the current chat beyond repo state.

Exact checked-in captures reviewed for the archived sync:

- `export/portrait_review/map_explore_1080x1920.png`
- `export/portrait_review/prompt42_full_board_footprint_20260423/after/seed11_late_1080x1920.png`
- `export/portrait_review/prompt42_full_board_footprint_20260423/after/seed29_late_1080x1920.png`
- `export/portrait_review/prompt42_full_board_footprint_20260423/after/seed41_late_1080x1920.png`
- `export/portrait_review/prompt20_board_path_hierarchy_20260423/after/map_explore_1080x1920.png`
- `export/portrait_review/prompt20_board_path_hierarchy_20260423/after/seed11_late_1080x1920.png`
- `export/portrait_review/prompt20_ground_filler_restraint_20260423/after/map_explore_1080x1920.png`
- `export/portrait_review/prompt40_final_reaudit_20260423/map_explore_1080x1920.png`

The archived sync extracted the following continuation rules from those captures:

- roads must become the first-read structure rather than secondary strokes between node discs
- roads must help define landmark pockets instead of merely connecting circles
- landmark pockets must become the primary node-identity surface; icon/plate layers are confirmation surfaces
- full-board usage includes the lower half; the board should not top-load its semantic mass into one central island
- negative space must separate pockets/corridors intentionally rather than reading as leftover void
- UI and overlay surfaces must support the small-world illusion instead of reframing the board as a dashboard inset
- candidate asset work remains a later support lane only and must not stand in for structural success

## 1. Repo-Truth Summary

Current map-screen visuals are produced by a layered presentation stack, not by one owner:

- Full-screen background textures:
  - `scenes/map_explore.tscn:4-6` loads:
    - `Assets/Backgrounds/bg_map_far.png`
    - `Assets/Backgrounds/bg_map_mid.png`
    - `Assets/Backgrounds/bg_map_overlay.png`
  - `scenes/map_explore.tscn:24-46` places them as `BackgroundFar`, `BackgroundMid`, `BackgroundOverlay`.
  - `Game/UI/temp_screen_theme.gd:344-361` sets their live alpha.
  - `scenes/map_explore.gd:900` calls `MapExploreSceneUi.apply_temp_theme(self)`, which applies that backdrop treatment.

- Board shell / board frame:
  - `scenes/map_explore.tscn:157-165` defines `BoardFrame` and `BoardBackdrop`.
  - `Game/UI/map_route_binding.gd:143-144` assigns `BoardBackdrop` a runtime texture.
  - `scenes/map_explore.gd:137` calls `apply_static_map_textures()` during `_ready()`.

- Procedural board rendering:
  - `Game/UI/map_explore_scene_ui.gd:26-75` creates `ComposedBoardCanvas` at runtime.
  - `Game/UI/map_route_binding.gd:173-183` prepares board composition.
  - `Game/UI/map_board_composer_v2.gd:38-100` builds:
    - `world_positions`
    - `layout_edges`
    - `visible_nodes`
    - `visible_edges`
    - `ground_shapes`
    - `filler_shapes`
    - `forest_shapes`
  - `Game/UI/map_board_canvas.gd:34-43` draws the board in passes:
    - atmosphere
    - ground surface
    - filler / landmark silhouettes
    - canopy
    - edges
    - trail decals
    - clearings
    - edge highlight
    - decor

- Optional map texture hooks:
  - `Game/UI/ui_asset_paths.gd:34-62` wires runtime texture families for:
    - walker
    - canopy
    - clearing decals
    - node plates
    - trail families
  - These are consumed by:
    - `Game/UI/map_board_backdrop_builder.gd:138,275-279` for canopy clumps
    - `Game/UI/map_board_composer_v2.gd:358-360,448,827-872` for node icons, node plates, clearing decals, trail textures
    - `Game/UI/map_route_binding.gd:13-16` for board backdrop and walker textures

- Generic fallback icons still in the live map identity path:
  - `Game/UI/ui_asset_paths.gd:10,22-23`
    - combat -> `Assets/Icons/icon_attack.svg`
    - key -> `Assets/Icons/icon_confirm.svg`
    - boss -> `Assets/Icons/icon_enemy_intent_heavy.svg`
  - `Game/UI/map_explore_presenter.gd:206-231` and `Game/UI/map_board_composer_v2.gd:827-848` both route map-facing icon selection through those paths.

Repo-truth conclusion:

- The current map does not have one upgraded "board surface" owner.
- It reads as:
  - full-screen background stack
  - active board shell
  - procedural atmosphere / pockets / roads
  - optional texture stamps
  - semantic icons, some of which are still generic fallback identities

This matches current authority direction:

- `Docs/MAP_CONTRACT.md:12` says board presentation may pre-compose derived layout while discovery stays a readability layer.
- `Docs/HANDOFF.md:28` says `MapBoardComposerV2` derives graph-native board positions / trails / forest shapes from runtime truth plus seed.
- `Docs/HANDOFF.md:329` says structural truth owner remains code and terrain stamps stay optional polish only.

## 2. Runtime Ownership Findings

### 2.1 What exactly is drawing the current map appearance?

From runtime truth:

- Full-screen forest mood comes from `BackgroundFar`, `BackgroundMid`, `BackgroundOverlay`.
- The visible board shell comes from `BoardFrame` plus `BoardBackdrop`.
- The interior map look comes from `ComposedBoardCanvas`, which draws:
  - atmosphere circles / arcs
  - canopy blobs or canopy stamps
  - road lines and highlights
  - trail texture stamps
  - clearing circles and rims
  - clearing decals
  - known-node icons
- The adjacent route markers and walker are separate runtime overlay layers above the canvas:
  - `Game/UI/map_explore_scene_ui.gd:37-73`
  - `Game/UI/map_route_binding.gd:512-564,759-952`

### 2.2 Which parts come from full-screen background textures?

These come from the full-screen background stack:

- far forest silhouette and broad mood mass
- mid-depth trunk / shape mass
- top-level vignette / haze / overlay pass

Runtime alpha is not guessed. It is explicitly applied by:

- `Game/UI/temp_screen_theme.gd:344-361`
- in the map scene call path via `scenes/map_explore.gd:900`

Current map-scene values are:

- far alpha: `0.30`
- mid alpha: `0.14`
- overlay alpha: `0.03`

### 2.3 Which parts come from procedural map board rendering?

These are procedural runtime board layers:

- node placement
- road geometry
- focus / offset behavior
- visible edge subset
- atmosphere circles and guide arcs
- clearing fills / rims / shadows
- fallback canopy blobs when texture hooks are absent

Owners:

- composition generation: `Game/UI/map_board_composer_v2.gd`
- forest-shape generation: `Game/UI/map_board_backdrop_builder.gd`
- actual drawing: `Game/UI/map_board_canvas.gd`
- palette / widths / fill colors / alpha: `Game/UI/map_board_style.gd`

### 2.4 Which parts come from optional map texture hooks?

Currently live optional texture-hook families:

- trail family stamps
- clearing decals
- board-node plates on the canvas
- canopy clump stamps
- walker textures

These are live, but they are not the primary owner of the board read.
Runtime test D shows the map still looks broadly like the same renderer when those hooks are removed.

### 2.5 Which parts come from generic fallback icons?

Current generic fallback map identity still includes:

- combat node icon -> `icon_attack.svg`
- key map icon / key marker -> `icon_confirm.svg`
- boss node icon -> `icon_enemy_intent_heavy.svg`

This is repo truth from:

- `Game/UI/ui_asset_paths.gd:10,22-23`
- `Docs/ASSET_WAVE_SEMANTIC_SCOPE.md:48-50`

Runtime test E confirms that when the currently visible generic-fallback identity is replaced by plain placeholder dots, the map still reads as mostly the same board.
That means the generic icon debt is real, but it is not the only thing flattening perceived quality.

## 3. BoardBackdrop Verification

### 3.1 Does `BoardBackdrop` receive a runtime texture assignment?

Yes.

Verified call path:

- `Game/UI/map_route_binding.gd:13` preloads `res://Assets/UI/Map/ui_map_board_backdrop.svg`
- `Game/UI/map_route_binding.gd:143-144` assigns it through `apply_static_map_textures()`
- `scenes/map_explore.gd:137` calls that method during `_ready()`

### 3.2 Is it later made visible in layout?

Yes.

- `Game/UI/map_route_binding.gd:589-594` sets its offsets each render/layout pass
- `Game/UI/map_route_binding.gd:594` forces `board_backdrop.modulate = Color(1, 1, 1, 1.0)`

Important verification:

- `Game/UI/map_explore_scene_ui.gd:257-260` earlier applies a dimmed modulate to `BoardBackdrop`
- that value is later overridden by `Game/UI/map_route_binding.gd:594`

So `BoardBackdrop` is not inert, not empty, and not just theme residue.
It is actively assigned and displayed at runtime.

### 3.3 Runtime proof

Screenshot F isolates it:

- `export/portrait_review/map_visual_audit_20260422_120708/F_board_backdrop_proof.png`

In that capture:

- full-screen backgrounds are hidden
- `ComposedBoardCanvas` is hidden
- markers / walker are hidden
- the visible interior board shell is still present

Conclusion:

- `BoardBackdrop` is truly active
- but it functions as a shell / backdrop frame, not as a true semantic board-ground layer

## 4. Ground / Terrain Verification

### 4.1 Is there any active dedicated ground / terrain layer?

No active dedicated ground / terrain layer was found.

Verified from repo truth:

- `Assets/UI/Map/Ground/` contains only `.gitkeep`
- `Assets/UI/Map/Landmarks/` contains only `.gitkeep`
- `Assets/UI/Map/Props/` contains only `.gitkeep`
- no active runtime owner was found reading `Assets/UI/Map/Ground/*`
- no `UiAssetPaths` ground family exists
- no runtime map renderer hook was found for board-ground textures

Search result:

- no live runtime references for `Assets/UI/Map/Ground`
- no live runtime references for map `Props` or `Landmarks`
- current reference docs still describe those as future optional families, not active hook lanes:
  - `Docs/ASSET_WAVE_SEMANTIC_SCOPE.md:63-70`

### 4.2 What is creating the current board feel instead?

Current board feel comes from:

- full-screen background textures
- active `BoardBackdrop`
- procedural atmosphere and pocket shading
- procedural clearing fills and rims
- road lines and trail stamps
- semantic icons

Plainly:

- the board currently feels like background + board shell + procedural renderer
- not like a grounded terrain surface

## 5. Map Texture Hook Table

| Surface | Current state | Runtime owner | Evidence | Quality contribution |
|---|---|---|---|---|
| trail family textures | live optional hook | `MapBoardComposerV2` -> `MapBoardCanvas` | `Game/UI/map_board_composer_v2.gd:448,871-872`; test D | meaningful but secondary; removal reduces sheen/readability a bit, not the core quality gap |
| clearing decals | live optional hook | `MapBoardComposerV2` -> `MapBoardCanvas` | `Game/UI/map_board_composer_v2.gd:359,863-868`; test D | low to medium; mostly polish, not a premium-feel driver |
| node plates | live optional hook on canvas | `MapBoardComposerV2` -> `MapBoardCanvas` | `Game/UI/map_board_composer_v2.gd:358,853-860`; test D | medium; contributes readable pockets, but removal does not collapse the visual tier |
| canopy clumps | live optional hook with procedural fallback | `MapBoardBackdropBuilder` -> `MapBoardCanvas` | `Game/UI/map_board_backdrop_builder.gd:138,275-279`; test D | medium for mood, low for semantic identity; currently adds haze/mass more than meaning |
| walker textures | live optional hook | `MapRouteBinding` overlay actor | `Game/UI/map_route_binding.gd:14-16,404,434,769,822`; test D disabled walker sprite | low to medium; gives life/readability, but not the main missing-premium issue |
| key icon | live generic fallback | presenter + composer + key marker | `Game/UI/ui_asset_paths.gd:22`; `Game/UI/map_route_binding.gd:17,743-753`; test E top-right placeholder | meaningful semantic debt; current map key identity still uses a generic confirm icon |
| boss icon | fallback-driven by code truth | presenter + composer | `Game/UI/ui_asset_paths.gd:23`; `Game/UI/map_board_composer_v2.gd:847-848`; `Game/UI/map_explore_presenter.gd:227-229` | meaningful semantic debt when boss is visible; current path still points at a generic heavy-intent icon |
| combat icon | live generic fallback | presenter + composer | `Game/UI/ui_asset_paths.gd:10`; `Game/UI/map_board_composer_v2.gd:831-832`; `Game/UI/map_explore_presenter.gd:211-213`; test E | meaningful repeated identity burden; very visible, but not the only reason the renderer feels similar |

Interpretation from runtime tests:

- trail / clearing / plate / canopy hooks are live
- they are real, not imaginary
- but they are not currently carrying enough of the visual identity to make the board feel like a new tier

### 5.1 Runtime Chain Cross-Check

Checked against current repo truth, the live runtime chain for this audit is:

1. `scenes/map_explore.tscn`
2. `BoardBackdrop` assignment/layout through `Game/UI/map_route_binding.gd`
3. `Game/UI/map_board_canvas.gd`
4. `Game/UI/map_board_composer_v2.gd`
5. `Game/UI/map_board_style.gd`
6. `Game/UI/ui_asset_paths.gd`
7. `AssetManifest/asset_manifest.csv`

Clarifications from the current repo:

- the manifest file lives at `AssetManifest/asset_manifest.csv`, not under `ContentDefinitions/`
- `BoardBackdrop` is a live shell texture lane with a manifest row (`ui_map_board_backdrop`)
- `UiAssetPaths` currently resolves live map-facing paths for:
  - semantic node icons
  - trail textures
  - canopy clumps
  - clearing decals
  - node plates
- the current manifest already has rows for those live families
- the current manifest does **not** have active runtime rows for a board-ground family or for `Assets/UI/Map/Landmarks/*` / `Assets/UI/Map/Props/*`

### 5.2 Visual-World Ownership Matrix

| layer name | current owner | expected owner surface after this pack | contract with `MapRuntimeState` / `MapBoardComposerV2` | seed derivation rule | routing-truth isolation rule | asset-pipeline gate status | blocking reason |
|---|---|---|---|---|---|---|---|
| nodes | live owner: `MapBoardComposerV2` composition into `MapBoardCanvas` | unchanged; stays `MapBoardComposerV2` -> `MapBoardCanvas` | `MapRuntimeState` remains node/discovery/state truth; `MapBoardComposerV2` only derives visible-node placement and render payload from that truth | already derives from the existing board/layout seed and runtime graph; no second RNG lane | nodes remain the clickable route truth; presentation must never rewrite node identity, reachability, or state | `partial` | runtime owner exists and current repo ships live fallbacks, but several supporting map-art rows are still temporary/candidate prototype assets rather than a closed reviewed family |
| paths | live owner: `MapBoardComposerV2` composition into `MapBoardCanvas` | unchanged; stays `MapBoardComposerV2` -> `MapBoardCanvas` | `MapRuntimeState` remains adjacency/routing truth; `MapBoardComposerV2` derives `layout_edges`, visible edges, and trail-family presentation only | already derives from the existing board/layout seed and runtime adjacency; no second RNG lane | paths remain display of route truth only; no decorative layer may add, remove, or redirect a traversable edge | `partial` | runtime owner exists and trail-family hooks are live, but trail textures remain optional polish and current trail asset rows are still temporary/candidate |
| ground / surface | live owner: `MapBoardComposerV2` -> `MapBoardGroundBuilder` -> `MapBoardCanvas` | owner landed in this pack; stays inside the existing `MapBoardComposerV2` chain | consumes composer-owned board inputs such as board size, frozen node world positions, template profile, existing board seed, and board-margin hints; outputs deterministic `ground_shapes` only and never reads scene-level route logic | derives only from the existing map/board seed already used by composition; no second RNG lane | ground is purely presentation under nodes and paths; it never becomes routing truth, click truth, or path-block truth | `partial` | owner landed and procedural fallback is active, but dedicated ground art remains gated by `Docs/ASSET_PIPELINE.md`, manifest rows, provenance/license review, and any future approved runtime hookup |
| filler / landmark | live owner: `MapBoardComposerV2` -> `MapBoardFillerBuilder` -> `MapBoardCanvas` | owner landed in this pack; stays inside the existing `MapBoardComposerV2` chain as a sparse secondary layer | consumes composer-owned board inputs for sparse decorative placement only, plus frozen route polylines for exclusion; outputs deterministic `filler_shapes` only and never owns movement, adjacency, or discovery | derives only from the existing map/board seed already used by composition; no second RNG lane | filler is decorative only; it never encodes reachability, node type, or route affordance, never responds to clicks, and never becomes a replacement atmosphere owner | `partial` | owner landed and procedural fallback is active, but dedicated landmark/prop art remains gated by `Docs/ASSET_PIPELINE.md`, manifest rows, provenance/license review, and any future approved runtime hookup |
| semantic icon overlay | live owner: `MapExplorePresenter` + `MapBoardComposerV2` + `UiAssetPaths` | unchanged in this pack; semantic icon identity remains the Prompt 04 Part D + Prompt 12 lane | `MapRuntimeState` provides node family / state truth, presenter/composer select the matching icon path, and `UiAssetPaths` resolves the runtime file path; this pack must not change that ownership | not seed-driven; deterministic from node family/state truth and existing render composition, with no added RNG | semantic icons express existing node meaning only; they must never become route logic or discovery truth | `partial` | live runtime owner/path exists, but dedicated semantic filenames (`icon_map_combat`, `icon_map_key`, `icon_map_boss`) are still blocked by approval/provenance/runtime-path work tracked outside this pack |

## 6. Screenshot Matrix With File Paths

All audit captures were generated locally at:

- `export/portrait_review/map_visual_audit_20260422_120708/`

| ID | Variant | File path | Runtime toggle | Result |
|---|---|---|---|---|
| A | baseline current map | `export/portrait_review/map_visual_audit_20260422_120708/A_baseline_current_map.png` | none | control image |
| B | backgrounds disabled / hidden | `export/portrait_review/map_visual_audit_20260422_120708/B_backgrounds_off.png` | hide `BackgroundFar`, `BackgroundMid`, `BackgroundOverlay` | map still reads broadly the same; background stack is not the whole problem |
| C | procedural board visible, background layers off | `export/portrait_review/map_visual_audit_20260422_120708/C_procedural_only_backgrounds_off.png` | B + hide `BoardBackdrop` | confirms the board can still render without full-screen backgrounds and without `BoardBackdrop`; in the pre-Prompt-13 capture it also showed that there was no dedicated ground layer under the procedural renderer yet |
| D | background on, optional map textures off | `export/portrait_review/map_visual_audit_20260422_120708/D_backgrounds_on_no_optional_textures.png` | blank trail stamps, clearing decals, node-plate textures, canopy textures; walker sprite disabled | scene still lands in the same quality band; current optional hook families are polish, not the main visual-tier owner |
| E | generic fallback icons replaced by local placeholders | `export/portrait_review/map_visual_audit_20260422_120708/E_generic_fallback_placeholders.png` | visible generic-fallback map icons replaced with plain dots for the capture only | confirms generic fallback identity matters, but replacing it alone does not create a premium-feel jump |
| F | `BoardBackdrop` proof | `export/portrait_review/map_visual_audit_20260422_120708/F_board_backdrop_proof.png` | backgrounds off, board canvas off, markers off, walker off | proves `BoardBackdrop` is active and visible at runtime |

Additional measured reference already in repo:

- `export/portrait_review/prompt05_followup_after_20260422_074840/stage_start_1080x1920.png`
- `export/portrait_review/prompt05_followup_after_20260422_074840/mid_progression_1080x1920.png`
- `export/portrait_review/prompt05_followup_after_20260422_074840/late_progression_1080x1920.png`

These remain useful for broader progression-state context, including late-route node visibility.

## 7. Top 5 Perceived-Quality Bottlenecks

Ranked from strongest contributor to weakest:

1. **No true board-ground layer exists**
   - The board has shell, atmosphere, roads, pockets, and icons.
   - It does not have a dedicated active board-ground owner.
   - This leaves the map reading like symbols floating over dark haze rather than over a designed board surface.

2. **Procedural atmosphere currently carries too much of the board identity**
   - The large halo, central beam, canopy blobs, and pocket shading remain the dominant interior read even after backgrounds are removed.
   - This flattens semantic differentiation between node families.

3. **Semantic map identity is still weak on the high-value icon lanes**
   - Combat, key, and boss still depend on generic shared icon contracts.
   - The map therefore lacks a strong dedicated identity on the most important semantic reads.

4. **Prompt 04 / 05 landed mainly in layout and optional polish, not in a new core visual owner**
   - Runtime test D shows that trail/clearing/plate/canopy hooks are present, but removing them does not drop the board into a radically worse tier.
   - That means they are not yet the main source of quality uplift.

5. **Full-screen background dominance is real, but secondary**
   - Baseline vs B changes the mood stack.
   - It does not, by itself, explain why the board still feels like the same quality level.
   - The deeper problem is the board interior ownership, not just the background stack.

Plain diagnosis:

- Biggest contributor to the current "same quality" feeling: **lack of a true board-ground layer, combined with procedural atmosphere overpowering semantic identity**
- Best category fit: **f. all of the above**, but not evenly
- Actual weight order from runtime evidence:
  1. `e` lack of a true board-ground layer
  2. `d` procedural atmosphere flattening the board
  3. `b/c` weak semantic identity and insufficient map-specific icon polish
  4. `a` background dominance

## 8. Historical Recommendation And Current Continuation Note

**Historical Prompt 13 recommendation: C. add a narrow board-ground ownership patch before any asset work**

Status after Prompt 13:

- this audit recommendation has now landed
- `MapBoardGroundBuilder` and `MapBoardFillerBuilder` are live inside the existing render chain with procedural fallbacks
- asset hookup is still gated by `Docs/ASSET_PIPELINE.md` and `Docs/ASSET_LICENSE_POLICY.md`
- semantic icon identity remains outside this pack in the Prompt 04 Part D + Prompt 12 lane

Why this path wins from runtime evidence:

- At audit time, the runtime did not yet have an active dedicated ground owner.
- `BoardBackdrop` is active, but it is a shell, not the board surface identity.
- Optional texture hooks are live, but they are not the main quality owner.
- Background tuning alone does not solve the core flatness.
- Semantic icon work is still needed, but doing it first would improve labels without fixing the missing surface layer under them.

What this recommendation does **not** mean:

- not terrain transition art
- not reopening asset hookup
- not approving generated assets
- not changing graph truth or route logic

It meant:

- create a narrow renderer-owned board-ground surface or slot
- keep it presentation-only
- keep it separate from save / gameplay / graph truth
- then do semantic icon work on top of a board that has an actual surface owner

Current continuation note:

- that ground/filler-owner recommendation already landed
- do not treat this historical recommendation as the full active-wave target anymore
- the active wave is now broader: road-first read, landmark-pocket identity, full-board usage, meaningful negative space, lower-half utilization, and UI non-interference
- candidate asset work remains delayed until structural review is green

## 9. Minimal Starter Asset Set If A Tiny Wave Starts After This Audit

Historical note:

- this section remains narrow asset triage from the older audit context
- it is not the current queue recommendation for the superseded Prompt `43-62` wave
- use the live `Docs/ROADMAP.md` queue instead of this historical note for current asset timing

If only one tiny asset wave starts after this audit, the highest-leverage three assets are:

1. `Assets/Icons/icon_map_combat.svg`
2. `Assets/Icons/icon_map_key.svg`
3. `Assets/Icons/icon_map_boss.svg`

Why these three:

- they target the exact generic fallback debts already documented in `Docs/ASSET_WAVE_SEMANTIC_SCOPE.md:48-50`
- they improve the most important semantic map reads
- they are narrower and safer than reopening terrain families

Why this is **not** the primary next-step recommendation:

- the audit found that missing surface ownership is the bigger blocker than icon polish alone

## 10. Explicit Non-Goals

This pass did **not**:

- generate assets
- approve assets
- move / rename / convert / import / hook any generated asset
- change save schema
- change gameplay logic
- change route logic
- change map graph truth
- reopen terrain asset hookup
- make any permanent runtime asset-path change

## Validation Notes

Validation run during this audit:

- Passed: `py -3 Tools/validate_architecture_guards.py`
- Passed: `powershell -NoProfile -ExecutionPolicy Bypass -File Tools/run_godot_scene_isolation.ps1 -ScenePath scenes/map_explore.tscn`
- portrait screenshot capture:
  - standard current-map capture: `export/portrait_review/map_explore_1080x1920.png`
  - audit matrix: `export/portrait_review/map_visual_audit_20260422_120708/*.png`

Temporary audit tooling note:

- a local-only capture script was used to generate the A-F matrix
- that tooling was removed after the captures
- the repo is left with the reference-only report, not a permanent asset-hook or gameplay change
