# Map Asset External Request Pack

Generated: 2026-04-25

Source: live `.gd` socket metadata from `map_socket_production_asset_brief`, current asset manifest state, and production asset pipeline rules.

## Purpose

This pack is the handoff for external art production. It tells an artist or image-generation workflow what to make before the repo imports any final candidate files.

Do not treat this pack as runtime approval. Runtime promotion still needs source/master files, runtime exports, manifest provenance, screenshot review, and pixel diff.

## Shared Style

- Dark forest wayfinder fantasy.
- Silhouette-first, readable at small map scale.
- Transparent background.
- No text, numbers, UI card frame, badge frame, or route truth markings.
- Keep detail sparse enough to read inside the existing socket sizes.
- Palette target: dark ink, muted bark, aged bronze, oxidized teal, pale warm highlight.
- Deliver 2-3 variants per item when possible.

## Requested Assets

| request id | socket/family key | preferred format | master path target | runtime path target | brief |
|---|---|---|---|---|---|
| `map_path_brush_production` | `path_surface` | SVG, transparent PNG acceptable | `SourceArt/Edited/Map/Production/ui_map_path_brush_master_v001.svg` | `Assets/UI/Map/Production/ui_map_path_brush.svg` | A forest trail brush that can rotate along curved path surfaces. It should read as worn earth, roots, and subtle guide-light flecks, not a hard UI line. |
| `map_landmark_combat_production` | `combat:crossed_stakes` | SVG preferred | `SourceArt/Edited/Map/Production/ui_map_combat_landmark_master_v001.svg` | `Assets/UI/Map/Production/ui_map_combat_landmark.svg` | Crossed stakes or broken warning totem. Clear danger silhouette without skull/cartoon icon language. |
| `map_landmark_event_production` | `event:standing_stone` | SVG preferred | `SourceArt/Edited/Map/Production/ui_map_event_landmark_master_v001.svg` | `Assets/UI/Map/Production/ui_map_event_landmark.svg` | Standing stone or omen marker. Mysterious but readable, with one simple inner glyph-like shape that is not literal text. |
| `map_landmark_reward_production` | `reward:cache_slab` | SVG preferred | `SourceArt/Edited/Map/Production/ui_map_reward_landmark_master_v001.svg` | `Assets/UI/Map/Production/ui_map_reward_landmark.svg` | Hidden cache slab, covered supply crate, or low treasure marker. Should imply reward without a shiny chest icon. |
| `map_landmark_blacksmith_production` | `blacksmith:forge` | SVG preferred | `SourceArt/Edited/Map/Production/ui_map_blacksmith_landmark_master_v001.svg` | `Assets/UI/Map/Production/ui_map_blacksmith_landmark.svg` | Small forge/anvil marker. Readable as blacksmith support without becoming a full building illustration. |
| `map_landmark_hamlet_production` | `hamlet:waypost` | SVG preferred | `SourceArt/Edited/Map/Production/ui_map_hamlet_landmark_master_v001.svg` | `Assets/UI/Map/Production/ui_map_hamlet_landmark.svg` | Tiny settlement waypost or clustered shelter sign. Should read as human refuge, not merchant/rest/blacksmith. |
| `map_decor_or_canopy_family_production` | `forest_decor` or `canopy` | SVG or transparent PNG | `SourceArt/Edited/Map/Production/ui_map_forest_decor_family_master_v001.svg` | `Assets/UI/Map/Production/ui_map_forest_decor_family.svg` | Small foliage/decor stamp or canopy frame family. It should add forest-world texture without hiding route readability. |

## Probe Coverage Added In Repo

This pass also adds three repo-authored hidden probe assets to test the socket path:

- `ui_map_production_probe_path_brush`
- `ui_map_production_probe_combat_landmark`
- `ui_map_production_probe_blacksmith_landmark`

These probes are not final art and are not the external production request output. They exist only to verify that path, combat, and blacksmith sockets can resolve candidate assets without changing default map render.

## Negative Instructions

- Do not create UI icons with circular badge backs.
- Do not include letters, numbers, labels, or readable runes.
- Do not use bright saturated fantasy loot colors.
- Do not imply path availability, lock state, route truth, hunger, or save state.
- Do not include background plates unless the shape is part of the landmark silhouette.
- Do not deliver source-only assets without a clear license/provenance note.

## Acceptance Notes

- Assets must stay readable when drawn at roughly `18-52px`, depending on socket type.
- Landmark silhouettes must remain distinct from each other at small map scale.
- Path brush must not overpower the procedural road surface.
- Decor/canopy must sit behind readability, not compete with route markers.
- Default render promotion is a later separate decision.
