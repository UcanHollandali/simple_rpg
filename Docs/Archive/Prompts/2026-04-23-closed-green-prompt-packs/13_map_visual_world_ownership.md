# Prompt 13 - Map Visual World Ownership

Use this prompt pack only after Prompt 12.5 is closed green.
This is a future-queue ownership/contract pack. Do not start it while any earlier open 06-12.5 pack is still open.

Checked-in filename note:
- this pack lives at `Docs/Archive/Prompts/2026-04-23-closed-green-prompt-packs/13_map_visual_world_ownership.md`
- checked-in filename and logical queue position now match Prompt `13`

Read first:
- `AGENTS.md`
- `Docs/DOC_PRECEDENCE.md`
- `Docs/HANDOFF.md`
- `Docs/ROADMAP.md`
- `Docs/MAP_CONTRACT.md`
- `Docs/MAP_COMPOSER_V2_DESIGN.md`
- `Docs/MAP_COMPOSER_V2_ASSET_REQUIREMENTS.md`
- `Docs/MAP_VISUAL_OWNERSHIP_AUDIT.md` (reference-only runtime audit; grounds this pack in repo truth)
- `Docs/ASSET_PIPELINE.md`
- `Docs/ASSET_LICENSE_POLICY.md`
- `Docs/VISUAL_AUDIO_STYLE_GUIDE.md`

Optional reference:
- `Docs/ASSET_WAVE_SEMANTIC_SCOPE.md`
- `Docs/SEMANTIC_ICON_READINESS_CHECKLIST.md` (reference-only output from Prompt 12)
- `Docs/UI_INFORMATION_ARCHITECTURE_AUDIT.md`

## Context Statement

After Prompts 04 and 05 landed, node placement and path routing feel more deliberate, but the board still reads as a *graph* rather than a *generated world*. `Docs/MAP_VISUAL_OWNERSHIP_AUDIT.md` now confirms the runtime truth behind that feeling:

- The current map surface stack is: full-screen background textures (`BackgroundFar` / `BackgroundMid` / `BackgroundOverlay`), an active board shell (`BoardFrame` + `BoardBackdrop`), the procedural board renderer (`MapBoardComposerV2` -> `MapBoardCanvas` -> `MapBoardStyle`), optional texture hooks (trails, clearing decals, node plates, canopy clumps, walker), and semantic icons still partly served by generic fallbacks (`icon_attack` for combat, `icon_confirm` for key, `icon_enemy_intent_heavy` for boss).
- `BoardBackdrop` is verified active (audit screenshot `F`), but it functions as a shell/frame, not as a true board-ground identity owner.
- The missing visual owner is not "background removal"; it is the lack of a true board-ground owner inside the board itself. Prompt 04/05 mostly landed in layout stability and optional polish, not in a new core visual owner.
- `Assets/UI/Map/Ground/`, `Assets/UI/Map/Landmarks/`, and `Assets/UI/Map/Props/` each contain only `.gitkeep`. No runtime owner reads them. `UiAssetPaths` has no ground family.
- The audit runtime test matrix (`A`-`F` under `export/portrait_review/map_visual_audit_20260422_120708/`) shows:
  - removing full-screen backgrounds (test `B`) does not change the perceived tier
  - disabling optional texture hooks (test `D`) does not collapse the tier either
  - replacing generic fallback icons with placeholders (test `E`) does not produce a premium-feel jump on its own
- The audit's stack-ranked bottlenecks are, strongest first: (1) no true board-ground layer, (2) procedural atmosphere carrying too much of the board identity, (3) weak semantic identity on high-value icon lanes, (4) Prompt 04/05 landing mostly in layout/optional polish, (5) full-screen background dominance as a secondary effect.
- The audit's recommended path is "C. add a narrow board-ground ownership patch before any asset work". Semantic icon work (combat/key/boss) is identified as real but dependent on a real surface owner under the icons.

This pack is the runtime follow-through to that audit. Its Part B directly implements the audit's recommended path. The audit itself is already checked in and is not regenerated here.
This pack primarily lands the missing board-ground owner. Its filler/landmark slice is secondary, sparse, non-routing, and must not become a replacement atmosphere layer.

## Goal

Establish *ownership and contract surfaces* for the two map visual-world layers that currently have no owner:

1. **Board ground/surface layer** - the terrain beneath nodes and paths.
2. **Board filler/landmark layer** - decorative, non-routing world fill (trees, rocks, ruins, water patches, roads-that-are-not-routes, etc.).

This pack does **not** ship art.
This pack does **not** hook art into runtime.
This pack **defines** where those layers belong, how they receive input, how they stay decoupled from routing, and how they compose with the existing `MapBoardComposerV2` chain.

## Direction Statement

