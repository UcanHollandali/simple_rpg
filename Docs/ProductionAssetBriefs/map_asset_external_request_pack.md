# Map Asset External Request Pack

Generated: 2026-04-25

Source: current live `.gd` socket metadata summary, current asset manifest state, the optional board-ground review hook, and production asset pipeline rules.

## Purpose

This pack is the handoff for external art production. It tells an artist or image-generation workflow what to make before the repo imports any final candidate files.

Use this file as the single AI-facing map asset request. Do not use generated drafts or JSON siblings as production prompts.

Do not treat this pack as runtime approval. Runtime promotion still needs source/master files, runtime exports, manifest provenance, screenshot review, and pixel diff.

## How To Use With AI

Give the AI only this file plus the visual reference image if needed.
Generate `2-3` variants per requested asset.
Return PNG files using the runtime filenames below when possible.
If the AI exports larger images, keep them uncropped for review; the intake pass will crop/export to the exact runtime target.

Required return files:

- `ui_map_board_ground.png`
- `ui_map_path_brush.png`
- `ui_map_boss_landmark.png`
- `ui_map_key_landmark.png`
- `ui_map_rest_landmark.png`
- `ui_map_merchant_landmark.png`
- `ui_map_combat_landmark.png`
- `ui_map_event_landmark.png`
- `ui_map_reward_landmark.png`
- `ui_map_blacksmith_landmark.png`
- `ui_map_hamlet_landmark.png`
- `ui_map_forest_decor_family.png`

## Shared Style

- Dark forest wayfinder fantasy.
- Silhouette-first, readable at small map scale.
- Socket assets use transparent backgrounds.
- Board ground is opaque edge-to-edge board art for the `920x1180` map board rect, not the full `1080x1920` viewport.
- No text, numbers, UI card frame, badge frame, or route truth markings.
- Keep detail sparse enough to read inside the existing socket sizes.
- Palette target: dark ink, muted bark, aged bronze, oxidized teal, pale warm highlight.
- Deliver 2-3 variants per item when possible.
- Runtime targets are PNG-primary for the production layer.

## Requested Assets

