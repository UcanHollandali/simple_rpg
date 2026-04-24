# SIMPLE RPG - Map Composer V2 Asset Requirements

## Status

- This file is a production/reference companion to `Docs/MAP_COMPOSER_V2_DESIGN.md`.
- Authority remains `Docs/VISUAL_AUDIO_STYLE_GUIDE.md` for style direction and `Docs/ASSET_PIPELINE.md` plus `Docs/ASSET_LICENSE_POLICY.md` for provenance/pipeline rules.
- This file describes the code-first Map Composer V2 presentation direction: the procedural renderer owns baseline terrain/board readability, while asset families stay in the optional-polish or later semantic-surface lanes.
- Asset adoption assumes the board first behaves as a stable stage-start layout and that discovery only reveals a frozen layout; optional dressing must re-enter through render-model sockets after screenshot evidence, not through the retired wrapper stamp layer.
- The closed map wave retired the older draw-only `ui_map_v2_trail_*`, `ui_map_v2_clearing_decal_*`, and `ui_map_v2_node_plate_*` candidate lanes. Future dressing should target render-model sockets instead of restoring those top-level asset-path hooks.
- The closed map wave retired the visible atmosphere/ground/filler/canopy wrapper blob layer, removed non-routing oval/blob marks from `ui_map_board_backdrop.svg`, and removed the old runtime wrapper assets; `ground_shapes`, `filler_shapes`, and `forest_shapes` remain metadata for masks/socket derivation only.

## Observed Current Asset Baseline (Certain)

The current repo already provides these map-facing runtime families:

- map background triplet:
  - `Assets/Backgrounds/bg_map_far.png`
  - `Assets/Backgrounds/bg_map_mid.png`
  - `Assets/Backgrounds/bg_map_overlay.png`
- board shell asset:
  - `Assets/UI/Map/ui_map_board_backdrop.svg`
- walker assets:
  - `Assets/UI/Map/Walker/ui_map_walker_idle.svg`
  - `Assets/UI/Map/Walker/ui_map_walker_walk_a.svg`
  - `Assets/UI/Map/Walker/ui_map_walker_walk_b.svg`
- map-family icons already used by the overlay layer:
  - `icon_map_start`
  - `icon_attack`
  - `icon_reward`
  - `icon_map_rest`
  - `icon_map_merchant`
  - `icon_map_blacksmith`
  - `icon_confirm`
  - `icon_enemy_intent_heavy`
  - `icon_node_marker`

## Asset Strategy

## Reuse Rule (Proposed)

Reuse current assets where they still fit the V2 role:

- keep the existing node-family icon family as the first overlay identity layer
- keep the existing walker family for traversal readability
- keep the existing `bg_map_*` family as the large-screen backdrop layer

## Prototype Asset-Wave Rule (Current Direction)

- `SourceArt/Generated/new/` is a candidate/source pack for the generated-map overhaul.
- Those files are not authority docs and they are not automatically approved runtime assets.
- File presence under `Assets/UI/Map/` or `SourceArt/Generated/new/` must not be treated as implicit approval; runtime hookup still requires explicit approved filenames plus truthful manifest rows.
- The current direction is selective adoption:
  - use the pack to replace or augment weak older node/path/pocket visuals
  - keep runtime graph truth and composer ownership unchanged
  - generate missing families only when the current prototype pack leaves a real gap
- The source pack now keeps normalized master folders under `SourceArt/Generated/new/`:
  - `node_shell_variants`
  - `state_overlays`
  - `path_assets`
  - `clearing_ground`
  - `canopy_fog_filler`
- The operational source prompt reference remains `SourceArt/Generated/new/asset_prompts.md`.
- Redundant source-planning markdowns were archived under `SourceArt/Archive/2026-04-20-map_prototype_pack/docs/`.
- Treat this as a prototype kit for the graph-backed board, not as final release art.

## Replacement Rule (Proposed)

The current `ui_map_board_backdrop` shell should become optional fallback art, not the primary map-surface identity.

V2 can optionally add socket-driven environmental polish for:

- path-surface breakup
- clearing / landmark pocket dressing
- decor or canopy-frame stamps derived from sockets/masks
- boss/key landmark emphasis

## Optional Terrain / Board Polish Families