- Nodes/paths are routing truth. Ground and filler must never become routing truth.
- Ground and filler are *derived from the same seeded map state* that already drives node layout; they must not introduce a second RNG stream that desyncs from the frozen full-layout baseline.
- Ownership for these layers belongs next to existing map render owners (board composer / board canvas / board style), not inside screen scenes.
- Asset hookup is gated by `Docs/ASSET_PIPELINE.md` and `Docs/ASSET_LICENSE_POLICY.md`; this pack must not shortcut those gates.
- Semantic icon identity (Prompt 04 Part D + Prompt 12 readiness) is out of scope here; this pack is only ground + filler ownership.
- The output should make the board *feel* generated, not just routed, while keeping gameplay truth unchanged.

## Preferred Owner Surfaces

- new shared owners sitting inside the existing `MapBoardComposerV2` chain, not above it
- `MapBoardStyle` extensions for style tokens only
- `MapBoardCanvas` layering order changes only if strictly needed for z-order correctness
- no new top-level scene owner
- no ownership inside `map_explore_scene_ui.gd` or other screen-level scripts

## Hotspot Guard

- `Game/UI/map_board_composer_v2.gd` is already a large hotspot file.
- Prefer extracting new owner/helper files over adding large inline blocks directly to `MapBoardComposerV2`.
- Keep `MapBoardComposerV2` as the caller-facing composition owner, but do not bury the new ground/filler rules inside random additional hundreds of lines there.

## Hard Guardrails

- No change to `MapRuntimeState` node/edge truth.
- No change to path routing logic.
- No new RNG stream; ground/filler seeds must derive from the existing map seed.
- No save/schema change.
- No flow change.
- No gameplay truth change (nothing the player can click that affects run state).
- No asset generation.
- No asset approval.
- No asset move/rename/import/convert.
- No `UiAssetPaths` change that points at art not already approved per `Docs/ASSET_PIPELINE.md`.
- No new command family or event family.
- No owner move out of the existing map render chain.
- No file rename of existing owners. `temp_screen_theme.gd` keeps its `temp_` prefix.
- No claim that this pack unblocks the semantic icon wave.
- No smuggling of terrain-transition art work into a ground/filler ownership pack.

## Validation

- `py -3 Tools/validate_architecture_guards.py`
- `py -3 Tools/validate_assets.py`
- targeted map composer / board style tests for touched owners
- scene isolation for the map explore screen if composer code changed
- full suite before closing implementation parts
- portrait screenshots of the map screen with ground + filler owners active (even with placeholder/procedural fallbacks) so the "feels generated" checkpoint can be reviewed

## Done Criteria

- `Docs/MAP_VISUAL_OWNERSHIP_AUDIT.md` exists and records, for each visual-world layer:
  - current owner (or "no owner yet")
  - expected owner surface
  - expected contract with `MapRuntimeState` / `MapBoardComposerV2`
  - seed derivation rule
  - routing-truth isolation rule
  - asset-pipeline gate status
- A named ground/surface owner exists in the map render chain with a clear contract and a procedural fallback that does not require new approved art.
- Ground-owner landing is the primary acceptance gate for this pack.
- A named filler/landmark owner exists in the map render chain as a secondary sparse layer with a clear contract and a procedural fallback that does not require new approved art.
- Filler must add light world fill without becoming a replacement atmosphere layer or a second core identity owner.
- Both owners derive placement from the existing seeded map state and cannot cause node/path drift.
- The map screen reads as a generated world under procedural fallbacks, not just a graph on a flat backdrop.
- No gameplay truth changed.
- No asset was generated, approved, or hooked.
- Semantic icon identity remains scoped to Prompt 04 Part D + Prompt 12, not this pack.

## Copy/Paste Parts

### Part A - Visual Ownership Audit Doc

```text
Apply only Prompt 13 Part A.

Scope:
- Verify the checked-in Docs/MAP_VISUAL_OWNERSHIP_AUDIT.md against current repo truth and update it only where the checked-in audit is stale or incomplete.
- If the audit doc is unexpectedly missing in the working tree, recreate it as a reference-only ownership audit instead of widening scope.
- Walk the current runtime chain:
  map_explore.tscn -> BoardBackdrop -> MapBoardCanvas -> MapBoardComposerV2 -> MapBoardStyle -> UiAssetPaths -> asset_manifest.csv
- For each visual-world layer, record:
  - layer name (nodes, paths, ground/surface, filler/landmark, semantic icon overlay)
  - current owner (or "no owner yet")
  - expected owner surface after this pack
  - contract with MapRuntimeState / MapBoardComposerV2
  - seed derivation rule (must derive from existing map seed)
  - routing-truth isolation rule (ground/filler must never become routing truth)
  - asset-pipeline gate status (ready now / blocked / partial) and blocking reason
- Mark ground/surface and filler/landmark rows as "no owner yet" where that is the current state.
- Mark semantic icon identity as owned by Prompt 04 Part D + Prompt 12, not this pack.

Do not:
- generate or edit assets
- repoint UiAssetPaths
- change MapRuntimeState truth
- treat file presence as approval

Validation:
- validate_architecture_guards
- validate_assets
- markdown/internal link sanity on the new audit doc

Report:
- files created/changed
- layers with new ownership plan vs still-no-owner
- explicit confirmation that no runtime code changed in Part A
- explicit confirmation that no asset changed state
```