| request id | socket/family key | preferred format | master path target | runtime path target | brief |
|---|---|---|---|---|---|
| `map_board_ground_production` | `board_ground` | PNG | `SourceArt/Edited/Map/Production/ui_map_board_ground_master_v001.png` | `Assets/UI/Map/Production/ui_map_board_ground.png` | Edge-to-edge dark moss and grass forest floor for the `920x1180` board rect. Low-contrast, non-directional, no island, no central object, no frame, no paths, no nodes, no landmarks, no UI text. |
| `map_path_brush_production` | `path_surface` | transparent PNG | `SourceArt/Edited/Map/Production/ui_map_path_brush_master_v001.png` | `Assets/UI/Map/Production/ui_map_path_brush.png` | A forest trail brush that can rotate along curved path surfaces. It should read as worn earth, roots, and subtle guide-light flecks, not a hard UI line. |
| `map_landmark_boss_production` | `boss:gate` | transparent PNG | `SourceArt/Edited/Map/Production/ui_map_boss_landmark_master_v001.png` | `Assets/UI/Map/Production/ui_map_boss_landmark.png` | Final gate, thorn-crowned portal, or boss threshold marker. It should read as the late danger endpoint without becoming a giant building or UI badge. |
| `map_landmark_key_production` | `key:shrine` | transparent PNG | `SourceArt/Edited/Map/Production/ui_map_key_landmark_master_v001.png` | `Assets/UI/Map/Production/ui_map_key_landmark.png` | Small shrine, seal, or keyed waystone. It should imply unlocking progress without a literal key icon or readable symbol. |
| `map_landmark_rest_production` | `rest:campfire` | transparent PNG | `SourceArt/Edited/Map/Production/ui_map_rest_landmark_master_v001.png` | `Assets/UI/Map/Production/ui_map_rest_landmark.png` | Low campfire, bedroll, or safe clearing marker. Warm but restrained; should read as rest/safety, not combat or hamlet. |
| `map_landmark_merchant_production` | `merchant:stall` | transparent PNG | `SourceArt/Edited/Map/Production/ui_map_merchant_landmark_master_v001.png` | `Assets/UI/Map/Production/ui_map_merchant_landmark.png` | Tiny pack stall, hanging goods, or trade post marker. Should read as merchant support without text, coin labels, or a full shop building. |
| `map_landmark_combat_production` | `combat:crossed_stakes` | transparent PNG | `SourceArt/Edited/Map/Production/ui_map_combat_landmark_master_v001.png` | `Assets/UI/Map/Production/ui_map_combat_landmark.png` | Crossed stakes or broken warning totem. Clear danger silhouette without skull/cartoon icon language. |
| `map_landmark_event_production` | `event:standing_stone` | transparent PNG | `SourceArt/Edited/Map/Production/ui_map_event_landmark_master_v001.png` | `Assets/UI/Map/Production/ui_map_event_landmark.png` | Standing stone or omen marker. Mysterious but readable, with one simple inner glyph-like shape that is not literal text. |
| `map_landmark_reward_production` | `reward:cache_slab` | transparent PNG | `SourceArt/Edited/Map/Production/ui_map_reward_landmark_master_v001.png` | `Assets/UI/Map/Production/ui_map_reward_landmark.png` | Hidden cache slab, covered supply crate, or low treasure marker. Should imply reward without a shiny chest icon. |
| `map_landmark_blacksmith_production` | `blacksmith:forge` | transparent PNG | `SourceArt/Edited/Map/Production/ui_map_blacksmith_landmark_master_v001.png` | `Assets/UI/Map/Production/ui_map_blacksmith_landmark.png` | Small forge/anvil marker. Readable as blacksmith support without becoming a full building illustration. |
| `map_landmark_hamlet_production` | `hamlet:waypost` | transparent PNG | `SourceArt/Edited/Map/Production/ui_map_hamlet_landmark_master_v001.png` | `Assets/UI/Map/Production/ui_map_hamlet_landmark.png` | Tiny settlement waypost or clustered shelter sign. Should read as human refuge, not merchant/rest/blacksmith. |
| `map_decor_or_canopy_family_production` | `forest_decor` or `canopy` | transparent PNG | `SourceArt/Edited/Map/Production/ui_map_forest_decor_family_master_v001.png` | `Assets/UI/Map/Production/ui_map_forest_decor_family.png` | Small foliage/decor stamp or canopy frame family. It should add forest-world texture without hiding route readability. |

## Prompt Notes

- Global prompt anchor: `dark forest wayfinder, dark misty forest, readable UI contrast, silhouette-focused, stylized not realistic, 2D flat shading, mobile-readable, small-screen-first composition`.
- Global negative anchor: `NOT: muddy green wash, NOT: bright pastel, NOT: photorealistic, NOT: anime, NOT: pixel art, NOT: watercolor, no letters, no numbers, no UI frame`.
- Board ground prompt must also say: `edge-to-edge board texture, 920x1180, no island, no center object, no border, no path, no landmarks, no nodes`.
- Socket asset prompts must also say: `transparent background, isolated object or brush, readable at small map scale, no badge, no circular backing`.
- Prefer one isolated subject per socket asset. Do not ask the AI to compose a full map.

## Negative Instructions

- Do not create UI icons with circular badge backs.
- Do not include letters, numbers, labels, or readable runes.
- Do not use bright saturated fantasy loot colors.
- Do not imply path availability, lock state, route truth, hunger, or save state.
- Do not include background plates unless the shape is part of the landmark silhouette.
- Do not deliver source-only assets without a clear license/provenance note.
- For board ground, do not create an island composition, central landmark, border frame, road network, node layout, or full-map route truth.

## Acceptance Notes

- Board ground must fit the `920x1180` board rect and remain subordinate beneath roads, junctions, clearings, icons, and optional socket art.
- Assets must stay readable when drawn at roughly `18-52px`, depending on socket type.
- Landmark silhouettes must remain distinct from each other at small map scale.
- Path brush must not overpower the procedural road surface.
- Decor/canopy must sit behind readability, not compete with route markers.
- Default render promotion is a later separate decision.
- Phase 1 adds code and brief targets only; runtime asset files and manifest rows are added later in the asset-intake patch.