These are optional terrain / board polish families for V2 after the procedural renderer is already acceptable on its own.

| Family group | Suggested runtime family pattern | Priority lane | Purpose | Notes |
|---|---|---|---|---|
| board-surface socket dressing | future socket-driven family | optional-polish | supplemental board-surface breakup after the road/pocket read is already green | must not restore the retired free-floating ground blob/stamp lane |
| path-surface socket brushes | future socket-driven family | optional-polish | supplemental render-model path-surface breakup after the procedural road read is already green | must derive from `render_model.path_surfaces`; the old `ui_map_v2_trail_*` draw lane is retired |
| clearing / landmark socket dressers | future socket-driven family | optional-polish | supplemental start/node/boss pocket read after procedural clearings and landmark slots are already green | must derive from `render_model.clearing_surfaces` or `render_model.landmark_slots`; the old `ui_map_v2_clearing_*` draw lane is retired |
| canopy / decor socket dressers | future socket-driven family | optional-polish | supplemental concealment mass and pocket framing | derive from `render_model.canopy_masks` or `render_model.decor_slots`; do not draw background blobs by default |
| route landmark accents | future socket-driven family | later-polish | boss approach, key hint, guide-light accents | used sparingly, not one per node family |
| foreground branch overlays | `ui_map_v2_foreground_*` | later-polish | light depth and framing | only if readability remains strong |

## Generated-Map Pipeline Fit

The intended board pipeline for the current overhaul is:

1. scatter node layout from graph truth
2. freeze full path layout for the stage
3. filter visible subset from that frozen layout
4. render the procedural pocket and road surface first, then optionally layer socket-driven dressing

Asset families must support that order and remain safe when optional socket dressing loads return `null`.
They must not assume that visibility changes can redraw path geometry.

## Minimum New Counts (Proposed)

These counts are a pragmatic baseline, not a strict contract:

- forest floor base: `2-3`
- trail brushes / masks / edge variants: `4-6`
- clearing underlays: `3-5`
- canopy clusters: `9-12`
- forest props: `10-16`
- route landmark accents: `4-6`
- foreground overlays: `3-4` if used

## Current Prototype Priority Families

The current prototype wave should favor semantic identity completion first, with terrain/board families treated as optional later polish:

- node identity/icon completion
  - `icon_map_combat`
  - `icon_map_key`
  - `icon_map_boss`
- optional socket-driven board-support polish
  - path-surface brushes derived from `render_model.path_surfaces`
  - junction/clearing trim derived from `render_model.junctions` and `render_model.clearing_surfaces`
  - landmark/decor/socket dressing derived from `render_model.landmark_slots` and `render_model.decor_slots`
- retired/deferred wrapper polish
  - free-floating canopy, ground, prop, and atmosphere blob/stamp lanes are not live runtime proof after the closed map wave
  - future canopy/clutter work must re-enter through sockets/masks with screenshot evidence instead of resurrecting the old background-stamp layer

These families can deepen the generated board after the procedural renderer itself is visually acceptable. They are not Priority 1 blockers for the first readable V2 pass.

## Overlay Asset Policy

## Reuse As-Is Or Near-As-Is (Proposed)

The following overlay-facing families should stay mostly reusable:

- current node family icon set
- current state-chip logic
- current selection ring logic
- current walker family

## Optional Overlay Refresh (Proposed)

These are optional refinements, not baseline blockers:

- `ui_map_v2_node_halo_*`
- `ui_map_v2_selection_ring_*`
- `ui_map_v2_state_badge_*`
- `ui_map_v2_current_beacon_*`

The baseline V2 design can keep these procedurally styled in UI rather than requiring new art exports.

## State Overlay Caution

- The current live state-plate lane is already readable and wired.
- SourceArt overlay experiments and heavy boss-shell concepts may be useful references, but they do not automatically replace the live state-plate baseline.
- Treat those heavier shell/overlay ideas as optional later adoption, not as first-pass runtime requirements.

## Scaffold-Specific Presentation Need

## Shared Core Rule (Proposed)

Do not create a separate full art set per scaffold.

Use one shared forest family, then vary density and placement by scaffold profile:

- `corridor`: denser canopy walls, narrower trail masks, fewer wide clearings
- `openfield`: wider clearings, broader negative space, lighter edge compression
- `loop`: more circular framing props, stronger reconnecting trail arcs

