# SIMPLE RPG - Production Art Pilot Socket Audit

Last updated: 2026-04-24

## Status

- This is a planning/audit document, not an authority document.
- Authority remains `Docs/ASSET_PIPELINE.md`, `Docs/ASSET_LICENSE_POLICY.md`, `Docs/MAP_CONTRACT.md`, and `Docs/SOURCE_OF_TRUTH.md`.
- Candidate art in this lane is not structural proof and must keep `replace_before_release=yes` until explicitly promoted.

## Confirmed Socket Carriers

### Path Surface

- Runtime source: `render_model.path_surfaces`.
- Current texture routing: `UiAssetPaths.build_map_path_surface_socket_texture_path(...)`.
- Prototype coverage: covered by `Assets/UI/Map/ArtPilot/ui_map_art_pilot_path_brush.svg` when that asset exists and explicit prototype socket dressing is enabled.
- Placeholder coverage: socket-smoke path brush is hidden by default and only allowed through the explicit debug/prototype flag.
- Placement:
  - center: midpoint of the rendered path polyline
  - rotation: path direction, with source art expected to run left-to-right along the positive X axis
  - draw size: `x = clamp(surface_width * 1.72, 24, 52)`, `y = clamp(surface_width * 0.68, 12, 24)`
  - opacity: lower for history roads than actionable roads
- Asset target:
  - source/runtime viewBox: `128x64`
  - transparent background
  - irregular walked-earth brush, no rectangular frame

### Landmark

- Runtime source: `render_model.landmark_slots`.
- Current texture routing: `UiAssetPaths.build_map_landmark_socket_texture_path(asset_family_key, node_family, ...)`.
- Current prototype coverage:
  - `boss:*` -> `Assets/UI/Map/ArtPilot/ui_map_art_pilot_boss_landmark.svg`
  - `key:*` -> `Assets/UI/Map/ArtPilot/ui_map_art_pilot_key_landmark.svg`
  - `rest:*` -> `Assets/UI/Map/ArtPilot/ui_map_art_pilot_rest_landmark.svg`
  - `merchant:*` -> `Assets/UI/Map/ArtPilot/ui_map_art_pilot_merchant_landmark.svg`
- Current normal/default render:
  - all candidate art-pilot landmark dressing is hidden.
  - unsupported landmark families skip socket-smoke placeholders.
- Placement:
  - center: `slot.anchor_point + board_offset`
  - rotation: `slot.rotation_degrees`
  - draw size: square `clamp(max(landmark_half_size) * 1.08, 18, 38)`
  - opacity: stronger for current/adjacent landmark slots, softer for older visible slots
- Asset target:
  - source/runtime viewBox: `128x128`
  - transparent background
  - centered silhouette that remains readable at roughly `18-38px`
  - rotation-tolerant, because board sockets can rotate by route direction

### Decor / Filler

- Runtime source: `render_model.decor_slots`.
- Current texture routing: `UiAssetPaths.build_map_decor_socket_texture_path(...)`.
- Prototype coverage: all decor slots use `Assets/UI/Map/ArtPilot/ui_map_art_pilot_decor_stamp.svg` when that asset exists and explicit prototype socket dressing is enabled.
- Placeholder coverage: socket-smoke decor stamp is hidden by default and only allowed through the explicit debug/prototype flag.
- Placement:
  - center: `slot.anchor_point + board_offset`
  - rotation: `slot.rotation_degrees`
  - draw size: square `clamp(max(radius * 1.36, max(half_size) * 0.68), 12, 30)`
  - opacity: soft secondary dressing
- Asset target:
  - source/runtime viewBox: `96x96`
  - transparent background
  - small route-edge or clearing-edge prop
  - must not read as a node token

## Current Candidate Runtime Assets

| Runtime asset | Manifest status | ViewBox | Prototype use |
|---|---:|---:|---|
| `Assets/UI/Map/ArtPilot/ui_map_art_pilot_path_brush.svg` | candidate, replace before release | `128x64` | path surface sockets when prototype dressing is enabled |
| `Assets/UI/Map/ArtPilot/ui_map_art_pilot_boss_landmark.svg` | candidate, replace before release | `128x128` | `boss:*` landmark sockets when prototype dressing is enabled |
| `Assets/UI/Map/ArtPilot/ui_map_art_pilot_key_landmark.svg` | candidate, replace before release | `128x128` | `key:*` landmark sockets when prototype dressing is enabled |
| `Assets/UI/Map/ArtPilot/ui_map_art_pilot_rest_landmark.svg` | candidate, replace before release | `128x128` | `rest:*` landmark sockets when prototype dressing is enabled |
| `Assets/UI/Map/ArtPilot/ui_map_art_pilot_merchant_landmark.svg` | candidate, replace before release | `128x128` | `merchant:*` landmark sockets when prototype dressing is enabled |
| `Assets/UI/Map/ArtPilot/ui_map_art_pilot_decor_stamp.svg` | candidate, replace before release | `96x96` | decor sockets when prototype dressing is enabled |

## Recommended Family Order

1. Landmark progression silhouettes: improve boss gate and key shrine because they carry route commitment and late-stage goals.
2. Support landmarks: continue merchant/rest variants after the first merchant coverage pass so support pockets do not collapse back into generic icon reads.
3. Path brush: improve cautiously because it touches every route and has the largest readability blast radius.
4. Decor/filler: keep last and sparse; it is useful for world texture but easiest to overdo.

## Confirmed Non-Goals

- Do not use candidate art as proof that route topology, hunger pressure, or pocket quality is solved.
- Do not restore retired `ui_map_v2_*` trail/decal/node-plate lanes.
- Do not draw socket-smoke placeholders in normal/default render.
- Do not draw art-pilot candidate dressing in normal/default render unless a future review explicitly promotes replacement assets.
- Do not add gameplay truth, save shape, or flow state changes.

## Assumptions

- SVG remains the fastest safe candidate format for this repo because the current art-pilot lane and runtime import path already use SVG.
- Final production art may later replace these SVG candidates with cleaned SVG or PNG exports, but the runtime socket contract should stay the same unless a future audit proves otherwise.