### Part B - Ground / Surface Owner

```text
Apply only Prompt 13 Part B.

Scope:
- Introduce a named ground/surface owner inside the existing MapBoardComposerV2 chain (preferred: a new shared sub-owner under the composer, not a new top-level scene node).
- The owner must:
  - read only from existing seeded map state
  - expose a small, auditable contract (what it draws, where it draws, what tokens it consumes)
  - not know about routing
  - not know about individual node identities (combat/key/boss live in the semantic icon layer, not here)
  - ship a procedural fallback that does not require new approved art and is defined only through code/style-token-driven rendering (for example seeded fills, pattern breakup, or noise derived from `MapBoardStyle` tokens)
- Extend MapBoardStyle with ground tokens only; do not widen its responsibility beyond style.
- MapBoardCanvas layer order may be adjusted only if strictly required for z-order correctness (ground must render beneath paths and nodes).
- The ground owner must define the board interior surface; it does not replace `BoardBackdrop`, which remains a board shell/frame owner.
- The ground owner must compose cleanly with the existing render stack and make the below/above relationship explicit if `BoardBackdrop` remains visible behind it.

Do not:
- introduce a second RNG stream
- add a new runtime event or command
- repoint UiAssetPaths at unapproved art
- widen into filler/landmark responsibilities
- change node or path rendering
- take over the existing procedural atmosphere owner
- silently redefine haze / halo / canopy mass as "ground"
- use `BoardBackdrop` art as a substitute for a real ground owner

Validation:
- validate_architecture_guards
- validate_assets
- targeted composer/board style tests
- scene isolation on the map explore screen
- portrait screenshot of the map screen with the procedural ground fallback active
- full suite before closing

Report:
- files changed
- new owner name and its contract in one paragraph
- confirmation that seed derivation flows from the existing map seed
- confirmation that routing truth is unchanged
- confirmation that no new art was hooked
```

### Part C - Filler / Landmark Owner

```text
Apply only Prompt 13 Part C.

Scope:
- Introduce a named filler/landmark owner inside the existing MapBoardComposerV2 chain as a secondary sparse layer, layered above ground and below paths/nodes.
- The owner must:
  - read only from existing seeded map state
  - produce sparse non-routing decoration (trees, rocks, ruins, water patches, road-like dressings that are not routes, etc.)
  - keep an auditable density/placement contract (how many items per region, minimum distance from nodes and paths, exclusion zones around interactive surfaces)
  - enforce explicit exclusion zones around nodes, real routes, route markers, and other interactive surfaces
  - ship a procedural fallback that does not require new approved art (e.g., token shapes, seeded silhouettes from existing MapBoardStyle tokens)
- Add filler tokens to MapBoardStyle only; do not widen style to own gameplay truth.
- Ensure filler cannot occlude, move, or visually imply edges between nodes that are not real routes.
- Filler must stay secondary to the ground/surface owner and must not become a replacement atmosphere layer.

Do not:
- share a layer with nodes/paths
- let filler items respond to clicks
- introduce a second RNG stream
- repoint UiAssetPaths at unapproved art
- widen into semantic icon identity (that is Prompt 04 Part D + Prompt 12)
- introduce animated filler that could be read as gameplay signal
- introduce a new haze / fog / halo mass that duplicates atmosphere ownership
- place filler so densely that it reads like a second canopy/atmosphere pass
- place filler so it suggests fake traversable routes or fake route branches

Validation:
- validate_architecture_guards
- validate_assets
- targeted composer/board style tests
- scene isolation on the map explore screen
- portrait screenshot of the map screen with procedural ground + procedural filler active, verifying the screen reads as a generated world rather than a graph
- full suite before closing

Report:
- files changed
- new owner name and its contract in one paragraph
- exclusion rules around nodes/paths
- confirmation that filler is non-interactive and non-routing
- confirmation that no new art was hooked
```

### Part D - Closeout And Handoff Refresh

```text
Apply only Prompt 13 Part D.

Scope:
- Update Docs/HANDOFF.md and Docs/ROADMAP.md so Prompt 13 is recorded as closed and the UI overhaul wave closes here; the next broader phase remains Phase D (`Playtest and Telemetry`).
- Record in Docs/MAP_VISUAL_OWNERSHIP_AUDIT.md the new owner names from Parts B and C and mark their rows as "owner landed, procedural fallback active, asset hookup still gated by ASSET_PIPELINE.md".
- Do not claim that this pack unblocked the semantic icon wave or terrain-transition art.

Validation:
- markdown/internal link sanity
- validate_architecture_guards
- validate_assets

Report:
- files changed
- final ownership state per visual-world layer
- explicit confirmation that no asset was generated, approved, or hooked
- explicit confirmation that no gameplay truth changed
- explicit confirmation that routing truth is unchanged
```