This keeps production scope controlled and avoids hidden mechanic drift through art.

## Asset Families By Layer

| Layer | Family group | Visual role |
|---|---|---|
| backdrop | existing `bg_map_*` | far atmosphere and depth |
| board surface | plain procedural base + future socket-driven dressing | local playable forest floor |
| path layer | procedural `render_model.path_surfaces` + future socket-driven path brushes | traversal read |
| pocket layer | procedural `render_model.clearing_surfaces` + future socket-driven clearing/landmark dressers | node-area readability |
| concealment layer | metadata-only canopy masks + future socket-driven dressers | unreadable forest mass without free-floating blob ownership |
| prop layer | future socket-driven decor dressers | variation and edge shaping |
| landmark layer | future socket-driven landmark dressers | boss/key/current-route emphasis |
| overlay layer | existing icons + optional `ui_map_v2_node_halo_*` | node family/state/hit target clarity |
| actor layer | existing walker family | local traversal motion |

## Style Requirements

These are pulled from current production authority and applied to Map Composer V2:

- dark forest wayfinder mood
- stylized, not realistic
- readable before atmospheric
- silhouette-first composition
- mobile-readable small-screen contrast
- no muddy green wash
- no neon fantasy drift
- no painterly watercolor softness

## Palette Guidance For New Families

Use the existing locked palette behavior:

- charcoal and panel-tone darks for deep canopy
- aged bronze / guide gold for path guidance and landmark accents
- wayfinder teal for controlled route emphasis
- rust accent only for danger / boss / lock reads
- text-primary light tones only for focused highlights, not for broad fill

## Shape Language

- canopy masses should read as clustered silhouettes, not individual botanical studies
- clearings should read as worn earth / flattened ground, not glowing magic circles
- trail edges should feel walked and slightly irregular, not ruler-straight
- props should support directionality and negative-space framing
- landmark accents should feel like wayfinding cues, not quest-marker UI objects embedded in the forest

## Audio Impact

## Certain Current Baseline

- The current map scene already has a map music loop and node-select SFX.

## Baseline V2 Recommendation

- No new audio family is required for baseline Map Composer V2 acceptance.
- Optional later additions could include:
  - softer footstep variant tied to longer trail moves
  - subtle forest rustle layer
  - boss-gate ambience sting

Those are optional polish, not baseline blockers.

## Production Priority

## Priority 1 - Required For First Readable Code-First Pass

- `icon_map_combat`
- `icon_map_key`
- `icon_map_boss`

Ground / trail / clearing / canopy / filler / junction / forest-transition families are optional polish, not Priority 1 blockers.

## Priority 2 - Optional Board / Route Polish After Procedural Pass

- future socket-driven board-surface dressing family
- future socket-driven path-surface brush family
- future socket-driven clearing / landmark dresser family
- future socket-driven canopy / decor dresser family
- future junction trim family derived from `render_model.junctions`

## Priority 3 - Later Semantic / Atmosphere Polish

- future socket-driven decor prop family
- future socket-driven route landmark accent family
- `ui_map_v2_foreground_*`
- optional overlay refresh families
- optional audio polish families
- larger shell-first node repaints if they still respect the live overlay/readability baseline

## Suggested Authoring Notes

- Favor reusable transparent SVG or high-resolution PNG cutout families over one giant baked board image.
- Keep assets modular so the composer can vary layouts without requiring one export per stage graph.
- Use silhouette readability checks at runtime scale, not only in source files.
- Validate every family against the portrait board first, not against a desktop zoom view.

## Risks

- Overproducing canopy detail could reduce path readability.
- Too few canopy variants could make deterministic composition feel repetitive.
- Too many bespoke landmark assets could quietly encode mechanic meaning into art rather than overlay/UI.
- Trail assets with hard edges may fight spline curvature and look stamped-on.
- Heavy raster props may become expensive if the board needs many layered pieces on mobile.

## Assumptions

These are proposals, not confirmed repo facts:

- Existing icon families are strong enough to carry node identity without a full new icon set.
- Most near-term V2 value will come from procedural renderer tuning plus semantic icon completion, not from terrain asset hookup.
- The shared-core-family approach will be enough to differentiate `corridor`, `openfield`, and `loop` without separate art packs.
