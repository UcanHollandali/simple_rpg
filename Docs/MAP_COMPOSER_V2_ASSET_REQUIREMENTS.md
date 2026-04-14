# SIMPLE RPG - Map Composer V2 Asset Requirements

## Status

- This file is a production/reference companion to `Docs/MAP_COMPOSER_V2_DESIGN.md`.
- Authority remains `Docs/VISUAL_AUDIO_STYLE_GUIDE.md` for style direction and `Docs/ASSET_PIPELINE.md` plus `Docs/ASSET_LICENSE_POLICY.md` for provenance/pipeline rules.
- This file describes asset families required for the baseline Map Composer V2 presentation design.

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

## Replacement Rule (Proposed)

The current `ui_map_board_backdrop` shell should become optional fallback art, not the primary map-surface identity.

V2 needs environmental composition assets for:

- trail carving
- clearing pockets
- canopy mass
- forest props
- boss/key landmark emphasis

## Minimum New Visual Families

These are the minimum new families for baseline V2.

| Family group | Suggested runtime family pattern | Required | Purpose | Notes |
|---|---|---|---|---|
| forest floor base | `ui_map_v2_ground_*` | yes | main board surface under clearings and trails | shared across all scaffold types |
| trail mask / trail edge brushes | `ui_map_v2_trail_*` | yes | spline trail fill, edge breakup, worn path read | preferably vector-friendly or high-resolution transparent raster |
| clearing underlays | `ui_map_v2_clearing_*` | yes | start/node/boss pocket read | at least small / medium / large variants |
| canopy clusters | `ui_map_v2_canopy_*` | yes | hide unreadable space and frame the pocket | large / medium / small silhouette clusters |
| forest props | `ui_map_v2_prop_*` | yes | roots, rocks, shrubs, broken logs | support edge framing and variation |
| route landmark accents | `ui_map_v2_landmark_*` | yes | boss approach, key hint, guide-light accents | used sparingly, not one per node family |
| foreground branch overlays | `ui_map_v2_foreground_*` | optional-baseline | light depth and framing | only if readability remains strong |

## Minimum New Counts (Proposed)

These counts are a pragmatic baseline, not a strict contract:

- forest floor base: `2-3`
- trail brushes / masks / edge variants: `4-6`
- clearing underlays: `3-5`
- canopy clusters: `9-12`
- forest props: `10-16`
- route landmark accents: `4-6`
- foreground overlays: `3-4` if used

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
| board surface | `ui_map_v2_ground_*` | local playable forest floor |
| path layer | `ui_map_v2_trail_*` | traversal read |
| pocket layer | `ui_map_v2_clearing_*` | node-area readability |
| concealment layer | `ui_map_v2_canopy_*` | unreadable forest mass |
| prop layer | `ui_map_v2_prop_*` | variation and edge shaping |
| landmark layer | `ui_map_v2_landmark_*` | boss/key/current-route emphasis |
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

## Priority 1 - Required For First Readable V2 Pass

- `ui_map_v2_ground_*`
- `ui_map_v2_trail_*`
- `ui_map_v2_clearing_*`
- `ui_map_v2_canopy_*`

## Priority 2 - Required For Strong Wayfinder Identity

- `ui_map_v2_prop_*`
- `ui_map_v2_landmark_*`

## Priority 3 - Nice To Have

- `ui_map_v2_foreground_*`
- optional overlay refresh families
- optional audio polish families

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
- Most V2 value will come from environmental composition assets, not from replacing every current overlay asset.
- The shared-core-family approach will be enough to differentiate `corridor`, `openfield`, and `loop` without separate art packs.
